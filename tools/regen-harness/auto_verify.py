#!/usr/bin/env python3
"""
auto_verify.py - mechanical pre-judge verification for trivially-simple wikis.

Premise: the LLM judge costs ~$0.05-0.10 per object on Sonnet routing. About
30% of the 593-newbuild backlog is trivially-simple objects (small column
count, single mirror upstream, every column is a Tier 1 passthrough). For
those, the judge always returns PASS because the writer's failure surface is
tiny -- there are simply not many ways to mess up a 4-column passthrough.

This script runs the deterministic checks the LLM judge would always pass
anyway, plus a triviality gate, and writes a synthetic judge_verdict.json
so the harness loop can skip the real judge call.

Triviality gate (ALL must hold):
  - DDL column count <= MAX_TRIVIAL_COLS (default 5)
  - _upstream_resolution.json shows >= 1 resolved upstream wiki
  - Every Element row is tagged Tier 1 (full passthrough)

Mechanical checks (ALL must hold to issue auto-PASS):
  - Element table row count == DDL column count
  - Every Element row's tier suffix uses single-tier format
    `(Tier N - source)` -- no hybrid `(Tier 1 - X, Tier 2 in source: Y)`
  - Every Tier 1 source identifier appears in _upstream_resolution.json
  - 8 required H2 sections are present
  - If bundle is `_no_upstream_found.txt`, NO Tier 1 tags allowed
  - Footer Tier1+Tier2+Tier3+Tier4 sum equals DDL column count (when present)

Exit codes:
  0 = auto-PASS issued (skip the LLM judge); judge_verdict.json written
  1 = mechanical check failed (run the LLM judge as normal)
  2 = triviality gate failed (run the LLM judge as normal)
  3 = wiki/lineage file missing (run the LLM judge as normal)

The "run the LLM judge as normal" exits are NOT errors -- they just mean
the auto-verify can't make a confident call and the harness should defer
to the LLM. This script never INVALIDATES a wiki; the judge is still the
sole authority for FAIL verdicts.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Optional, Set, Tuple

# Reuse DDL column extractor from preload_upstream
sys.path.insert(0, str(Path(__file__).resolve().parent))
from preload_upstream import _extract_ddl_columns  # noqa: E402

MAX_TRIVIAL_COLS = 5
SYNTH_PASS_SCORE = 8.5

REQUIRED_H2_SECTIONS = [
    "1. Business Meaning",
    "2. Business Logic",
    "3. Operational Profile",
    "4. Elements",
    "5. Lineage Summary",
    "6. Relationships",
    "7. Sample Queries",
    "8. Atlassian Knowledge Inventory",
]

# `(Tier N - source)` or `(Tier N -- source)` or em-dash variant.
TIER_SUFFIX_RE = re.compile(
    r"\(\s*Tier\s+([1-4])\s+(?:-{1,2}|\u2013|\u2014)\s+([^)]+?)\s*\)"
)

# Hybrid markers we explicitly reject.
HYBRID_TIER_PATTERNS = [
    re.compile(r"\(\s*Tier\s+\d+\s*/\s*\d+", re.IGNORECASE),
    re.compile(r"Tier\s+\d+\b.{0,40}\bTier\s+\d+", re.IGNORECASE),
    re.compile(r"Tier\s+\d+\s+in\s+source", re.IGNORECASE),
]

FOOTER_TIER_RE = re.compile(
    r"Tier\s*1\s*[:\s]+(\d+).{0,40}Tier\s*2\s*[:\s]+(\d+).{0,40}Tier\s*3\s*[:\s]+(\d+).{0,40}Tier\s*4\s*[:\s]+(\d+)",
    re.IGNORECASE | re.DOTALL,
)


def _read_text(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")


def _check(name: str, ok: bool, detail: str = "") -> Tuple[str, bool, str]:
    return (name, ok, detail)


def parse_element_rows(wiki_text: str) -> List[dict]:
    """Return one dict per row in the Elements table (Section 4).

    Best-effort markdown table parser. Looks for the line `## 4. Elements`,
    skips through blank lines + table header + separator (`---`), then
    captures every pipe-row until a blank line or new H2.
    """
    rows: List[dict] = []
    in_section = False
    in_table = False
    after_separator = False
    headers: List[str] = []
    for raw in wiki_text.splitlines():
        if re.match(r"^##\s+4\.\s+Elements", raw):
            in_section = True
            continue
        if in_section and re.match(r"^##\s+\d+\.", raw):
            break  # next H2 closes Section 4
        if not in_section:
            continue
        line = raw.strip()
        if line.startswith("|"):
            if not in_table:
                # First pipe row is the header
                headers = [c.strip() for c in line.strip("|").split("|")]
                in_table = True
                continue
            if not after_separator:
                # Second pipe row is the |---|---| separator
                after_separator = True
                continue
            cells = [c.strip() for c in line.strip("|").split("|")]
            if len(cells) < 2:
                continue
            row = {}
            for i, h in enumerate(headers):
                if i < len(cells):
                    row[h] = cells[i]
            rows.append(row)
        else:
            if in_table and not line:
                # blank line ends the table; stop scanning Section 4
                break
    return rows


def detect_tier_for_row(row: dict) -> Optional[Tuple[int, str]]:
    """Return (tier_num, source) parsed from the row's Description column."""
    desc = row.get("Description") or row.get("description") or ""
    if not desc:
        # Sometimes the suffix is in a dedicated column
        for k, v in row.items():
            if "tier" in k.lower():
                desc = v
                break
    m = TIER_SUFFIX_RE.search(desc)
    if not m:
        return None
    return int(m.group(1)), m.group(2).strip()


