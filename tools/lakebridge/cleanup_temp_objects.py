"""Defensive sweep: drop any residual TEMP_TABLE_* views or managed
tables left in dwh_daily_process.migration_tables from crashed or
interrupted SP runs.

The per-SP cleanup block (added by `fix_inject_temp_cleanup`) handles
the happy path: each SP drops its TEMP_TABLE_* objects before returning.
If an SP throws partway through, residue can persist. Run this script
periodically (or before bulk SP test runs) to keep the schema clean.

Usage:
    python cleanup_temp_objects.py            # report + drop
    python cleanup_temp_objects.py --dry-run  # report only
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys

from databricks import sql as dbsql


CATALOG = "dwh_daily_process"
SCHEMA = "migration_tables"
SERVER_HOSTNAME = "adb-5142916747090026.6.azuredatabricks.net"
HTTP_PATH = "/sql/1.0/warehouses/208214768b0e0308"


def fetch_token(profile: str) -> str:
    res = subprocess.run(
        ["databricks", "auth", "token", "--profile", profile, "-o", "json"],
        capture_output=True, text=True, check=True, shell=True,
    )
    return json.loads(res.stdout)["access_token"]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true",
                    help="Report orphans but don't drop them")
    args = ap.parse_args()

    token = None
    for prof in ("name-of-profile", "guyman", "DEFAULT"):
        try:
            token = fetch_token(prof)
            print(f"Auth: using profile '{prof}'")
            break
        except Exception:
            continue
    if not token:
        print("ERROR: no working Databricks profile.", file=sys.stderr)
        return 2

    conn = dbsql.connect(
        server_hostname=SERVER_HOSTNAME,
        http_path=HTTP_PATH,
        access_token=token,
    )
    cur = conn.cursor()

    cur.execute(
        f"SELECT table_name, table_type "
        f"FROM {CATALOG}.information_schema.tables "
        f"WHERE table_schema='{SCHEMA}' "
        f"  AND (table_name ILIKE 'TEMP_TABLE_%' "
        f"       OR table_name LIKE '#%') "
        f"ORDER BY table_name"
    )
    rows = cur.fetchall()
    print(f"Found {len(rows)} orphan temp objects "
          f"in {CATALOG}.{SCHEMA}")

    n_dropped = 0
    for name, ttype in rows:
        kind = "VIEW" if ttype == "VIEW" else "TABLE"
        fq = f"`{CATALOG}`.`{SCHEMA}`.`{name}`"
        if args.dry_run:
            print(f"  [DRY] would DROP {kind} {fq}")
            continue
        try:
            cur.execute(f"DROP {kind} IF EXISTS {fq}")
            n_dropped += 1
            print(f"  DROPPED {kind} {name}")
        except Exception as exc:
            print(f"  FAILED  {kind} {name}: "
                  f"{str(exc).splitlines()[0][:120]}")

    if not args.dry_run:
        print(f"\nDone. Dropped {n_dropped}/{len(rows)} orphans.")
    cur.close()
    conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
