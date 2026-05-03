"""Phase 5 probe: confirm whether the 3 EXW objects suffer the silent-no-op bug.
Strategy:
  1. SHOW CREATE TABLE -> establish real UC object type
  2. Compare against alter file column count vs UC actual columns
  3. Try `COMMENT ON COLUMN` syntax as a probe with a marker
  4. Re-DESCRIBE to see if the comment landed
"""
from __future__ import annotations

import os
from databricks import sql

HOST = "adb-5142916747090026.6.azuredatabricks.net"
HTTP_PATH = "/sql/1.0/warehouses/208214768b0e0308"

TARGETS = [
    "main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_inventory_snapshot_history",
    "main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory",
    "main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation",
]


def conn():
    tok = os.environ.get("DATABRICKS_TOKEN")
    if tok:
        return sql.connect(server_hostname=HOST, http_path=HTTP_PATH, access_token=tok)
    return sql.connect(
        server_hostname=HOST, http_path=HTTP_PATH, auth_type="databricks-oauth"
    )


def main() -> int:
    c = conn()
    cur = c.cursor()
    for tgt in TARGETS:
        print("=" * 100)
        print(f"TARGET: {tgt}")
        print("=" * 100)
        try:
            cur.execute(f"SHOW CREATE TABLE {tgt}")
            row = cur.fetchone()
            ddl = row[0]
            print(f"  DDL line 1: {ddl.splitlines()[0][:140]}")
        except Exception as e:
            print(f"  SHOW CREATE TABLE failed: {str(e)[:140]}")
            continue

        cur.execute(f"DESCRIBE TABLE {tgt}")
        cols = [r[0] for r in cur.fetchall() if r[0] and not r[0].startswith("#")]
        print(f"  Columns: {len(cols)}")
        if not cols:
            continue
        probe_col = cols[0]

        # Probe 1: COMMENT ON COLUMN syntax
        probe = "PROBE_PHASE5_DETECTOR_2026"
        sqlstr = f"COMMENT ON COLUMN {tgt}.`{probe_col}` IS '{probe}'"
        print(f"  PROBE-1 (COMMENT ON COLUMN): {sqlstr[:120]}")
        try:
            cur.execute(sqlstr)
            cur.execute(f"DESCRIBE TABLE {tgt}")
            for r in cur.fetchall():
                if r[0] == probe_col:
                    cm = (r[2] or "")
                    print(f"    after probe, col '{probe_col}' comment: {cm[:80] or '(BLANK)'}")
                    if probe in cm:
                        print(f"    -> COMMENT ON COLUMN works on this object")
                    elif cm == "":
                        print(f"    -> SILENT NO-OP CONFIRMED for COMMENT ON COLUMN")
                    else:
                        print(f"    -> existing comment, probe rejected? cm={cm[:80]}")
                    break
        except Exception as e:
            print(f"    PROBE-1 FAIL: {str(e)[:160]}")

        # Probe 2: ALTER TABLE ... ALTER COLUMN COMMENT
        sqlstr2 = f"ALTER TABLE {tgt} ALTER COLUMN `{probe_col}` COMMENT 'PROBE2_ALTER_COLUMN_2026'"
        print(f"  PROBE-2 (ALTER COLUMN COMMENT): {sqlstr2[:120]}")
        try:
            cur.execute(sqlstr2)
            cur.execute(f"DESCRIBE TABLE {tgt}")
            for r in cur.fetchall():
                if r[0] == probe_col:
                    cm = (r[2] or "")
                    if "PROBE2" in cm:
                        print(f"    -> ALTER COLUMN COMMENT works on this object")
                    elif cm == "":
                        print(f"    -> SILENT NO-OP CONFIRMED for ALTER COLUMN COMMENT")
                    else:
                        print(f"    -> probe2 rejected, cm: {cm[:80]}")
                    break
        except Exception as e:
            print(f"    PROBE-2 FAIL: {str(e)[:160]}")
        print()

    cur.close()
    c.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
