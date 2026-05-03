"""Phase 5 fix: substitute space-named columns with underscore form in
EXW_Inventory_Snapshot_History.alter.sql, then redeploy. Limited to the
13 known mismatches (no broad text replacement)."""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

from databricks import sql

REPO_ROOT = Path(__file__).resolve().parents[1]
HOST = "adb-5142916747090026.6.azuredatabricks.net"
HTTP_PATH = "/sql/1.0/warehouses/208214768b0e0308"
TARGET = "main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history"
ALTER = REPO_ROOT / "knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_Inventory_Snapshot_History.alter.sql"

DRIFT = {
    "Allocated 30 days": "Allocated_30_days",
    "Allocated 7 days": "Allocated_7_days",
    "Allocated Daily": "Allocated_Daily",
    "Allocated Total": "Allocated_Total",
    "Created 30 days": "Created_30_days",
    "Created 7 days": "Created_7_days",
    "Created Daily": "Created_Daily",
    "Date for Report": "Date_for_Report",
    "Funded Free": "Funded_Free",
    "Funded Occupied": "Funded_Occupied",
    "Total AllocatedOmnibuses": "Total_AllocatedOmnibuses",
    "Total AllocatedToUsers": "Total_AllocatedToUsers",
    "Total Created": "Total_Created",
}


def conn():
    tok = os.environ.get("DATABRICKS_TOKEN")
    if tok:
        return sql.connect(server_hostname=HOST, http_path=HTTP_PATH, access_token=tok)
    return sql.connect(server_hostname=HOST, http_path=HTTP_PATH, auth_type="databricks-oauth")


def patch_alter() -> str:
    text = ALTER.read_text(encoding="utf-8")
    out = text
    for old, new in DRIFT.items():
        # Only replace when the name is enclosed in backticks (column refs)
        out = out.replace(f"`{old}`", f"`{new}`")
    return out


def split_statements(text: str) -> list[str]:
    out: list[str] = []
    buf: list[str] = []
    in_str = False
    i = 0
    while i < len(text):
        ch = text[i]
        if not in_str:
            if ch == "-" and text[i : i + 2] == "--":
                nl = text.find("\n", i)
                if nl < 0:
                    break
                i = nl + 1
                continue
            if ch == "'":
                in_str = True
                buf.append(ch)
                i += 1
                continue
            if ch == ";":
                stmt = "".join(buf).strip()
                if stmt:
                    out.append(stmt)
                buf = []
                i += 1
                continue
            buf.append(ch)
            i += 1
            continue
        else:
            if ch == "'":
                if text[i : i + 2] == "''":
                    buf.append("''")
                    i += 2
                    continue
                in_str = False
                buf.append(ch)
                i += 1
                continue
            buf.append(ch)
            i += 1
    tail = "".join(buf).strip()
    if tail:
        out.append(tail)
    return out


def main() -> int:
    patched = patch_alter()
    print(f"=== Patching {ALTER.name} ===")
    n_before = len(re.findall(r"ALTER COLUMN `[^`]+`", ALTER.read_text(encoding='utf-8')))
    n_after = len(re.findall(r"ALTER COLUMN `[^`]+`", patched))
    print(f"  ALTER COLUMN refs: before={n_before}, after={n_after}")

    miss_before = sum(patched.count(f"`{k}`") for k in DRIFT)
    print(f"  remaining space-named refs (should be 0): {miss_before}")

    ALTER.write_text(patched, encoding="utf-8")
    print(f"  wrote patched alter file")

    print(f"\n=== Re-deploying ===")
    c = conn()
    cur = c.cursor()
    stmts = split_statements(patched)
    ok = fail = 0
    fails: list[str] = []
    for s in stmts:
        upper = s.upper().lstrip()
        if not (upper.startswith("ALTER ") or upper.startswith("COMMENT ON ")):
            continue
        try:
            cur.execute(s)
            ok += 1
        except Exception as e:
            fail += 1
            fails.append(f"{str(e)[:120]} | {s[:120]}")
    print(f"  ran {ok+fail} stmts: {ok} ok, {fail} fail")
    for f in fails[:5]:
        print(f"    {f}")

    cur.execute(
        f"SELECT COUNT(*) FROM system.information_schema.columns "
        f"WHERE table_catalog||'.'||table_schema||'.'||table_name = '{TARGET}' "
        f"  AND length(comment) > 0"
    )
    cm = cur.fetchone()[0]
    cur.execute(
        f"SELECT COUNT(*) FROM system.information_schema.columns "
        f"WHERE table_catalog||'.'||table_schema||'.'||table_name = '{TARGET}'"
    )
    tot = cur.fetchone()[0]
    print(f"\n=== AFTER: {cm}/{tot} cols have comments ===")
    cur.close()
    c.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
