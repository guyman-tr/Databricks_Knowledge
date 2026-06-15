"""Detect alter.sql files where COMMENT was scaffolded with the Tier token
(T1/T2/T3/T4) instead of the real description from the wiki Elements table.

Root cause:
  An older version of `parse_wiki_column_catalog` (in
  tools/merge_wiki_column_comments_into_alter.py) walked the wiki Elements
  row from the TYPE cell forward and would stop on the first non-empty cell.
  For wikis whose Elements table carried a separate `Tier` column placed
  BEFORE the description cell, the parser captured the tier value ("T2") as
  the column description. The current parser fixes this via a "substantial"
  cell filter, but historic scaffold runs persisted bad comments into
  .alter.sql AND those files were deployed into UC.

Bug signature in the alter file:
  ALTER TABLE <uc> ALTER COLUMN <col> COMMENT 'T1' | 'T2' | 'T3' | 'T4';

This script:
  1. Walks every .alter.sql under knowledge/synapse/Wiki
  2. Parses COMMENT 'X' values for each column line
  3. Flags any file where >=1 column comment equals exactly T1/T2/T3/T4
  4. Reports counts per file and aggregate stats
  5. Cross-checks against deploy logs to identify which were deployed to UC

Output: CSV at tools/lakebridge/tier_drift_report.csv plus stdout summary.
"""
from __future__ import annotations

import csv
import re
from pathlib import Path
from collections import Counter

REPO = Path(__file__).resolve().parents[1]
WIKI_ROOT = REPO / "knowledge" / "synapse" / "Wiki"
OUT_CSV = REPO / "tools" / "lakebridge" / "tier_drift_report.csv"

TIER_TOKENS = {"T0", "T1", "T2", "T3", "T4"}

# Header / metadata tokens that pollute the comment when the parser anchors
# on a section-header row (col_name='Column', desc='Description'/'Tier'/etc.)
# or on the wrong cell when the wiki table layout puts metadata before the
# real description. Comments equal to any of these (case-insensitive) are
# definitely wrong and should be re-generated.
HEADER_TOKENS = {
    "description", "tier", "confidence", "column", "element", "type",
    "nullable", "null", "not null", "source", "rule", "notes",
    "code-backed", "code backed", "inferred", "verbatim",
    "sentinel", "category", "yes", "no",
}

COMMENT_RE = re.compile(
    r"ALTER\s+TABLE\s+(\S+)\s+ALTER\s+COLUMN\s+([^\s]+)\s+COMMENT\s+'((?:[^']|'')*)'",
    re.IGNORECASE,
)

UC_TARGET_RE = re.compile(r"^--\s*UC Target:\s*(\S+)", re.MULTILINE)
LAST_EXEC_RE = re.compile(r"^--\s*Timestamp:\s*(.+)$", re.MULTILINE)
LAST_EXEC_STATUS_RE = re.compile(r"^--\s*Statements:\s*(\d+)/(\d+)\s*(\w+)", re.MULTILINE)


def analyze_file(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="replace")
    uc_target_m = UC_TARGET_RE.search(text)
    uc_target = uc_target_m.group(1).strip() if uc_target_m else ""

    deployed = "LAST EXECUTION" in text
    deploy_ts_m = LAST_EXEC_RE.search(text)
    deploy_ts = deploy_ts_m.group(1).strip() if deploy_ts_m else ""

    deploy_status_m = LAST_EXEC_STATUS_RE.search(text)
    deploy_status = ""
    if deploy_status_m:
        succ, tot, label = deploy_status_m.groups()
        deploy_status = f"{succ}/{tot} {label}"

    total_cols = 0
    tier_cols = []
    header_cols = []
    for m in COMMENT_RE.finditer(text):
        total_cols += 1
        col = m.group(2).strip("`")
        comment = m.group(3).strip()
        if comment in TIER_TOKENS:
            tier_cols.append((col, comment))
        elif comment.lower() in HEADER_TOKENS:
            header_cols.append((col, comment))

    return {
        "file": str(path.relative_to(REPO)).replace("\\", "/"),
        "uc_target": uc_target,
        "deployed": "yes" if deployed else "no",
        "deploy_timestamp": deploy_ts,
        "deploy_status": deploy_status,
        "total_column_comments": total_cols,
        "tier_only_count": len(tier_cols),
        "header_token_count": len(header_cols),
        "bad_count": len(tier_cols) + len(header_cols),
        "tier_only_pct": (round(100 * len(tier_cols) / total_cols, 1) if total_cols else 0.0),
        "bad_pct": (round(100 * (len(tier_cols) + len(header_cols)) / total_cols, 1) if total_cols else 0.0),
        "tier_only_columns_sample": ";".join(f"{c}={t}" for c, t in tier_cols[:5]),
        "header_token_columns_sample": ";".join(f"{c}={t}" for c, t in header_cols[:5]),
    }


def main() -> None:
    rows = []
    for ap in sorted(WIKI_ROOT.rglob("*.alter.sql")):
        r = analyze_file(ap)
        if r["bad_count"] > 0:
            rows.append(r)

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(
            fh,
            fieldnames=[
                "file",
                "uc_target",
                "deployed",
                "deploy_timestamp",
                "deploy_status",
                "total_column_comments",
                "tier_only_count",
                "header_token_count",
                "bad_count",
                "tier_only_pct",
                "bad_pct",
                "tier_only_columns_sample",
                "header_token_columns_sample",
            ],
        )
        w.writeheader()
        w.writerows(rows)

    schema_counts = Counter()
    deployed_files = 0
    total_tier_cols = 0
    total_header_cols = 0
    for r in rows:
        sch = r["file"].split("/")[3] if r["file"].count("/") >= 3 else "?"
        schema_counts[sch] += 1
        total_tier_cols += r["tier_only_count"]
        total_header_cols += r["header_token_count"]
        if r["deployed"] == "yes":
            deployed_files += 1

    print("=" * 70)
    print(f"Affected .alter.sql files: {len(rows)}")
    print(f"  of which deployed to UC: {deployed_files}")
    print(f"Total bad column comments: {total_tier_cols + total_header_cols}")
    print(f"  tier-only ('T1'/'T2'/'T3'/'T4'): {total_tier_cols}")
    print(f"  header-pollution ('Description'/'Tier'/...): {total_header_cols}")
    print()
    print("By schema:")
    for sch, n in schema_counts.most_common():
        print(f"  {sch:<20s} {n:>4d} files")
    print()
    print(f"Detail CSV: {OUT_CSV.relative_to(REPO).as_posix()}")
    print()
    print("Top 15 worst offenders (by total bad_count):")
    for r in sorted(rows, key=lambda x: -x["bad_count"])[:15]:
        deploy_flag = "[deployed]" if r["deployed"] == "yes" else "[NOT deployed]"
        print(
            f"  bad={r['bad_count']:>4d}/{r['total_column_comments']:>4d} ({r['bad_pct']:>5.1f}%) "
            f"tier={r['tier_only_count']:>4d} hdr={r['header_token_count']:>3d} "
            f"{deploy_flag:<16s} {r['file']}"
        )


if __name__ == "__main__":
    main()
