"""Wiki post-run auditor — orchestrator.

Stage 1 (heuristic scan) -> Stage 2 (LLM merger) -> Stage 3 (concentrated audit
report). Stage 4 (apply patches) lives in a separate `apply.py` once the
dry-run output looks good.

Usage:
    python tools/wiki-auditor/audit.py --schema BI_DB_dbo --sample 15 --seed 42 --dry-run

Output:
    audits/wiki_audit_run_{YYYYMMDD_HHMMSS}.md
    audits/wiki_audit_run_{YYYYMMDD_HHMMSS}.diffs.json
"""

from __future__ import annotations

import argparse
import json
import random
import re
import sys
from dataclasses import asdict, dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Optional

# Sibling-module import (works regardless of cwd).
HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

from heuristics import (  # noqa: E402  (sys.path mutation above is intentional)
    RuleHits,
    evaluate_column,
    load_glossary_terms,
)
from llm_merger import (  # noqa: E402
    CandidateInput,
    MergeResult,
    merge_candidates,
)
from wiki_parser import (  # noqa: E402
    ElementRow,
    LineageRow,
    UpstreamPointer,
    description_without_tier_suffix,
    expand_wildcard_table,
    parse_element_table,
    parse_lineage_file,
    upstream_pointers_for_object,
)


# --- Repo geometry ----------------------------------------------------------


REPO_ROOT_DEFAULT = Path(__file__).resolve().parents[2]


def _wiki_root(repo_root: Path) -> Path:
    return repo_root / "knowledge" / "synapse" / "Wiki"


def _glossary_path(repo_root: Path) -> Path:
    return repo_root / "knowledge" / "glossary.md"


def _audits_dir(repo_root: Path) -> Path:
    return repo_root / "audits"


# --- Object discovery -------------------------------------------------------


_NON_PRIMARY_SUFFIXES = (".review-needed.md", ".lineage.md")


def discover_objects(schema_folder: Path) -> list[Path]:
    """List primary wiki .md files for a schema (Tables and Views)."""
    out: list[Path] = []
    for sub in ("Tables", "Views"):
        folder = schema_folder / sub
        if not folder.is_dir():
            continue
        for f in folder.iterdir():
            if not f.is_file() or f.suffix != ".md":
                continue
            name = f.name
            if name.startswith("_"):
                continue
            if any(name.endswith(suf) for suf in _NON_PRIMARY_SUFFIXES):
                continue
            out.append(f)
    return sorted(out)


# --- Per-object analysis ----------------------------------------------------


@dataclass
class CandidateFinding:
    column: str
    line_no: int
    rules: list[str]
    severity: int
    rule_detail: dict[str, str]
    downstream_desc: str
    downstream_tier: Optional[str]
    upstream_table: Optional[str]
    upstream_column: Optional[str]
    upstream_tier: Optional[str]
    upstream_desc: Optional[str]
    upstream_wiki_path: Optional[str]


@dataclass
class ObjectAudit:
    schema: str
    object_name: str
    wiki_path: str
    lineage_path: Optional[str]
    column_count: int
    candidates: list[CandidateFinding] = field(default_factory=list)
    skipped_reason: Optional[str] = None  # e.g. "no element table", "all synthetic lineage"
    # Filled by stage 2:
    merges: list[MergeResult] = field(default_factory=list)


def _read_optional(path: Optional[Path]) -> Optional[str]:
    if not path or not path.exists():
        return None
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None


def _resolve_upstream_wiki(
    pointer: UpstreamPointer,
    wiki_root: Path,
    current_schema: str,
) -> list[Path]:
    """Find candidate upstream wiki files for a pointer.

    Search order (most specific first):
      1. pointer.schema_hint if provided
      2. DWH_dbo (canonical upstream)
      3. current_schema (intra-schema reference)
      4. all schemas (last resort)
    """
    schemas_tried: list[str] = []
    candidates: list[Path] = []

    def _try(schema_name: str):
        if schema_name in schemas_tried:
            return
        schemas_tried.append(schema_name)
        candidates.extend(
            expand_wildcard_table(pointer.table, wiki_root, schema_hint=schema_name)
        )

    if pointer.schema_hint:
        _try(pointer.schema_hint)
        if candidates:
            return candidates
    _try("DWH_dbo")
    if candidates:
        return candidates
    _try(current_schema)
    if candidates:
        return candidates
    # Last resort: scan everything.
    candidates.extend(expand_wildcard_table(pointer.table, wiki_root))
    return candidates