def detect_hybrid(row: dict) -> bool:
    desc = row.get("Description") or row.get("description") or ""
    return any(p.search(desc) for p in HYBRID_TIER_PATTERNS)


def upstream_identifiers(resolution: dict) -> Set[str]:
    """Pull every fully-qualified identifier from _upstream_resolution.json."""
    out: Set[str] = set()
    for key in ("resolved_synapse", "resolved_remote", "resolved_sps",
                "migration_mirrors_discovered"):
        for ent in resolution.get(key, []) or []:
            if isinstance(ent, str):
                out.add(ent)
            elif isinstance(ent, dict):
                ident = ent.get("identifier") or ent.get("name") or ""
                if ident:
                    out.add(ident)
    return out


def _ident_in_upstream(source: str, upstream_ids: Set[str]) -> bool:
    """Does the source string match (substring) any upstream identifier?"""
    s = source.lower()
    if not s:
        return False
    for u in upstream_ids:
        u_l = u.lower()
        if s in u_l or u_l in s:
            return True
        # Also try the unqualified object name
        last = u.rsplit(".", 1)[-1].lower()
        if last and (last in s or s in last):
            return True
    return False


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--regen-dir", required=True, help="audits/regen-sample/{Schema}/{Object}/regen/attempt_N/")
    p.add_argument("--ddl-path", required=True, help="absolute path to the SSDT DDL .sql file")
    p.add_argument("--upstream-bundle", required=True, help="absolute path to _upstream_bundle.md")
    p.add_argument("--upstream-resolution", required=True, help="absolute path to _upstream_resolution.json")
    p.add_argument("--object-name", required=True)
    p.add_argument("--schema", required=True)
    p.add_argument("--max-trivial-cols", type=int, default=MAX_TRIVIAL_COLS,
                   help=f"trivial column-count threshold (default {MAX_TRIVIAL_COLS})")
    return p.parse_args()


