"""Phase 3 QA: confirm new comments landed in UC for 1 sample per schema,
plus verify the v_* view comment bug status on v_eMoney_Card_Instance_Summary."""
from __future__ import annotations

import os
from databricks import sql

# 1 pick per schema, drawn from what we just deployed
PICKS = [
    ("EXW_Wallet", "main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_price"),
    ("DWH_dbo", "main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost"),
    ("eMoney_dbo", "main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary"),
    ("Dealing_dbo", "main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients"),
    ("BI_DB_dbo", "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca"),
    ("BI_DB_dbo (large)", "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel"),
]


def main() -> int:
    host = os.environ.get(
        "DATABRICKS_SERVER_HOSTNAME",
        "adb-5142916747090026.6.azuredatabricks.net",
    )
    http_path = os.environ.get(
        "DATABRICKS_HTTP_PATH", "/sql/1.0/warehouses/208214768b0e0308"
    )
    token = os.environ.get("DATABRICKS_TOKEN")

    if token:
        conn = sql.connect(
            server_hostname=host, http_path=http_path, access_token=token
        )
    else:
        conn = sql.connect(
            server_hostname=host, http_path=http_path, auth_type="databricks-oauth"
        )
    cur = conn.cursor()

    for label, target in PICKS:
        print()
        print("=" * 100)
        print(f"[{label}]  {target}")
        print("=" * 100)
        try:
            cur.execute(f"DESCRIBE TABLE EXTENDED {target}")
            rows = cur.fetchall()
        except Exception as exc:
            print(f"  ERROR: {exc}")
            continue

        in_extended = False
        cols: list[tuple[str, str, str]] = []
        table_comment = None
        for r in rows:
            cn = (r[0] or "").strip()
            dt = (r[1] or "").strip()
            cm = (r[2] or "").strip()
            if cn == "" or cn.startswith("#"):
                if "Detailed Table Information" in cn:
                    in_extended = True
                continue
            if in_extended:
                if cn.lower() in ("comment", "table comment"):
                    table_comment = dt
                continue
            cols.append((cn, dt, cm))

        cols_with = [c for c in cols if c[2]]
        pct = 100 * len(cols_with) // max(1, len(cols))
        print(f"  Columns: {len(cols)} | with comment: {len(cols_with)} ({pct}%)")

        print(f"  TABLE COMMENT: {(table_comment or '(none)')[:200]}")

        print(f"  FIRST 3 COL COMMENTS:")
        for cn, dt, cm in cols[:3]:
            cm_short = (cm[:160] + "...") if len(cm) > 160 else cm
            print(f"    {cn} [{dt}]")
            print(f"        {cm_short or '(none)'}")

    cur.close()
    conn.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
