"""For each UC table that has empty column comments, check whether a wiki §4
exists for it. This identifies the deployable gap.

UC -> Wiki path heuristic:
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_<X>            -> Wiki/BI_DB_dbo/Tables/<X>.md  or  Wiki/BI_DB_dbo/Functions/<X>.md  or  Wiki/BI_DB_dbo/Views/<X>.md
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_<X>      -> Wiki/BI_DB_dbo/Tables/BI_DB_<X>.md  (etc.)
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_<X>                -> Wiki/DWH_dbo/...
  main.etoro_kpi_prep.<X>                                 -> heuristic name matching against Wiki/BI_DB_dbo/Functions/Function_<X>.md
"""
from __future__ import annotations
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WIKI_ROOT = ROOT / "knowledge" / "synapse" / "Wiki"

UC_PREFIX_MAP = {
    "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_": ("BI_DB_dbo", ""),
    "main.dwh.gold_sql_dp_prod_we_dwh_dbo_": ("DWH_dbo", ""),
    "main.dwh.gold_sql_dp_prod_we_dealing_dbo_": ("Dealing_dbo", ""),
    "main.bi_db.gold_sql_dp_prod_we_dealing_dbo_": ("Dealing_dbo", ""),
    "main.bi_db.gold_sql_dp_prod_we_emoney_dbo_": ("eMoney_dbo", ""),
    "main.dwh.gold_sql_dp_prod_we_emoney_dbo_": ("eMoney_dbo", ""),
}

# Cache wiki files index
WIKI_INDEX: dict[str, Path] = {}
for p in WIKI_ROOT.rglob("*.md"):
    WIKI_INDEX[p.stem.lower()] = p


def uc_to_wiki(uc_fqn: str) -> Path | None:
    """Given main.schema.table, return the wiki path or None."""
    fqn = uc_fqn.lower()
    for prefix, (schema_dir, _) in UC_PREFIX_MAP.items():
        if fqn.startswith(prefix.lower()):
            stem = fqn[len(prefix):]
            stem = re.sub(r"^bi_db_", "BI_DB_", stem, flags=re.IGNORECASE) if "bi_db" in prefix else stem
            for candidate in (stem, "bi_db_" + stem, stem.replace("_", "")):
                hit = WIKI_INDEX.get(candidate.lower())
                if hit:
                    return hit
    # etoro_kpi_prep view convention: main.etoro_kpi_prep.v_revenue_x -> Function_Revenue_X.md
    m = re.match(r"main\.etoro_kpi_prep\.(v|mv|tvf|tf)_(.+)", fqn)
    if m:
        name = m.group(2)
        for candidate in (f"function_{name}", name, "function_" + name.replace("_", "")):
            hit = WIKI_INDEX.get(candidate.lower())
            if hit:
                return hit
    return None


def main() -> int:
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    if not src:
        print("Pass a CSV of (schema,table,empty_col_count) or run with stdin", file=sys.stderr)
        return 2
    print(f"Wiki index: {len(WIKI_INDEX)} files")
    with src.open(encoding="utf-8") as fh:
        reader = csv.reader(fh)
        header = next(reader)
        rows = list(reader)
    print(f"Input rows: {len(rows)}")
    print()
    have = 0
    missing = 0
    out_rows = []
    for r in rows:
        sch, tbl, empty = r[0], r[1], int(r[2])
        fqn = f"main.{sch}.{tbl}"
        wiki = uc_to_wiki(fqn)
        if wiki:
            have += 1
            rel = str(wiki.relative_to(ROOT)).replace("\\", "/")
            out_rows.append((empty, fqn, rel))
        else:
            missing += 1
            out_rows.append((empty, fqn, ""))
    out_rows.sort(key=lambda x: -x[0])
    print(f"Empty-column tables: {len(rows)}")
    print(f"  with matching wiki: {have}")
    print(f"  without wiki:       {missing}")
    print()
    print("Top 20 by empty-col count (have wiki):")
    shown = 0
    for empty, fqn, rel in out_rows:
        if rel and shown < 20:
            print(f"  {empty:4d}  {fqn}  ->  {rel}")
            shown += 1
    print()
    print("Top 20 by empty-col count (no wiki):")
    shown = 0
    for empty, fqn, rel in out_rows:
        if not rel and shown < 20:
            print(f"  {empty:4d}  {fqn}")
            shown += 1

    deployable = sum(e for e, f, r in out_rows if r)
    undeployable = sum(e for e, f, r in out_rows if not r)
    print()
    print(f"Total empty cols where we have a wiki:    {deployable}")
    print(f"Total empty cols where we have NO wiki:    {undeployable}")

    out_path = ROOT / "audits" / "_uc_empty_audit" / "empty_with_wiki.csv"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["empty_cols", "uc_fqn", "wiki_path"])
        for empty, fqn, rel in out_rows:
            w.writerow([empty, fqn, rel])
    print(f"Wrote: {out_path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
