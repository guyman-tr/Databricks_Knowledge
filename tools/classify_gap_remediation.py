"""Classify the UC comment gap tables into actionable buckets.

For each entry in knowledge/_dwh_uc_gap_table_level.csv, look up the wiki .md
Element-table column count and compare against UC col_count. Then partition:

  - B  : wiki >= UC cols  AND  has .alter.sql -> just redeploy (cheapest)
  - A1 : wiki >= UC cols  AND  no .alter.sql  -> scaffold + deploy
  - A2 : wiki <  UC cols  AND  wiki has > 50% coverage -> partial Speckit fill-in
  - A3 : wiki <  UC cols  AND  wiki has <= 50% coverage -> full Speckit regen
  - C  : no wiki .md      -> classify junk vs real (backup/test/temp/util/val names)

Outputs `knowledge/_dwh_gap_remediation_plan.csv` and prints a summary.
"""
from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
WIKI = REPO / "knowledge" / "synapse" / "Wiki"
sys.path.insert(0, str(WIKI))
from merge_wiki_column_comments_into_alter import parse_wiki_column_catalog  # type: ignore


JUNK_RE = re.compile(
    r"(_backup$|_bck$|_test$|_archive$|_bak$|_old$|"
    r"^bi_db_outliers_new$|"  # historical odd cases
    r"^from_synapse_|^v_from_synapse_|"
    r"^util_|^val_|"
    r"_temp_|_tmp_|"
    r"^scratch_)",
    re.IGNORECASE,
)


def syn_table_from_uc(source_schema: str, uc_table: str) -> str:
    """Recover the Synapse object name from the gold_* UC name."""
    schema_token = source_schema.lower()
    marker = f"gold_sql_dp_prod_we_{schema_token}_"
    if uc_table.startswith(marker):
        return uc_table[len(marker):]
    return uc_table


def find_wiki_md(source_schema: str, syn_table_lower: str) -> Path | None:
    base = WIKI / source_schema
    if not base.is_dir():
        return None
    for sub in ("Tables", "Views"):
        d = base / sub
        if not d.is_dir():
            continue
        for f in d.glob("*.md"):
            if f.name.endswith(".lineage.md") or f.name.endswith(".review-needed.md"):
                continue
            if f.stem.lower() == syn_table_lower:
                return f
    return None


def count_wiki_cols(md: Path) -> int:
    try:
        text = md.read_text(encoding="utf-8", errors="replace")
        rows = parse_wiki_column_catalog(text)
        return len(rows)
    except Exception:
        return 0


def main() -> int:
    gap_csv = REPO / "knowledge" / "_dwh_uc_gap_table_level.csv"
    if not gap_csv.is_file():
        print(f"ERROR: missing {gap_csv}", file=sys.stderr)
        return 1

    out_csv = REPO / "knowledge" / "_dwh_gap_remediation_plan.csv"
    rows_in = list(csv.DictReader(gap_csv.open(encoding="utf-8")))

    out_rows = []
    bucket: dict[str, list[dict]] = {
        "B": [], "A1": [], "A2": [], "A3": [], "C_real": [], "C_junk": [],
    }

    for r in rows_in:
        source_schema = r["source_schema"]
        uc_table = r["uc_table"]
        col_count = int(r["col_count"])
        missing = int(r["missing"])
        syn = syn_table_from_uc(source_schema, uc_table)

        md = find_wiki_md(source_schema, syn.lower())
        if md is None:
            # Cat C
            cat = "C_junk" if JUNK_RE.search(syn.lower()) else "C_real"
            alter = None
        else:
            wiki_cols = count_wiki_cols(md)
            alter = md.with_name(md.stem + ".alter.sql")
            alter_exists = alter.is_file()
            if wiki_cols >= col_count:
                cat = "B" if alter_exists else "A1"
            else:
                # wiki incomplete
                coverage = wiki_cols / col_count if col_count else 0
                cat = "A2" if coverage > 0.5 else "A3"

        out = {
            "category": cat,
            "source_schema": source_schema,
            "catalog": r["catalog"],
            "uc_schema": r["uc_schema"],
            "uc_table": uc_table,
            "uc_full_target": f"{r['catalog']}.{r['uc_schema']}.{uc_table}",
            "uc_col_count": col_count,
            "missing_cols": missing,
            "wiki_md": str(md.relative_to(REPO).as_posix()) if md else "",
            "wiki_col_count": (count_wiki_cols(md) if md else 0),
            "alter_sql_exists": (
                "yes" if md and md.with_name(md.stem + ".alter.sql").is_file()
                else "no"
            ),
        }
        out_rows.append(out)
        bucket[cat].append(out)

    with out_csv.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(out_rows[0].keys()))
        w.writeheader()
        for row in sorted(out_rows, key=lambda x: (x["category"], -x["missing_cols"])):
            w.writerow(row)

    print(f"Wrote {out_csv.relative_to(REPO)}")
    print(f"\nBucket summary ({len(rows_in)} total tables):\n")
    for cat in ("B", "A1", "A2", "A3", "C_real", "C_junk"):
        rs = bucket[cat]
        if not rs:
            continue
        total_missing = sum(r["missing_cols"] for r in rs)
        descs = {
            "B": "wiki complete + has .alter.sql -> JUST REDEPLOY",
            "A1": "wiki complete, no .alter.sql -> SCAFFOLD + DEPLOY",
            "A2": "wiki partial (>50%) -> Speckit FILL-IN",
            "A3": "wiki sparse (<=50%) -> FULL Speckit regen",
            "C_real": "no wiki, real business object -> FULL Speckit",
            "C_junk": "no wiki, junk/backup/test -> SKIP",
        }
        print(f"  {cat:<7}  tables={len(rs):>4}  missing_cols={total_missing:>5}  "
              f"-- {descs[cat]}")

    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