def main() -> int:
    args = parse_args()
    regen_dir = Path(args.regen_dir)
    wiki_path = regen_dir / f"{args.object_name}.md"
    lineage_path = regen_dir / f"{args.object_name}.lineage.md"
    log_path = regen_dir / "auto_verify_log.md"
    verdict_path = regen_dir / "judge_verdict.json"

    log_lines: List[str] = [
        f"# auto-verify log -- {args.schema}.{args.object_name}",
        f"timestamp: {datetime.now(timezone.utc).isoformat()}",
        f"regen_dir: {regen_dir}",
        "",
    ]

    if not wiki_path.exists() or not lineage_path.exists():
        log_lines.append(f"FAIL: writer outputs missing ({wiki_path.name} / {lineage_path.name})")
        log_path.write_text("\n".join(log_lines), encoding="utf-8")
        return 3

    wiki_text = _read_text(wiki_path)
    ddl_cols = _extract_ddl_columns(Path(args.ddl_path))
    bundle_text = _read_text(Path(args.upstream_bundle)) if Path(args.upstream_bundle).exists() else ""
    no_upstream_marker = (regen_dir.parent / "_no_upstream_found.txt").exists() \
        or "**NO UPSTREAM WIKI**" in bundle_text \
        or "NO UPSTREAM WIKI was resolvable" in bundle_text

    try:
        resolution = json.loads(_read_text(Path(args.upstream_resolution)))
    except Exception as e:
        log_lines.append(f"FAIL: cannot parse _upstream_resolution.json: {e}")
        log_path.write_text("\n".join(log_lines), encoding="utf-8")
        return 1

    upstream_ids = upstream_identifiers(resolution)
    log_lines.append(f"DDL columns ({len(ddl_cols)}): {sorted(ddl_cols)}")
    log_lines.append(f"upstream_ids ({len(upstream_ids)}): {sorted(upstream_ids)}")
    log_lines.append(f"no_upstream_marker: {no_upstream_marker}")
    log_lines.append("")

    # ----- triviality gate ---------------------------------------------------
    if no_upstream_marker:
        log_lines.append("TRIVIALITY: SKIP (bundle has _no_upstream_found.txt or NO UPSTREAM marker)")
        log_path.write_text("\n".join(log_lines), encoding="utf-8")
        return 2

    if len(upstream_ids) == 0:
        log_lines.append("TRIVIALITY: SKIP (no upstream identifiers resolved)")
        log_path.write_text("\n".join(log_lines), encoding="utf-8")
        return 2

    if len(ddl_cols) > args.max_trivial_cols:
        log_lines.append(f"TRIVIALITY: SKIP ({len(ddl_cols)} cols > threshold {args.max_trivial_cols})")
        log_path.write_text("\n".join(log_lines), encoding="utf-8")
        return 2

    # ----- mechanical checks -------------------------------------------------
    rows = parse_element_rows(wiki_text)
    log_lines.append(f"Element rows parsed: {len(rows)}")

    checks: List[Tuple[str, bool, str]] = []

    checks.append(_check(
        "section_presence",
        all(re.search(rf"^##\s+{re.escape(s)}", wiki_text, re.MULTILINE)
            for s in REQUIRED_H2_SECTIONS),
        "8 H2 sections required"
    ))

    checks.append(_check(
        "row_count_matches_ddl",
        len(rows) == len(ddl_cols),
        f"rows={len(rows)} ddl_cols={len(ddl_cols)}"
    ))

    # Per-row checks
    tier_counts = {1: 0, 2: 0, 3: 0, 4: 0}
    rows_without_tier: List[str] = []
    rows_with_hybrid: List[str] = []
    bad_t1_sources: List[str] = []
    not_all_passthrough = False

    for row in rows:
        col = row.get("Element") or row.get("Column") or row.get("Name") or "?"
        if detect_hybrid(row):
            rows_with_hybrid.append(col)
        tinfo = detect_tier_for_row(row)
        if tinfo is None:
            rows_without_tier.append(col)
            continue
        tier_n, source = tinfo
        tier_counts[tier_n] = tier_counts.get(tier_n, 0) + 1
        if tier_n != 1:
            not_all_passthrough = True
        if tier_n == 1 and not _ident_in_upstream(source, upstream_ids):
            bad_t1_sources.append(f"{col} <- {source}")

    checks.append(_check(
        "every_row_has_tier_suffix",
        not rows_without_tier,
        f"missing tier on: {rows_without_tier[:5]}" if rows_without_tier else "all rows tagged"
    ))
    checks.append(_check(
        "no_hybrid_tier_labels",
        not rows_with_hybrid,
        f"hybrids: {rows_with_hybrid[:5]}" if rows_with_hybrid else "none"
    ))
    checks.append(_check(
        "every_t1_source_in_upstream",
        not bad_t1_sources,
        f"orphan T1 sources: {bad_t1_sources[:3]}" if bad_t1_sources else "all T1 sources match upstream"
    ))

    # Footer arithmetic (when present in the wiki)
    footer_match = FOOTER_TIER_RE.search(wiki_text)
    if footer_match:
        f1, f2, f3, f4 = (int(x) for x in footer_match.groups())
        footer_sum = f1 + f2 + f3 + f4
        checks.append(_check(
            "footer_arithmetic_matches_ddl",
            footer_sum == len(ddl_cols),
            f"footer sum={footer_sum} ({f1}+{f2}+{f3}+{f4})  ddl={len(ddl_cols)}"
        ))
        checks.append(_check(
            "footer_matches_element_table_counts",
            f1 == tier_counts[1] and f2 == tier_counts[2]
            and f3 == tier_counts[3] and f4 == tier_counts[4],
            f"footer=({f1},{f2},{f3},{f4})  table=({tier_counts[1]},{tier_counts[2]},{tier_counts[3]},{tier_counts[4]})"
        ))

    # Triviality gate part 2: every column must be Tier 1 passthrough for us
    # to be confident skipping the LLM judge. Mixed-tier objects can have
    # subtle ETL drift the judge needs to validate.
    if not_all_passthrough:
        log_lines.append("TRIVIALITY: SKIP (not all rows are Tier 1 passthrough)")
        for name, ok, detail in checks:
            log_lines.append(f"  [{'OK' if ok else 'FAIL'}] {name} -- {detail}")
        log_path.write_text("\n".join(log_lines), encoding="utf-8")
        return 2

    # ----- verdict -----------------------------------------------------------
    log_lines.append("CHECKS:")
    all_ok = True
    for name, ok, detail in checks:
        log_lines.append(f"  [{'OK' if ok else 'FAIL'}] {name} -- {detail}")
        if not ok:
            all_ok = False

    if not all_ok:
        log_lines.append("")
        log_lines.append("RESULT: mechanical checks failed -- defer to LLM judge")
        log_path.write_text("\n".join(log_lines), encoding="utf-8")
        return 1

    # All checks passed AND object is trivially-simple -> issue synthetic PASS.
    synth = {
        "verdict": {
            "verdict": "PASS",
            "weighted_score": SYNTH_PASS_SCORE,
            "auto_verified": True,
            "auto_verify_reason": (
                f"Trivially-simple ({len(ddl_cols)} cols, {len(upstream_ids)} upstream wikis, "
                f"all rows Tier 1 passthrough); mechanical checks all passed."
            ),
            "checks": [{"name": n, "passed": ok, "detail": d} for n, ok, d in checks],
        },
        "judge_skipped": True,
        "judge_skip_reason": "auto_verify",
        "schema": args.schema,
        "object": args.object_name,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    verdict_path.write_text(json.dumps(synth, indent=2), encoding="utf-8")
    log_lines.append("")
    log_lines.append(f"RESULT: AUTO-PASS issued (score {SYNTH_PASS_SCORE}); judge_verdict.json written")
    log_path.write_text("\n".join(log_lines), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