def _find_upstream_element(
    upstream_path: Path, column_name: str
) -> tuple[Optional[ElementRow], Optional[str]]:
    """Locate the upstream element row for a column. Returns (row, full_text)."""
    text = _read_optional(upstream_path)
    if not text:
        return None, None
    rows = parse_element_table(text)
    target = column_name.lower()
    for r in rows:
        if r.name.lower() == target:
            return r, text
    return None, text


def _tier_score(row: Optional[ElementRow]) -> int:
    """Score an upstream candidate by tier authority (higher = better).

    Tier 1 (verbatim upstream) and Tier 4-Confluence (domain-expert source)
    are the most useful inheritances. Tier 2/3 are SP-derived. Tier 5 is
    domain-expert glossary -- still useful, but rarely on a column row.
    """
    if not row or not row.tier:
        return 0
    t = row.tier
    if t.is_confluence:
        return 5
    if t.tier == "1":
        return 6
    if t.tier == "4":
        return 4
    if t.tier in ("2", "2b"):
        return 3
    if t.tier in ("3", "3b"):
        return 2
    if t.tier == "5":
        return 1
    return 0


def _pick_best_upstream(
    upstream_paths: list[Path], column_name: str
) -> tuple[Optional[Path], Optional[str], Optional[ElementRow]]:
    """Across all wildcard-expanded upstream paths, pick the row with the best
    tier authority. Returns (path, full_text, row).
    """
    best: tuple[int, int, Optional[Path], Optional[str], Optional[ElementRow]] = (
        -1,
        -1,
        None,
        None,
        None,
    )
    for up_path in upstream_paths:
        row, text = _find_upstream_element(up_path, column_name)
        if row is None:
            continue
        score = _tier_score(row)
        # Tie-breaker: longer description wins (more semantic content).
        desc_len = len(row.description or "")
        if (score, desc_len) > (best[0], best[1]):
            best = (score, desc_len, up_path, text, row)
    return best[2], best[3], best[4]


def audit_object(
    wiki_path: Path,
    schema: str,
    wiki_root: Path,
    glossary_terms: set[str],
) -> ObjectAudit:
    """Run Stage 1 (heuristic scan) for a single object."""
    object_name = wiki_path.stem
    audit = ObjectAudit(
        schema=schema,
        object_name=object_name,
        wiki_path=str(wiki_path),
        lineage_path=None,
        column_count=0,
    )

    text = _read_optional(wiki_path)
    if not text:
        audit.skipped_reason = "wiki file unreadable"
        return audit

    elements = parse_element_table(text)
    audit.column_count = len(elements)
    if not elements:
        audit.skipped_reason = "no element table found"
        return audit

    # Path.with_suffix replaces the last extension only -- spell .lineage.md out.
    lineage_path = wiki_path.parent / f"{object_name}.lineage.md"
    lineage_text = _read_optional(lineage_path)
    lineage_rows: Optional[list[LineageRow]] = None
    if lineage_text:
        lineage_rows = parse_lineage_file(lineage_text)
        audit.lineage_path = str(lineage_path)

    pointers_by_col = upstream_pointers_for_object(wiki_path, elements, lineage_rows)

    # Cache wildcard expansion results per (schema_hint, table) to avoid re-reads.
    wildcard_cache: dict[tuple[str, str], list[Path]] = {}

    for el in elements:
        ptrs = pointers_by_col.get(el.name, [])
        chosen_path: Optional[Path] = None
        chosen_text: Optional[str] = None
        chosen_row: Optional[ElementRow] = None
        chosen_pointer: Optional[UpstreamPointer] = None
        # Try each pointer in turn; for each, score across all wildcard matches
        # and pick the most authoritative upstream row. First pointer that
        # resolves to a real row wins.
        for p in ptrs:
            cache_key = (p.schema_hint or "", p.table)
            if cache_key not in wildcard_cache:
                wildcard_cache[cache_key] = _resolve_upstream_wiki(p, wiki_root, schema)
            up_paths = wildcard_cache[cache_key]
            if not up_paths:
                continue
            picked_path, picked_text, picked_row = _pick_best_upstream(up_paths, p.column)
            if picked_row is None:
                continue
            chosen_path = picked_path
            chosen_text = picked_text
            chosen_row = picked_row
            chosen_pointer = p
            break

        hits = evaluate_column(
            downstream_description=el.description,
            downstream_tier=el.tier,
            downstream_wiki_text=text,
            upstream_description=chosen_row.description if chosen_row else None,
            upstream_tier=chosen_row.tier if chosen_row else None,
            upstream_wiki_text=chosen_text,
            glossary_terms=glossary_terms,
        )

        if not hits.is_candidate:
            continue

        audit.candidates.append(
            CandidateFinding(
                column=el.name,
                line_no=el.line_no,
                rules=hits.triggered,
                severity=hits.severity,
                rule_detail=hits.detail,
                downstream_desc=el.description,
                downstream_tier=el.tier.tier if el.tier else None,
                upstream_table=chosen_pointer.table if chosen_pointer else None,
                upstream_column=chosen_pointer.column if chosen_pointer else None,
                upstream_tier=(
                    chosen_row.tier.tier if chosen_row and chosen_row.tier else None
                ),
                upstream_desc=chosen_row.description if chosen_row else None,
                upstream_wiki_path=str(chosen_path) if chosen_path else None,
            )
        )

    return audit


