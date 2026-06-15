"""Deploy the manually-rewritten stored procedures that BladeBridge
couldn't produce viable output for. Each .sql file under
`manual_rewrites/` is a stand-alone `CREATE OR REPLACE PROCEDURE`
statement ready for execution against dwh_daily_process.migration_tables.

Usage:
    python deploy_manual_rewrites.py                  # deploy all
    python deploy_manual_rewrites.py --filter futures # deploy matching
    python deploy_manual_rewrites.py --dry-run        # parse only
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
from pathlib import Path

from databricks import sql as dbsql


REWRITES_DIR = Path(__file__).parent / "manual_rewrites"
SERVER = "adb-5142916747090026.6.azuredatabricks.net"
HTTP_PATH = "/sql/1.0/warehouses/208214768b0e0308"


def fetch_token(profile: str) -> str:
    res = subprocess.run(
        ["databricks", "auth", "token", "--profile", profile, "-o", "json"],
        capture_output=True, text=True, check=True, shell=True,
    )
    return json.loads(res.stdout)["access_token"]


def strip_leading_comments(text: str) -> str:
    """Drop any leading `--` line comments and blank lines so the body
    that we hand to cur.execute starts at the CREATE keyword."""
    lines = text.splitlines()
    keep_start = 0
    for i, ln in enumerate(lines):
        s = ln.strip()
        if not s or s.startswith("--"):
            continue
        keep_start = i
        break
    return "\n".join(lines[keep_start:]).strip().rstrip(";").strip()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--filter", default="",
                    help="Only process files whose name contains this substring")
    args = ap.parse_args()

    files = sorted(REWRITES_DIR.glob("*.sql"))
    if args.filter:
        files = [f for f in files if args.filter.lower() in f.name.lower()]
    print(f"Found {len(files)} manual rewrite files")
    if not files:
        return 0

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
        server_hostname=SERVER, http_path=HTTP_PATH, access_token=token,
    )
    cur = conn.cursor()
    cur.execute("USE CATALOG dwh_daily_process")
    cur.execute("USE SCHEMA migration_tables")

    n_ok = n_fail = 0
    for i, fp in enumerate(files, start=1):
        raw = fp.read_text(encoding="utf-8-sig", errors="replace")
        body = strip_leading_comments(raw)

        if args.dry_run:
            print(f"[{i:2d}/{len(files)}] DRY    {fp.name}")
            continue

        t0 = time.time()
        try:
            cur.execute(body)
            elapsed = int((time.time() - t0) * 1000)
            n_ok += 1
            print(f"[{i:2d}/{len(files)}] OK    {elapsed:>5d}ms  {fp.name}")
        except Exception as exc:
            elapsed = int((time.time() - t0) * 1000)
            err_short = str(exc).split("SQLSTATE")[0][:250].replace("\n", " ").strip()
            n_fail += 1
            print(f"[{i:2d}/{len(files)}] FAIL  {elapsed:>5d}ms  {fp.name}")
            print(f"             ^-- {err_short}")

    print(f"\n=== Done. OK={n_ok}  FAIL={n_fail}  TOTAL={len(files)} ===")
    cur.close()
    conn.close()
    return 0 if n_fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
