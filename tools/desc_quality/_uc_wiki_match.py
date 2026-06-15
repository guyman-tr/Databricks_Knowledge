"""Cross-reference UC tables that have empty column comments against the wiki
tree. Produces a CSV of (uc_fqn, wiki_path, empty_cols, wiki_cols, col_overlap)
to inform Phase-B-v2 cohort deploys.

Heuristics for UC -> wiki mapping (only the parts we have wikis for):
  main.<sch>.gold_sql_dp_prod_we_<dbschema>_<dbobj>_<rest>
    -> knowledge/synapse/Wiki/<DbSchema>_<dbobj>/{Tables,Views,Functions}/<rest>.md
       where DbSchema=BI_DB / DWH / Dealing / eMoney / etc.

  main.etoro_kpi_prep.v_<x>  / mv_<x>  / tvf_<x>
    -> knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_<MatchingName>.md
"""
from __future__ import annotations
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WIKI_ROOT = ROOT / "knowledge" / "synapse" / "Wiki"

# Build a fast lookup: lowercase-stem -> Path
WIKI_INDEX: dict[str, Path] = {}
for p in WIKI_ROOT.rglob("*.md"):
    WIKI_INDEX[p.stem.lower()] = p

# UC prefix -> (wiki_subdir_root, db_object_prefix)
# wiki path is WIKI_ROOT / "<DbSchema>_dbo" / ("Tables"|"Views"|"Functions") / "<stem>.md"
GOLD_PREFIXES = {
    "main.dwh.gold_sql_dp_prod_we_dwh_dbo_": "DWH_dbo",
    "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_": "BI_DB_dbo",
    "main.bi_db.gold_sql_dp_prod_we_dealing_dbo_": "Dealing_dbo",
    "main.dwh.gold_sql_dp_prod_we_dealing_dbo_": "Dealing_dbo",
    "main.bi_db.gold_sql_dp_prod_we_emoney_dbo_": "eMoney_dbo",
    "main.dwh.gold_sql_dp_prod_we_emoney_dbo_": "eMoney_dbo",
    "main.dwh.gold_sql_dp_prod_we_exw_dbo_": "ExW_dbo",
    "main.bi_db.gold_sql_dp_prod_we_exw_dbo_": "ExW_dbo",
}


def find_wiki_for_uc(uc_fqn: str) -> Path | None:
    fqn = uc_fqn.lower()
    # Strict gold mirror prefix
    for prefix, wiki_subdir in GOLD_PREFIXES.items():
        if fqn.startswith(prefix):
            stem = fqn[len(prefix):]
            # Try both with original casing recovery (lowercase lookup works since we
            # indexed by lowercased stems). Also try a `BI_DB_<rest>` variant since
            # many BI_DB wikis prefix the object name.
            candidates = [stem]
            if wiki_subdir == "BI_DB_dbo" and not stem.startswith("bi_db_"):
                candidates.append("bi_db_" + stem)
            for cand in candidates:
                hit = WIKI_INDEX.get(cand)
                if hit and wiki_subdir.lower() in str(hit).lower().replace("\\", "/"):
                    return hit
            # Fall back to any stem match even if subdir differs
            for cand in candidates:
                hit = WIKI_INDEX.get(cand)
                if hit:
                    return hit
            return None
    # etoro_kpi_prep V/MV/TVF views — try Function_<rest>.md
    m = re.match(r"main\.etoro_kpi_prep\.(v|mv|tvf|tf)_(.+)", fqn)
    if m:
        name = m.group(2)
        for cand in (
            f"function_{name}",
            f"function_{name}".replace("__", "_"),
            name,
        ):
            hit = WIKI_INDEX.get(cand)
            if hit:
                return hit
        # snake -> different casings; try removing trailing _<suffix>
        bits = name.split("_")
        for n in range(len(bits), 0, -1):
            cand = f"function_{'_'.join(bits[:n])}"
            hit = WIKI_INDEX.get(cand)
            if hit:
                return hit
    return None


def parse_wiki_cols(path: Path) -> set[str]:
    txt = path.read_text(encoding="utf-8")
    m4 = re.search(r"## 4\. Output Columns\s*\n(.*?)(?=\n## |\Z)", txt, re.DOTALL)
    if not m4:
        return set()
    cols: set[str] = set()
    for line in m4.group(1).splitlines():
        line = line.strip()
        if not line.startswith("|") or line.startswith("|---") or "# |" in line:
            continue
        parts = [p.strip() for p in line.split("|")]
        if len(parts) < 6:
            continue
        c = parts[2].strip().strip("*").strip("`")
        if c and c.lower() != "column":
            cols.add(c.lower())
    return cols


def main() -> int:
    src = ROOT / sys.argv[1] if len(sys.argv) > 1 else None
    if not src:
        print("Pass a CSV: schema,table,empty_cols", file=sys.stderr)
        return 2

    rows = list(csv.DictReader(src.open(encoding="utf-8")))
    print(f"Input: {len(rows)} UC tables with empty cols")

    out_path = ROOT / "audits" / "_uc_empty_audit" / "uc_wiki_match.csv"
    out_path.parent.mkdir(parents=True, exist_ok=True)

    # Also need to know which UC cols are empty (not just count) — we'll fetch that
    # in a follow-up via Databricks. For now we just match table -> wiki.
    rows_out = []
    matched = unmatched = 0
    matched_cols = unmatched_cols = 0
    for r in rows:
        sch = r["table_schema"]
        tbl = r["table_name"]
        empty = int(r["empty_cols"])
        fqn = f"main.{sch}.{tbl}"
        wiki = find_wiki_for_uc(fqn)
        if wiki:
            matched += 1
            matched_cols += empty
            wiki_cols = parse_wiki_cols(wiki)
            rows_out.append({
                "uc_fqn": fqn,
                "empty_cols": empty,
                "wiki_path": str(wiki.relative_to(ROOT)).replace("\\", "/"),
                "wiki_cols_in_section4": len(wiki_cols),
            })
        else:
            unmatched += 1
            unmatched_cols += empty
            rows_out.append({
                "uc_fqn": fqn,
                "empty_cols": empty,
                "wiki_path": "",
                "wiki_cols_in_section4": 0,
            })

    rows_out.sort(key=lambda x: -x["empty_cols"])
    with out_path.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["uc_fqn", "empty_cols", "wiki_path", "wiki_cols_in_section4"])
        w.writeheader()
        for r in rows_out:
            w.writerow(r)

    print()
    print(f"Matched (have wiki):    {matched:4d} objects, {matched_cols:5d} empty cols")
    print(f"Unmatched (no wiki):    {unmatched:4d} objects, {unmatched_cols:5d} empty cols")
    print()
    print("Top 25 matched (by empty-col count):")
    shown = 0
    for r in rows_out:
        if r["wiki_path"]:
            print(f"  {r['empty_cols']:4d} empty  |  §4 has {r['wiki_cols_in_section4']:3d} cols  |  {r['uc_fqn']}")
            shown += 1
            if shown >= 25:
                break
    print()
    print(f"Wrote: {out_path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
