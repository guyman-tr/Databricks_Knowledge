"""Count deployed SPs in dwh_daily_process.migration_tables."""

from __future__ import annotations

import fix_and_deploy_sp_dim_customer as base
from databricks import sql as dbsql


def main() -> None:
    token = None
    for prof in ("name-of-profile", "guyman", "DEFAULT"):
        try:
            token = base.fetch_token(prof)
            print(f"Using profile '{prof}'")
            break
        except Exception:
            continue
    if not token:
        raise SystemExit("No working profile.")
    conn = dbsql.connect(
        server_hostname="adb-5142916747090026.6.azuredatabricks.net",
        http_path="/sql/1.0/warehouses/208214768b0e0308",
        access_token=token,
    )
    cur = conn.cursor()
    cur.execute(
        "SELECT routine_name FROM system.information_schema.routines "
        "WHERE routine_catalog='dwh_daily_process' "
        "AND routine_schema='migration_tables' "
        "AND routine_type='PROCEDURE' "
        "ORDER BY routine_name"
    )
    rows = cur.fetchall()
    print(f"Total SPs deployed in dwh_daily_process.migration_tables: {len(rows)}")
    print()
    print("Procedures (lowercase, sorted):")
    for r in rows:
        print(f"  {r[0]}")


if __name__ == "__main__":
    main()
