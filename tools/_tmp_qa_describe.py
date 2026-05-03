"""DESCRIBE TABLE EXTENDED for QA samples; print table comment + first 5 column comments."""
from __future__ import annotations

import os
from databricks import sql

TARGETS = [
    ("etoro", "main.general.bronze_etoro_dictionary_funnel"),
    ("etoro", "main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration"),
    ("WalletDB", "main.wallet.bronze_walletdb_wallet_conversiontransactions"),
    ("FiatDwhDB", "main.emoney.bronze_fiatdwhdb_dbo_customereodbalance"),
    ("CalendarDB", "main.general.bronze_calendardb_market_providersexchangedailyschedules"),
    ("UserApiDB", "main.compliance.bronze_userapidb_dictionary_mandatorytype"),
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

    for db, target in TARGETS:
        print()
        print("=" * 100)
        print(f"[{db}]  {target}")
        print("=" * 100)

        try:
            cur.execute(f"DESCRIBE TABLE EXTENDED {target}")
            rows = cur.fetchall()
        except Exception as exc:
            print(f"  ERROR: {exc}")
            continue

        # Collect columns and table-level metadata
        in_extended = False
        cols: list[tuple[str, str, str]] = []  # (col, type, comment)
        table_comment = None
        for r in rows:
            cn, dt, cm = (r[0] or "").strip(), (r[1] or "").strip(), (
                r[2] or ""
            ).strip()
            if cn == "" or cn.startswith("#"):
                if "Detailed Table Information" in cn:
                    in_extended = True
                continue
            if in_extended:
                # In the extended block, col 0 is the metadata key
                if cn.lower() in ("comment", "table comment"):
                    table_comment = dt
                continue
            cols.append((cn, dt, cm))

        print(f"  Columns: {len(cols)}")
        cols_with_comment = [c for c in cols if c[2]]
        print(
            f"  Columns w/ comment: {len(cols_with_comment)}/{len(cols)} "
            f"({100*len(cols_with_comment)//max(1,len(cols))}%)"
        )

        print()
        print(f"  TABLE COMMENT:")
        if table_comment:
            preview = table_comment if len(table_comment) <= 600 else (
                table_comment[:600] + "..."
            )
            for line in preview.splitlines():
                print(f"    {line}")
        else:
            print("    (none)")

        print()
        print(f"  FIRST 5 COLUMN COMMENTS:")
        for cn, dt, cm in cols[:5]:
            cm_short = cm if len(cm) <= 200 else (cm[:200] + "...")
            print(f"    {cn}  [{dt}]")
            if cm:
                print(f"        {cm_short}")
            else:
                print(f"        (none)")

    cur.close()
    conn.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
