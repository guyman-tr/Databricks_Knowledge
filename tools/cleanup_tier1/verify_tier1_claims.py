#!/usr/bin/env python3
"""At-write-time verifier for Tier-1 claims in Synapse / UC_generated wikis.

For every row that ends with `(Tier 1 - <source>)` we verify two invariants
mechanically (no LLM):

  1. RESOLVES   The `<source>` tag must point at an existing wiki file and a
                column whose own tier is Tier 1. If the resolved source's tier
                is 2-5 / N / U, the downstream row is a "promotion lie".

  2. TEXT_MATCH The downstream row's description (with its own tier tag
                stripped) must be a verbatim copy of the resolved source
                column's description (also with tier tag stripped). Any text
                divergence is a "narrative drift" and the row should either
                downgrade its claim (Tier 2 - via <source>) or sync its text.

Outputs a structured CSV plus a non-zero exit code on the first failure so
this script can be wired into pre-commit hooks and CI gates. See Phase E
`harden_generator` and `ci_gate` todos in the cleanup plan.
"""
from __future__ import annotations

import argparse
import csv
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "tools"))

from tier1_audit.parser import find_tier1_claims, parse_wiki_columns


def _norm(s: str) -> str:
    return (s or "").strip().strip("`").lstrip("[").rstrip("]").lower()


from tier1_audit.resolver import resolve

REPORT_FIELDS = [
    "wiki_path",
    "column_name",
    "verdict",         # PASS | FAIL_resolve | FAIL_tier_promotion | FAIL_text_mismatch
    "claim_tier",
    "claim_source_text",
    "resolved_wiki",
    "resolved_column",
    "resolved_tier",
    "claim_text",
    "source_text",
    "notes",
]


def verify_wiki(wiki: Path) -> list[dict]:
    """Walk every Tier-1 claim in `wiki` and emit one report row per claim."""
    rows: list[dict] = []
    try:
        claims = find_tier1_claims(wiki)
    except Exception as exc:
        rows.append({
            "wiki_path": str(wiki.relative_to(REPO)).replace("\\", "/"),
            "column_name": "",
            "verdict": "FAIL_parse",
            "claim_tier": "1",
            "claim_source_text": "",
            "resolved_wiki": "",
            "resolved_column": "",
            "resolved_tier": "",
            "claim_text": "",
            "source_text": "",
            "notes": f"parse error: {exc}",
        })
        return rows

    for claim in claims:
        tag = claim.primary_tier_tag
        if not tag:
            continue
        out = {
            "wiki_path": str(wiki.relative_to(REPO)).replace("\\", "/"),
            "column_name": claim.column_name,
            "claim_tier": tag.tier,
            "claim_source_text": tag.source_text,
            "resolved_wiki": "",
            "resolved_column": "",
            "resolved_tier": "",
            "claim_text": claim.description,
            "source_text": "",
            "notes": "",
        }
        try:
            res = resolve(tag.source_text)
        except Exception as exc:
            out["verdict"] = "FAIL_resolve"
            out["notes"] = f"resolver error: {exc}"
            rows.append(out)
            continue
        if not res.candidate_paths:
            out["verdict"] = "FAIL_resolve"
            out["notes"] = "no matching upstream wiki"
            rows.append(out)
            continue
        src_path = res.candidate_paths[0]
        out["resolved_wiki"] = str(src_path.relative_to(REPO)).replace("\\", "/")
        # Find the matching column in the source
        try:
            src_cols = parse_wiki_columns(src_path)
        except Exception as exc:
            out["verdict"] = "FAIL_resolve"
            out["notes"] = f"source parse error: {exc}"
            rows.append(out)
            continue
        match = next((c for c in src_cols
                      if _norm(c.column_name) == _norm(claim.column_name)),
                     None)
        if not match:
            out["verdict"] = "FAIL_resolve"
            out["notes"] = f"column {claim.column_name!r} not found in source"
            rows.append(out)
            continue
        out["resolved_column"] = match.column_name
        src_tag = match.primary_tier_tag
        out["resolved_tier"] = src_tag.tier if src_tag else ""
        out["source_text"] = match.description
        if not src_tag or src_tag.tier != "1":
            out["verdict"] = "FAIL_tier_promotion"
            out["notes"] = (f"downstream claims Tier 1 but source is "
                            f"Tier {src_tag.tier if src_tag else 'NONE'}")
            rows.append(out)
            continue
        # Text match — exact string equality after stripping tier tags
        if claim.description.strip() != match.description.strip():
            out["verdict"] = "FAIL_text_mismatch"
            out["notes"] = "description text diverges from source"
            rows.append(out)
            continue
        out["verdict"] = "PASS"
        rows.append(out)
    return rows


def verify_paths(paths: list[Path]) -> list[dict]:
    seen: set[str] = set()
    rows: list[dict] = []
    for p in paths:
        if p.is_dir():
            wikis = sorted(p.rglob("*.md"))
        else:
            wikis = [p]
        for wiki in wikis:
            # Skip sidecars
            if any(part in wiki.stem.lower() for part in
                   (".lineage", ".review-needed", ".deploy-report", ".alter")):
                continue
            key = str(wiki).lower()
            if key in seen:
                continue
            seen.add(key)
            rows.extend(verify_wiki(wiki))
    return rows


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("paths", nargs="+",
                    help="One or more wiki files or directories.")
    ap.add_argument("--out", default="",
                    help="Optional CSV report path. Defaults to "
                         "audits/_verify_tier1_<ts>.csv")
    ap.add_argument("--strict", action="store_true",
                    help="Exit non-zero on first FAIL_* row (CI mode).")
    ap.add_argument("--summary", action="store_true",
                    help="Print per-verdict tally.")
    args = ap.parse_args()

    paths = [Path(p).resolve() for p in args.paths]
    rows = verify_paths(paths)

    if args.out:
        out_path = Path(args.out)
    else:
        ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H-%M-%SZ")
        out_path = REPO / "audits" / f"_verify_tier1_{ts}.csv"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=REPORT_FIELDS)
        w.writeheader()
        for r in rows:
            w.writerow(r)

    print(f"Verified {len(rows)} Tier-1 claims across "
          f"{len({r['wiki_path'] for r in rows})} wikis -> {out_path}")
    if args.summary or args.strict:
        tally: dict[str, int] = {}
        for r in rows:
            tally[r["verdict"]] = tally.get(r["verdict"], 0) + 1
        for v in sorted(tally):
            print(f"  {v:25} {tally[v]}")

    if args.strict:
        fails = [r for r in rows if r["verdict"].startswith("FAIL")]
        if fails:
            print(f"STRICT FAIL: {len(fails)} failing claim(s). First 5:",
                  file=sys.stderr)
            for r in fails[:5]:
                print(f"  {r['wiki_path']}::{r['column_name']}  {r['verdict']}  "
                      f"{r['notes']}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