# --- Stage 2 wrapper --------------------------------------------------------


def run_stage2(audit: ObjectAudit, *, use_llm: bool, llm_timeout_s: int) -> None:
    """Mutate `audit.merges` in place."""
    if not audit.candidates:
        return
    inputs = [
        CandidateInput(
            column=c.column,
            downstream_desc=c.downstream_desc,
            downstream_tier=c.downstream_tier or "",
            upstream_table=c.upstream_table or "",
            upstream_column=c.upstream_column or "",
            upstream_desc=c.upstream_desc or "",
            upstream_tier=c.upstream_tier or "",
            rules_triggered=c.rules,
            rule_detail=c.rule_detail,
        )
        for c in audit.candidates
        if c.upstream_desc  # only ask the LLM about candidates with a real upstream
    ]
    if not inputs:
        return
    audit.merges = merge_candidates(
        f"{audit.schema}.{audit.object_name}",
        inputs,
        timeout_s=llm_timeout_s,
        use_llm=use_llm,
    )


# --- Stage 3: report writer -------------------------------------------------


def _short(text: str, limit: int = 240) -> str:
    text = (text or "").strip().replace("\n", " ")
    if len(text) <= limit:
        return text
    return text[: limit - 3] + "..."


def write_report(
    audits: list[ObjectAudit],
    *,
    repo_root: Path,
    schema: str,
    sample: int,
    seed: Optional[int],
    dry_run: bool,
    use_llm: bool,
) -> tuple[Path, Path]:
    """Write the concentrated markdown report and the machine-readable diffs."""
    audits_dir = _audits_dir(repo_root)
    audits_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    md_path = audits_dir / f"wiki_audit_run_{ts}.md"
    json_path = audits_dir / f"wiki_audit_run_{ts}.diffs.json"

    # --- Tally ---
    total_objects = len(audits)
    objects_with_candidates = sum(1 for a in audits if a.candidates)
    total_candidates = sum(len(a.candidates) for a in audits)
    total_promotes = sum(
        sum(1 for m in a.merges if m.recommendation == "PROMOTE") for a in audits
    )
    total_skips = sum(
        sum(1 for m in a.merges if m.recommendation == "SKIP") for a in audits
    )
    total_conflicts = sum(
        sum(1 for m in a.merges if m.recommendation == "CONFLICT") for a in audits
    )
    total_stub = sum(
        sum(1 for m in a.merges if m.source == "stub") for a in audits
    )

    # --- Markdown ---
    lines: list[str] = []
    lines.append(f"# Wiki Audit Run — {ts}")
    lines.append("")
    lines.append("## Run metadata")
    lines.append("")
    lines.append(f"- **Schema**: `{schema}`")
    lines.append(f"- **Sample size**: {sample}")
    lines.append(f"- **Seed**: {seed if seed is not None else '(random)'}")
    lines.append(f"- **Mode**: {'dry-run' if dry_run else 'apply'}")
    lines.append(f"- **LLM merger**: {'enabled' if use_llm else 'stub-only'}")
    lines.append(f"- **Repo root**: `{repo_root}`")
    lines.append("")
    lines.append("## Summary")
    lines.append("")
    lines.append(f"- Objects scanned: **{total_objects}**")
    lines.append(f"- Objects with at least one candidate: **{objects_with_candidates}**")
    lines.append(f"- Total candidates: **{total_candidates}**")
    if total_candidates:
        lines.append(
            f"- LLM verdicts: PROMOTE **{total_promotes}** / SKIP **{total_skips}** / CONFLICT **{total_conflicts}**"
        )
        if total_stub:
            lines.append(f"- Stub-merge fallbacks (LLM unavailable): **{total_stub}**")
    lines.append("")

    # --- Per-object summary table ---
    lines.append("## Per-object summary")
    lines.append("")
    lines.append("| Object | Columns | Candidates | PROMOTE | SKIP | CONFLICT | Notes |")
    lines.append("|---|---:|---:|---:|---:|---:|---|")
    for a in audits:
        promotes = sum(1 for m in a.merges if m.recommendation == "PROMOTE")
        skips = sum(1 for m in a.merges if m.recommendation == "SKIP")
        confs = sum(1 for m in a.merges if m.recommendation == "CONFLICT")
        notes = a.skipped_reason or ""
        lines.append(
            f"| `{a.object_name}` | {a.column_count} | {len(a.candidates)} | "
            f"{promotes} | {skips} | {confs} | {notes} |"
        )
    lines.append("")

    # --- Top findings ---
    high_severity = sorted(
        (
            (a, c)
            for a in audits
            for c in a.candidates
            if c.severity >= 3
        ),
        key=lambda pair: (-pair[1].severity, pair[0].object_name, pair[1].column),
    )
    if high_severity:
        lines.append("## Top findings (severity >= 3)")
        lines.append("")
        lines.append("| Object | Column | Rules | Upstream |")
        lines.append("|---|---|---|---|")
        for a, c in high_severity[:50]:
            up = (
                f"`{c.upstream_table}.{c.upstream_column}`"
                if c.upstream_table and c.upstream_column
                else "—"
            )
            lines.append(
                f"| `{a.object_name}` | `{c.column}` | {' + '.join(c.rules)} | {up} |"
            )
        lines.append("")

    # --- Per-candidate diffs ---
    lines.append("## Per-candidate diffs")
    lines.append("")
    if total_candidates == 0:
        lines.append("_No candidates surfaced for this run._")
        lines.append("")
    else:
        merges_by_obj_col: dict[tuple[str, str], MergeResult] = {}
        for a in audits:
            for m in a.merges:
                merges_by_obj_col[(a.object_name, m.column)] = m

        for a in audits:
            if not a.candidates:
                continue
            lines.append(f"### {a.schema}.{a.object_name}")
            lines.append("")
            lines.append(
                f"_Wiki: `{Path(a.wiki_path).relative_to(repo_root)}`"
                + (
                    f"  •  Lineage: `{Path(a.lineage_path).relative_to(repo_root)}`"
                    if a.lineage_path
                    else "  •  Lineage: (inline tier-suffix only)"
                )
                + "_"
            )
            lines.append("")
            for c in a.candidates:
                merge = merges_by_obj_col.get((a.object_name, c.column))
                lines.append(f"#### `{c.column}` (line {c.line_no}, severity {c.severity})")
                lines.append("")
                lines.append(f"- **Rules**: {' + '.join(c.rules)}")
                for rule, msg in c.rule_detail.items():
                    lines.append(f"  - `{rule}`: {msg}")
                if c.upstream_table and c.upstream_column:
                    up_loc = f"`{c.upstream_table}.{c.upstream_column}`"
                    if c.upstream_wiki_path:
                        rel = Path(c.upstream_wiki_path).relative_to(repo_root)
                        up_loc += f" (`{rel}`)"
                    lines.append(f"- **Upstream**: {up_loc}")
                if c.upstream_tier:
                    lines.append(f"- **Tiers**: downstream `{c.downstream_tier or '?'}` -> upstream `{c.upstream_tier}`")
                lines.append("")
                lines.append("**Current downstream description**:")
                lines.append("")
                lines.append(f"> {_short(c.downstream_desc, 600)}")
                lines.append("")
                if c.upstream_desc:
                    lines.append("**Upstream description**:")
                    lines.append("")
                    lines.append(f"> {_short(c.upstream_desc, 600)}")
                    lines.append("")
                if merge:
                    lines.append(
                        f"**Proposed merge** ({merge.recommendation}, source: {merge.source}):"
                    )
                    lines.append("")
                    if merge.recommendation == "PROMOTE" and merge.merged_desc:
                        # The LLM frequently embeds the tier suffix at the end
                        # of merged_desc AND repeats it in `attribution`. Strip
                        # any end-of-string (Tier ...) from the body so we
                        # never double-print attribution.
                        body = description_without_tier_suffix(merge.merged_desc).rstrip(" .;")
                        attrib = merge.attribution.strip()
                        if attrib and not attrib.startswith("("):
                            attrib = f"({attrib})"
                        rendered = f"{body}. {attrib}".strip() if attrib else f"{body}."
                        lines.append(f"> {rendered}")
                    else:
                        lines.append(f"> _{merge.recommendation}_ — {merge.notes or '(no merge proposed)'}")
                    lines.append("")
                lines.append("---")
                lines.append("")

    md_path.write_text("\n".join(lines), encoding="utf-8")

    # --- diffs.json ---
    diffs_payload: list[dict] = []
    for a in audits:
        merges_by_col = {m.column: m for m in a.merges}
        for c in a.candidates:
            m = merges_by_col.get(c.column)
            diffs_payload.append(
                {
                    "schema": a.schema,
                    "object": a.object_name,
                    "wiki_path": a.wiki_path,
                    "column": c.column,
                    "line_no": c.line_no,
                    "rules": c.rules,
                    "severity": c.severity,
                    "rule_detail": c.rule_detail,
                    "downstream_desc": c.downstream_desc,
                    "downstream_tier": c.downstream_tier,
                    "upstream_table": c.upstream_table,
                    "upstream_column": c.upstream_column,
                    "upstream_tier": c.upstream_tier,
                    "upstream_desc": c.upstream_desc,
                    "upstream_wiki_path": c.upstream_wiki_path,
                    "merge": asdict(m) if m else None,
                }
            )
    json_path.write_text(json.dumps(diffs_payload, indent=2, ensure_ascii=False), encoding="utf-8")

    return md_path, json_path


