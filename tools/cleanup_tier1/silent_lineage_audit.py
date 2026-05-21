#!/usr/bin/env python3
"""Detect downstream wiki columns that have NO tier tag but DO have a real
UC-lineage edge back to an upstream column. These are "silent" inheritance --
the wiki author copied a description from an upstream wiki without leaving any
provenance breadcrumb. Review-only -- no automatic fix.

For every UC object with at least one inbound column-lineage event:
  For every column in that object that appears in the wiki §4 Elements table:
    If the wiki row carries no `(Tier N - X)` tag at all:
      Find the upstream column it most likely inherits from (highest
      event_count in the lineage index) and emit a candidate Tier-N tag.

Output: audits/_silent_lineage_<ts>.csv
"""
from __future__ import annotations

import argparse
import csv
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "tools"))

from cleanup_tier1 import dag
from tier1_audit.parser import parse_wiki_columns

REPORT_FIELDS = [
    "wiki_path",
    "uc_full_name",
    "column_name",
    "candidate_upstream_full_name",
    "candidate_upstream_column",
    "lineage_event_count",
    "current_description_head",
    "proposed_tier_tag",
]


def _upstream_for(uc_full_name: str, col: str) -> tuple[str, str, int] | None:
    """Cheap reverse-lineage lookup. We scan _lineage_index for rows whose
    downstream_full_name + downstream_column match, return the upstream with
    the highest event_count."""
    dag.load_dag()
    assert dag._lineage_index is not None  # noqa: SLF001
    best: tuple[str, str, int] | None = None
    needle_dn = uc_full_name.lower()
    needle_dc = col.lower()
    for (_src_table, _src_col), entries in dag._lineage_index.items():  # noqa: SLF001
        for e in entries:
            if (e["downstream_full_name"].lower() == needle_dn
                    and e["downstream_column"].lower() == needle_dc):
                cand = (_src_table, _src_col, e["event_count"])
                if best is None or cand[2] > best[2]:
                    best = cand
    return best


def audit(scope_globs: list[str]) -> list[dict]:
    dag.load_dag()
    out: list[dict] = []

    wikis: list[tuple[str, str]] = []
    for pattern in scope_globs:
        for wp in REPO.glob(pattern):
            if not wp.is_file() or not wp.suffix == ".md":
                continue
            stem_low = wp.stem.lower()
            if any(s in stem_low for s in
                   (".lineage", ".review-needed", ".deploy-report", ".alter")):
                continue
            rel = str(wp.relative_to(REPO)).replace("\\", "/")
            fn = dag.full_name_for(rel)
            if not fn:
                continue
            wikis.append((rel, fn))

    for rel, fn in wikis:
        try:
            cols = parse_wiki_columns(REPO / rel)
        except Exception:
            continue
        for c in cols:
            if c.tier_tags:
                continue
            up = _upstream_for(fn, c.column_name)
            if not up:
                continue
            up_table, up_col, ec = up
            proposed = f"(Tier N - {up_table}.{up_col})"
            out.append({
                "wiki_path": rel,
                "uc_full_name": fn,
                "column_name": c.column_name,
                "candidate_upstream_full_name": up_table,
                "candidate_upstream_column": up_col,
                "lineage_event_count": ec,
                "current_description_head": (c.description or "")[:140],
                "proposed_tier_tag": proposed,
            })
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--scope", action="append", default=[],
                    help="Glob (relative to repo) of wikis to audit. "
                         "Repeatable. Default: knowledge/synapse/Wiki/**/*.md + "
                         "knowledge/UC_generated/**/*.md")
    ap.add_argument("--out", default="")
    args = ap.parse_args()

    if not args.scope:
        args.scope = [
            "knowledge/synapse/Wiki/**/*.md",
            "knowledge/UC_generated/**/*.md",
        ]

    rows = audit(args.scope)
    if args.out:
        out_path = Path(args.out)
    else:
        ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H-%M-%SZ")
        out_path = REPO / "audits" / f"_silent_lineage_{ts}.csv"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=REPORT_FIELDS)
        w.writeheader()
        for r in rows:
            w.writerow(r)
    print(f"Wrote {len(rows)} silent-inheritance candidates -> {out_path}")


if __name__ == "__main__":
    main()
