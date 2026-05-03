"""Phase 5 follow-on: dump UC actual columns vs wiki claimed columns
for EXW_Inventory_Snapshot_History to make column-drift fix actionable."""
from __future__ import annotations

import os
import re
from pathlib import Path

from databricks import sql

REPO_ROOT = Path(__file__).resolve().parents[1]
HOST = "adb-5142916747090026.6.azuredatabricks.net"
HTTP_PATH = "/sql/1.0/warehouses/208214768b0e0308"
TARGET = "main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history"
ALTER = REPO_ROOT / "knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_Inventory_Snapshot_History.alter.sql"


def conn():
    tok = os.environ.get("DATABRICKS_TOKEN")
    if tok:
        return sql.connect(server_hostname=HOST, http_path=HTTP_PATH, access_token=tok)
    return sql.connect(server_hostname=HOST, http_path=HTTP_PATH, auth_type="databricks-oauth")


def main() -> int:
    c = conn()
    cur = c.cursor()
    cur.execute(f"DESCRIBE TABLE {TARGET}")
    uc_cols = []
    for r in cur.fetchall():
        if r[0] and not r[0].startswith("#"):
            uc_cols.append(r[0])

    text = ALTER.read_text(encoding="utf-8")
    wiki_cols = re.findall(r"ALTER COLUMN `([^`]+)`", text)
    wiki_unique = sorted(set(wiki_cols))

    uc_set = set(uc_cols)
    wiki_set = set(wiki_unique)
    only_in_wiki = sorted(wiki_set - uc_set)
    only_in_uc = sorted(uc_set - wiki_set)
    matching = sorted(wiki_set & uc_set)

    print(f"UC actual columns ({len(uc_cols)}):")
    for c2 in uc_cols:
        print(f"  {c2}")
    print()
    print(f"Wiki/alter columns ({len(wiki_unique)}):")
    for c2 in wiki_unique:
        in_uc = "OK" if c2 in uc_set else "MISS"
        print(f"  [{in_uc:<4}] `{c2}`")
    print()
    print(f"=== DRIFT ANALYSIS ===")
    print(f"  matching          : {len(matching)}")
    print(f"  only in wiki/alter: {len(only_in_wiki)}")
    for c2 in only_in_wiki:
        print(f"    - `{c2}`")
    print(f"  only in UC        : {len(only_in_uc)}")
    for c2 in only_in_uc:
        print(f"    - `{c2}`")

    cur.close()
    c.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
