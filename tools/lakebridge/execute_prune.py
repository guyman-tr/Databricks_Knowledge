"""
execute_prune.py

Reads tools/lakebridge/audit/PRUNE_CHECKLIST.md, extracts every line of the
form `- [x] \`<table_name>\`` (ticked entries), looks up each object's type
in Unity Catalog, and issues the appropriate `DROP TABLE IF EXISTS` or
`DROP VIEW IF EXISTS` against `dwh_daily_process.migration_tables`.

A safety pass first verifies every ticked target is empty (0 rows). If any
ticked table has rows the script refuses to drop it (flagged for manual
inspection).

Output: tools/lakebridge/audit/PRUNE_RESULT.md
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
import time
from pathlib import Path


ROOT = Path(__file__).parent
CHECKLIST = ROOT / "audit" / "PRUNE_CHECKLIST.md"
RESULT = ROOT / "audit" / "PRUNE_RESULT.md"


TICKED_RE = re.compile(r"^\s*-\s*\[x\]\s+`([^`]+)`", re.IGNORECASE)


def parse_ticked() -> list[str]:
    """Return ordered list of lower-cased table names ticked in the checklist."""
    out: list[str] = []
    seen: set[str] = set()
    for line in CHECKLIST.read_text(encoding="utf-8").splitlines():
        m = TICKED_RE.match(line)
        if not m:
            continue
        name = m.group(1).strip().lower()
        if name and name not in seen:
            out.append(name)
            seen.add(name)
    return out


def fetch_token(profile: str) -> str:
    res = subprocess.run(
        ["databricks", "auth", "token", "--profile", profile, "-o", "json"],
        capture_output=True, text=True, check=True, shell=True,
    )
    return json.loads(res.stdout)["access_token"]


def main(dry_run: bool = False) -> int:
    targets = parse_ticked()
    print(f"Ticked entries in checklist: {len(targets)}")
    if not targets:
        print("Nothing to do.")
        return 0

    token = fetch_token("name-of-profile")
    from databricks import sql as dbsql
    conn = dbsql.connect(
        server_hostname="adb-5142916747090026.6.azuredatabricks.net",
        http_path="/sql/1.0/warehouses/208214768b0e0308",
        access_token=token,
    )
    cur = conn.cursor()

    # ---- 1) classify each target as TABLE / VIEW / MISSING -----------------
    placeholders = ",".join(["?"] * len(targets))
    cur.execute(
        f"SELECT lower(table_name), table_type "
        f"FROM system.information_schema.tables "
        f"WHERE table_catalog='dwh_daily_process' "
        f"AND table_schema='migration_tables' "
        f"AND lower(table_name) IN ({placeholders})",
        targets,
    )
    types: dict[str, str] = {r[0]: r[1] for r in cur.fetchall()}
    missing = [t for t in targets if t not in types]
    print(f"  classified: {len(types)} found, {len(missing)} missing")

    # ---- 2) safety pass: each MANAGED target must be empty ----------------
    nonempty: dict[str, int] = {}
    print("Safety pass (verify each ticked table is empty)...")
    for i, t in enumerate(targets):
        if t not in types or types[t] != "MANAGED":
            continue
        cur.execute(
            f"SELECT COUNT(*) FROM dwh_daily_process.migration_tables.`{t}`"
        )
        n = int(cur.fetchone()[0])
        if n > 0:
            nonempty[t] = n
        if (i + 1) % 25 == 0:
            print(f"  {i+1}/{len(targets)} checked...")
    if nonempty:
        print(f"\nABORT: {len(nonempty)} ticked tables are NOT empty:")
        for t, n in nonempty.items():
            print(f"  {t}: {n} rows")
        print("Investigate before dropping.")
        cur.close()
        conn.close()
        return 2

    print(f"Safety pass OK: every ticked target is empty (or a view).")

    # ---- 3) execute drops --------------------------------------------------
    results: list[tuple[str, str, str, int, str]] = []  # name, type, action, elapsed_ms, error
    drop_action = "DRY-RUN" if dry_run else "DROP"
    print(f"\n{drop_action}ing {len(targets)} objects...")
    for i, t in enumerate(targets, 1):
        ttype = types.get(t, "MISSING")
        stmt = ""
        if ttype == "VIEW":
            stmt = f"DROP VIEW IF EXISTS dwh_daily_process.migration_tables.`{t}`"
        elif ttype == "MANAGED":
            stmt = f"DROP TABLE IF EXISTS dwh_daily_process.migration_tables.`{t}`"
        else:
            results.append((t, ttype, "SKIPPED-missing", 0, ""))
            continue
        if dry_run:
            results.append((t, ttype, f"WOULD: {stmt}", 0, ""))
            continue
        t0 = time.time()
        try:
            cur.execute(stmt)
            elapsed = int((time.time() - t0) * 1000)
            results.append((t, ttype, "DROPPED", elapsed, ""))
            if i % 10 == 0:
                print(f"  {i}/{len(targets)} dropped...")
        except Exception as exc:
            elapsed = int((time.time() - t0) * 1000)
            results.append((t, ttype, "FAILED", elapsed, str(exc)[:240]))

    cur.close()
    conn.close()

    # ---- 4) write result report -------------------------------------------
    drops = [r for r in results if r[2] == "DROPPED"]
    fails = [r for r in results if r[2] == "FAILED"]
    skips = [r for r in results if r[2].startswith("SKIPPED")]
    wouldbe = [r for r in results if r[2].startswith("WOULD")]

    with RESULT.open("w", encoding="utf-8") as fh:
        fh.write(f"# Prune execution result\n\n")
        fh.write(f"- Targets ticked: **{len(targets)}**\n")
        if dry_run:
            fh.write(f"- Mode: **DRY RUN** (no DROP issued)\n")
        else:
            fh.write(f"- Dropped: **{len(drops)}**\n")
            fh.write(f"- Failed: **{len(fails)}**\n")
        fh.write(f"- Skipped (missing): {len(skips)}\n\n")

        if fails:
            fh.write(f"## Failures ({len(fails)})\n\n")
            fh.write("| table | error |\n|---|---|\n")
            for n, _t, _a, _e, err in fails:
                fh.write(f"| `{n}` | {err} |\n")
            fh.write("\n")

        if drops:
            fh.write(f"## Dropped ({len(drops)})\n\n")
            fh.write("| # | table | type | elapsed_ms |\n|---:|---|---|---:|\n")
            for i, (n, ttype, _a, ms, _e) in enumerate(drops, 1):
                fh.write(f"| {i} | `{n}` | {ttype} | {ms} |\n")

        if wouldbe:
            fh.write(f"## Would drop ({len(wouldbe)})\n\n")
            fh.write("| # | table | type | statement |\n|---:|---|---|---|\n")
            for i, (n, ttype, action, _ms, _e) in enumerate(wouldbe, 1):
                fh.write(f"| {i} | `{n}` | {ttype} | `{action[6:]}` |\n")

        if skips:
            fh.write(f"## Skipped (missing in lake) ({len(skips)})\n\n")
            for n, _t, _a, _e, _err in skips:
                fh.write(f"- `{n}`\n")

    print(f"\nReport written: {RESULT}")
    print(f"Drops: {len(drops)}  Failures: {len(fails)}  Skipped: {len(skips)}")
    return 0 if not fails else 3


if __name__ == "__main__":
    dry = "--dry-run" in sys.argv
    sys.exit(main(dry_run=dry))
