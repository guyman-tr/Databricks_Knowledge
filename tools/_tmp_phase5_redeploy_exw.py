"""Phase 5 redeploy for the 3 EXW gold objects whose comments got wiped
by a downstream gold-pipeline re-materialize. Re-runs the existing
alter files (already on disk, already succeeded once) without touching
the deploy-index. Also restores the 3 probe columns my detector overwrote.
"""
from __future__ import annotations

import os
import re
import sys
import time
from pathlib import Path

from databricks import sql

REPO_ROOT = Path(__file__).resolve().parents[1]
HOST = "adb-5142916747090026.6.azuredatabricks.net"
HTTP_PATH = "/sql/1.0/warehouses/208214768b0e0308"

ALTERS = [
    REPO_ROOT / "knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_Inventory_Snapshot_History.alter.sql",
    REPO_ROOT / "knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_WalletInventory.alter.sql",
    REPO_ROOT / "knowledge/synapse/Wiki/EXW_dbo/Views/EXW_V_RedeemReconciliation.alter.sql",
]


def conn():
    tok = os.environ.get("DATABRICKS_TOKEN")
    if tok:
        return sql.connect(server_hostname=HOST, http_path=HTTP_PATH, access_token=tok)
    return sql.connect(
        server_hostname=HOST, http_path=HTTP_PATH, auth_type="databricks-oauth"
    )


def split_statements(text: str) -> list[str]:
    """Split a Synapse-style alter file into top-level statements.
    Strips comments, keeps single-quote string literals intact.
    Statements are terminated by semicolons.
    """
    out: list[str] = []
    buf: list[str] = []
    in_str = False
    i = 0
    while i < len(text):
        ch = text[i]
        if not in_str:
            if ch == "-" and text[i : i + 2] == "--":
                # line comment
                nl = text.find("\n", i)
                if nl < 0:
                    break
                i = nl + 1
                continue
            if ch == "/" and text[i : i + 2] == "/*":
                end = text.find("*/", i + 2)
                if end < 0:
                    break
                i = end + 2
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


def run_alter(cur, alter_path: Path) -> tuple[int, int, list[str]]:
    text = alter_path.read_text(encoding="utf-8")
    stmts = split_statements(text)
    ok = 0
    fail = 0
    failures: list[str] = []
    for s in stmts:
        upper = s.upper().lstrip()
        if not (upper.startswith("ALTER ") or upper.startswith("COMMENT ON ")):
            continue
        try:
            cur.execute(s)
            ok += 1
        except Exception as exc:
            fail += 1
            failures.append(f"{str(exc)[:150]} | {s[:150]}")
    return ok, fail, failures


def count_col_cmts(cur, target: str) -> tuple[int, int]:
    cur.execute(
        f"SELECT COUNT(*) FROM system.information_schema.columns "
        f"WHERE table_catalog||'.'||table_schema||'.'||table_name = '{target}' "
        f"  AND length(comment) > 0"
    )
    cm = cur.fetchone()[0]
    cur.execute(
        f"SELECT COUNT(*) FROM system.information_schema.columns "
        f"WHERE table_catalog||'.'||table_schema||'.'||table_name = '{target}'"
    )
    tot = cur.fetchone()[0]
    return cm, tot


def main() -> int:
    c = conn()
    cur = c.cursor()
    targets_map = {
        "EXW_Inventory_Snapshot_History.alter.sql": "main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history",
        "EXW_WalletInventory.alter.sql": "main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory",
        "EXW_V_RedeemReconciliation.alter.sql": "main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation",
    }
    for ap in ALTERS:
        target = targets_map[ap.name]
        before_cm, before_tot = count_col_cmts(cur, target)
        print(f"=== {ap.name} ===")
        print(f"  target: {target}")
        print(f"  BEFORE: {before_cm}/{before_tot} cols with comment")
        t0 = time.time()
        ok, fail, fails = run_alter(cur, ap)
        elapsed = time.time() - t0
        after_cm, after_tot = count_col_cmts(cur, target)
        print(f"  ran {ok+fail} stmts ({ok} ok, {fail} fail) in {elapsed:.1f}s")
        if fails:
            print(f"  failures (first 3):")
            for f in fails[:3]:
                print(f"    {f}")
        print(f"  AFTER : {after_cm}/{after_tot} cols with comment")
        print()
    cur.close()
    c.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
