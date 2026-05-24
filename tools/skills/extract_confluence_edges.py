"""
Extract co-occurrence edges from a pre-fetched Confluence page corpus.

Architecture
------------
This extractor is parallel to `tools/skills/extract_tableau_edges.py` but
Confluence content cannot be reached by a standalone Python process in
this repo (no python-side Atlassian client wired up). The crawl is driven
by the agent via `plugin-atlassian-atlassian` MCP calls during Phase A.5b
of a domain build and writes one JSON dump per page under

    knowledge/confluence/_corpus/<domain>/<page_id>.json

Per-page JSON schema (written by the crawler):
    {
      "page_id":        "905478189",                 # required
      "title":          "AML-OPS Monitoring Procedure",
      "space_key":      "OTS",
      "space_name":     "Operations Wiki",
      "url":            "https://etoro-jira.../wiki/spaces/OTS/pages/...",
      "version":        18,
      "created_date":   "2020-02-28T08:53:57.861Z",
      "last_updated":   "2025-10-14T11:22:00.000Z",  # if known
      "depth_in_tree":  3,
      "ancestor_titles":["Operations Wiki", "Compliance", "AML"],
      "query_term":     "AML",
      "body_markdown":  "...",                        # plain markdown rendering
      "fetched_at":     "2026-05-24T12:20:00Z"
    }

This script:
  1. Walks every JSON dump under knowledge/confluence/_corpus/<domain>/.
  2. Parses body_markdown for:
       - SQL code blocks (```sql...```) — extracts FROM/JOIN refs (same regex
         as extract_tableau_edges.py).
       - Inline backtick references that look like `Schema.Object`.
  3. For each page with >= 2 distinct table refs, emits all-pairs
     co-occurrence edges in the same CSV schema as _edges_tableau.csv plus
     a `stability_score` column derived from the page's metadata.
  4. Pages with stability_score < 0.6 are EXCLUDED from the edges output by
     default (use --include-low-stability to include them with weight 0.5
     instead of 1.0 in the source column).

Stability scoring (favors canonical / Handbook / Glossary pages over
recent-edit churn — per spec 011 FR-007 / Authority Hierarchy Tier 3 vs 5):

    title_pattern    +1.0 if title contains Handbook/Framework/Glossary/
                          Policy/Specification/Reference/Architecture
                     +0.5 if title contains Procedure/Manual/Standard
                     +0.0 otherwise

    title_red_flag   -1.0 if title contains (Obsolete)/(Old logic)/(WIP)/
                          (Deprecated)/(Draft)/(Sandbox)/(DEPRECATED)/Legacy

    depth_score      0.3 * (1.0 - min(depth/10, 0.8))      # shallower wins

    age_score        0.5 * min(months_since_edit/12, 1.0)  # OLDER wins -
                                                            # the explicit
                                                            # "stability over
                                                            # recency" rule

    stability_score = title_pattern + title_red_flag + depth_score + age_score

Usage:
  python tools/skills/extract_confluence_edges.py --domain compliance

Output:
  knowledge/skills/_<domain>_confluence_edges.csv  # for graph overlay / future merge
  knowledge/skills/_<domain>_confluence_corpus.md  # human-readable corpus audit trail

Reads:
  knowledge/confluence/_corpus/<domain>/*.json
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from datetime import datetime, timezone
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SKILLS = ROOT / "knowledge" / "skills"
CORPUS_ROOT = ROOT / "knowledge" / "confluence" / "_corpus"


SQL_TABLE_REF = re.compile(
    r"\b(?:FROM|JOIN)\s+"
    r"(?!\(|LATERAL\b|UNNEST\b)"
    r"(\[?[A-Za-z_][\w]*\]?(?:\s*\.\s*\[?[A-Za-z_][\w]*\]?){0,2})",
    re.IGNORECASE,
)

INLINE_SCHEMA_OBJ = re.compile(
    r"`([A-Za-z_][\w]*\.[A-Za-z_][\w]*(?:\.[A-Za-z_][\w]*)?)`"
)

TITLE_CANONICAL_RE = re.compile(
    r"(?i)(handbook|framework|glossary|policy|specification|reference|architecture|standard"
    r"|\bhld\b|\bprd\b|\brfc\b)"
)
TITLE_DOCUMENT_RE = re.compile(r"(?i)(procedure|manual|process)")
TITLE_RED_FLAG_RE = re.compile(
    r"(?i)\(?\s*(obsolete|old\s*logic|deprecated|wip|draft|sandbox|legacy|scratch|temp|tmp|not\s*in\s*use)\s*\)?"
)
# Content-derived signal: any page with this many `Schema.Object` refs is
# treated as having de-facto canonical authority regardless of title pattern
# (production-content trumps title heuristics).
CONTENT_BONUS_REF_THRESHOLD = 5
CONTENT_BONUS_SCORE = 1.0


UC_CATALOGS = {"main", "samples", "system", "spark_catalog", "hive_metastore"}


def normalize_ref(raw: str) -> str | None:
    """Return a schema.table form, dropping any column suffix.

    3-part refs are ambiguous (could be db.schema.table OR schema.table.column).
    Heuristic: if first part is a known UC catalog, treat as catalog.schema.table
    and return schema.table. Otherwise treat as schema.table.column and return
    schema.table (i.e. first two parts).

    Examples:
        BackOffice.Customer                       -> BackOffice.Customer
        BackOffice.Customer.RiskClassificationID  -> BackOffice.Customer
        main.general.bronze_etoro_dict_x          -> general.bronze_etoro_dict_x
        V_CustomerAnswersNrml                     -> None  (no schema)
    """
    parts = [p.strip().strip("[]").strip("`") for p in raw.split(".") if p.strip()]
    if not parts:
        return None
    if len(parts) == 1:
        return None
    if len(parts) == 2:
        return f"{parts[0]}.{parts[1]}"
    if parts[0].lower() in UC_CATALOGS:
        return f"{parts[1]}.{parts[2]}"
    return f"{parts[0]}.{parts[1]}"


def parse_table_refs(markdown_body: str) -> set[str]:
    refs: set[str] = set()
    for m in re.finditer(r"```sql\s*\n(.*?)```", markdown_body, re.DOTALL | re.IGNORECASE):
        sql = m.group(1)
        sql = re.sub(r"/\*.*?\*/", " ", sql, flags=re.DOTALL)
        sql = re.sub(r"--[^\n]*", " ", sql)
        for tm in SQL_TABLE_REF.finditer(sql):
            n = normalize_ref(tm.group(1))
            if n:
                refs.add(n)
    for m in INLINE_SCHEMA_OBJ.finditer(markdown_body):
        n = normalize_ref(m.group(1))
        if n:
            refs.add(n)
    return refs


def compute_stability(page: dict, n_refs: int = 0) -> tuple[float, dict]:
    title = page.get("title", "") or ""
    breakdown: dict[str, float] = {}

    title_pattern_score = 0.0
    if TITLE_CANONICAL_RE.search(title):
        title_pattern_score = 1.0
    elif TITLE_DOCUMENT_RE.search(title):
        title_pattern_score = 0.5
    breakdown["title_pattern"] = title_pattern_score

    red_flag = -1.0 if TITLE_RED_FLAG_RE.search(title) else 0.0
    breakdown["title_red_flag"] = red_flag

    depth = page.get("depth_in_tree", 5)
    try:
        depth = int(depth)
    except (TypeError, ValueError):
        depth = 5
    depth_score = 0.3 * (1.0 - min(depth / 10.0, 0.8))
    breakdown["depth_score"] = round(depth_score, 3)

    last_updated = page.get("last_updated") or page.get("created_date") or ""
    age_score = 0.0
    if last_updated:
        try:
            ts = last_updated.rstrip("Z")
            if "." in ts:
                ts = ts.split(".")[0]
            dt = datetime.fromisoformat(ts).replace(tzinfo=timezone.utc)
            now = datetime.now(timezone.utc)
            months = (now - dt).days / 30.0
            age_score = 0.5 * min(months / 12.0, 1.0)
        except (ValueError, TypeError):
            age_score = 0.0
    breakdown["age_score"] = round(age_score, 3)

    content_bonus = CONTENT_BONUS_SCORE if n_refs >= CONTENT_BONUS_REF_THRESHOLD else 0.0
    breakdown["content_bonus"] = content_bonus

    total = title_pattern_score + red_flag + depth_score + age_score + content_bonus
    return round(total, 3), breakdown


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--domain", required=True)
    ap.add_argument(
        "--include-low-stability", action="store_true",
        help="include pages with stability_score < 0.6 (with weight 0.5)"
    )
    ap.add_argument("--threshold", type=float, default=0.6,
                    help="minimum stability_score to include (default 0.6)")
    args = ap.parse_args()

    corpus_dir = CORPUS_ROOT / args.domain
    if not corpus_dir.exists():
        print(f"No corpus directory at {corpus_dir} - run the crawl first.", file=sys.stderr)
        return 2

    pages = []
    for jf in sorted(corpus_dir.glob("*.json")):
        if jf.name.startswith("_"):
            continue  # underscore-prefixed files are scratch (e.g. _candidates.json)
        try:
            obj = json.loads(jf.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            print(f"Skipping {jf.name}: {e}", file=sys.stderr)
            continue
        if isinstance(obj, dict) and "page_id" in obj:
            pages.append(obj)

    if not pages:
        print(f"No pages found under {corpus_dir}", file=sys.stderr)
        return 2

    print(f"Loaded {len(pages)} pages from {corpus_dir.relative_to(ROOT)}", flush=True)

    edges = []
    page_summaries = []
    refs_by_page: list[tuple[dict, set[str], float, dict]] = []

    for page in pages:
        title = page.get("title", "(no title)")
        body = page.get("body_markdown", "") or ""
        refs = parse_table_refs(body)
        stab, breakdown = compute_stability(page, n_refs=len(refs))
        refs_by_page.append((page, refs, stab, breakdown))
        page_summaries.append({
            "page_id": page.get("page_id", ""),
            "title": title,
            "space": page.get("space_key", ""),
            "stability": stab,
            "n_refs": len(refs),
            "query_term": page.get("query_term", ""),
            "url": page.get("url", ""),
            "last_updated": page.get("last_updated") or page.get("created_date", ""),
            "depth": page.get("depth_in_tree", "?"),
            "breakdown": breakdown,
            "included": stab >= args.threshold or args.include_low_stability,
        })

    excluded = sum(1 for s in page_summaries if not s["included"])
    included = len(page_summaries) - excluded

    for page, refs, stab, _ in refs_by_page:
        if len(refs) < 2:
            continue
        if stab < args.threshold and not args.include_low_stability:
            continue
        is_canonical = stab >= args.threshold
        edge_kind = "confluence_canonical" if is_canonical else "confluence_non_canonical"
        purpose = (page.get("title", "") or "")[:80]
        source_str = f"confluence:{page.get('space_key', '?')}/{page.get('page_id', '?')}"
        for a, b in combinations(sorted(refs), 2):
            edges.append({
                "left": a,
                "right": b,
                "edge_kind": edge_kind,
                "join_keys": "",
                "purpose": purpose,
                "source": source_str,
                "stability_score": stab,
            })

    out_csv = SKILLS / f"_{args.domain}_confluence_edges.csv"
    fields = ["left", "right", "edge_kind", "join_keys", "purpose", "source", "stability_score"]
    with out_csv.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for e in edges:
            w.writerow(e)

    # human-readable corpus audit trail
    out_md = SKILLS / f"_{args.domain}_confluence_corpus.md"
    lines = []
    lines.append(f"# {args.domain} — Confluence corpus audit")
    lines.append("")
    lines.append(f"_Generated by `tools/skills/extract_confluence_edges.py --domain {args.domain}`._")
    lines.append("")
    lines.append("## Summary")
    lines.append(f"- Pages crawled: **{len(pages)}**")
    lines.append(f"- Pages above stability threshold ({args.threshold}): **{included}** (Tier 3 - canonical)")
    lines.append(f"- Pages below threshold: **{excluded}** (Tier 5 - non-canonical)")
    lines.append(f"- Edges emitted: **{len(edges)}**")
    lines.append("")
    lines.append("## Selection scorer")
    lines.append("")
    lines.append("```")
    lines.append("stability_score = title_pattern + title_red_flag")
    lines.append("                + 0.3*(1 - min(depth/10, 0.8))")
    lines.append("                + 0.5*min(months_since_edit/12, 1.0)")
    lines.append(f"                + content_bonus  ({CONTENT_BONUS_SCORE} if n_refs >= {CONTENT_BONUS_REF_THRESHOLD}, else 0)")
    lines.append("")
    lines.append("title_pattern  : +1.0 (Handbook/Framework/Glossary/Policy/Specification/Reference/")
    lines.append("                       Architecture/Standard/HLD/PRD/RFC)")
    lines.append("                 +0.5 (Procedure/Manual/Process)")
    lines.append("                  0.0 otherwise")
    lines.append("title_red_flag : -1.0 (Obsolete/Old Logic/Deprecated/WIP/Draft/Sandbox/Legacy/scratch/not in use)")
    lines.append("content_bonus  : +1.0 if page body has >= 5 inline `Schema.Object` refs (production-content signal)")
    lines.append("")
    lines.append("Stability favors AGE (older = more committed-to) and SHALLOW DEPTH (root-of-space).")
    lines.append("```")
    lines.append("")

    lines.append("## Pages by stability score")
    lines.append("")
    lines.append("| Inc | Score | Title | Space | Depth | Last updated | Refs | Query | URL |")
    lines.append("|---|---|---|---|---|---|---|---|---|")
    for s in sorted(page_summaries, key=lambda x: -x["stability"]):
        inc = "yes" if s["included"] else " no"
        url_anchor = s["url"]
        title = s["title"].replace("|", "\\|")
        lines.append(f"| {inc} | {s['stability']:.2f} | {title} | {s['space']} | {s['depth']} | {s['last_updated'][:10] if s['last_updated'] else ''} | {s['n_refs']} | {s['query_term']} | {url_anchor[:60]} |")
    lines.append("")

    lines.append("## Stability breakdown (top 20 by score)")
    lines.append("")
    for s in sorted(page_summaries, key=lambda x: -x["stability"])[:20]:
        b = s["breakdown"]
        lines.append(
            f"- **{s['stability']:.2f}** `{s['title'][:80]}` "
            f"({s['n_refs']} refs) — pattern {b['title_pattern']:+.1f}, "
            f"red_flag {b['title_red_flag']:+.1f}, depth {b['depth_score']:+.2f}, "
            f"age {b['age_score']:+.2f}, content {b.get('content_bonus', 0.0):+.1f}"
        )
    lines.append("")

    out_md.write_text("\n".join(lines), encoding="utf-8")

    print(f"Wrote {out_csv.relative_to(ROOT)} ({len(edges)} edges)")
    print(f"Wrote {out_md.relative_to(ROOT)}")
    print(f"  Pages: {len(pages)} crawled, {included} above threshold, {excluded} below")
    return 0


if __name__ == "__main__":
    sys.exit(main())