# --- CLI -------------------------------------------------------------------


def _build_argparser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Wiki post-run auditor (heuristic + LLM merger).")
    p.add_argument("--schema", required=True, help="Schema folder under knowledge/synapse/Wiki/, e.g. BI_DB_dbo.")
    p.add_argument("--sample", type=int, default=15, help="Random sample size (default 15).")
    p.add_argument("--seed", type=int, default=None, help="Random seed for reproducibility.")
    p.add_argument("--dry-run", action="store_true", default=True, help="Dry-run mode (default).")
    p.add_argument("--no-llm", action="store_true", help="Skip LLM stage; use stub merger only.")
    p.add_argument("--llm-timeout", type=int, default=240, help="Per-object LLM call timeout in seconds.")
    p.add_argument("--objects", help="Comma-separated explicit object names (skips random sampling).")
    p.add_argument("--all", action="store_true", help="Audit every object in the schema (overrides --sample).")
    p.add_argument("--repo-root", default=str(REPO_ROOT_DEFAULT), help="Repo root override.")
    return p


def main(argv: Optional[list[str]] = None) -> int:
    args = _build_argparser().parse_args(argv)
    repo_root = Path(args.repo_root).resolve()
    wiki_root = _wiki_root(repo_root)
    schema_folder = wiki_root / args.schema
    if not schema_folder.is_dir():
        print(f"[error] schema folder not found: {schema_folder}", file=sys.stderr)
        return 2

    glossary_terms = load_glossary_terms(_glossary_path(repo_root))

    objects = discover_objects(schema_folder)
    if args.objects:
        explicit = {n.strip() for n in args.objects.split(",") if n.strip()}
        objects = [p for p in objects if p.stem in explicit]
        if not objects:
            print(f"[error] no matching objects in {args.schema}: {args.objects}", file=sys.stderr)
            return 2
    elif not args.all:
        rng = random.Random(args.seed)
        if len(objects) > args.sample:
            objects = sorted(rng.sample(objects, args.sample), key=lambda p: p.stem)

    print(f"[info] auditing {len(objects)} object(s) in {args.schema}")

    audits: list[ObjectAudit] = []
    for i, wiki_path in enumerate(objects, start=1):
        print(f"[scan] {i}/{len(objects)} {wiki_path.stem}", flush=True)
        audit = audit_object(wiki_path, args.schema, wiki_root, glossary_terms)
        audits.append(audit)

    cand_total = sum(len(a.candidates) for a in audits)
    print(f"[info] heuristic stage done: {cand_total} candidate(s) across {sum(1 for a in audits if a.candidates)} object(s)")

    use_llm = not args.no_llm
    if cand_total:
        for i, audit in enumerate(audits, start=1):
            if not audit.candidates:
                continue
            print(f"[merge] {audit.object_name} ({len(audit.candidates)} candidate(s))", flush=True)
            run_stage2(audit, use_llm=use_llm, llm_timeout_s=args.llm_timeout)

    md_path, json_path = write_report(
        audits,
        repo_root=repo_root,
        schema=args.schema,
        sample=args.sample,
        seed=args.seed,
        dry_run=args.dry_run,
        use_llm=use_llm,
    )
    print(f"[done] report: {md_path}")
    print(f"[done] diffs: {json_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
