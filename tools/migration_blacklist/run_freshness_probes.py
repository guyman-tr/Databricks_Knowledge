"""Run all freshness probes in tools/migration_blacklist via pyodbc.

Reads each .sql file in audits/blacklist/_a3_work/probes/ that begins with
'probe_', executes against PROD Synapse, and writes the (schema, table,
max_update) rows to audits/blacklist/_a3_work/freshness_results.csv.

Failed chunks are logged and retried as single-table queries so a single
missing UpdateDate column does not poison the whole batch.

Run:
    python tools\\migration_blacklist\\run_freshness_probes.py
"""

from __future__ import annotations

import csv
import os
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(line_buffering=True)

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

import synapse_connect as sc  # noqa: E402
from synapse_connect import run_query  # noqa: E402

# Force PROD endpoints. synapse_connect._conn_str (AAD path) ignores env vars
# and uses module-level SERVER/DATABASE constants, so we patch those directly.
sc.SERVER = "prod-synapse-dataplatform-we.sql.azuresynapse.net"
sc.DATABASE = "sql_dp_prod_we"


PROBES_DIR = REPO_ROOT / "audits" / "blacklist" / "_a3_work" / "probes"
OUT_CSV    = REPO_ROOT / "audits" / "blacklist" / "_a3_work" / "freshness_results.csv"
ERR_LOG    = REPO_ROOT / "audits" / "blacklist" / "_a3_work" / "freshness_errors.log"


def split_into_singles(sql: str) -> list[tuple[str, str, str]]:
    """Parse a UNION ALL probe back into (schema, table, single_select)."""
    pat = re.compile(
        r"SELECT\s+'([^']+)'\s+AS\s+schema_name,\s*"
        r"'([^']+)'\s+AS\s+table_name,\s*"
        r"CONVERT\([^)]*\)\s+AS\s+max_update\s+FROM\s+\[([^\]]+)\]\.\[([^\]]+)\]",
        re.IGNORECASE,
    )
    out: list[tuple[str, str, str]] = []
    for m in pat.finditer(sql):
        s = m.group(1)
        t = m.group(2)
        single = (
            "SELECT '" + s + "' AS schema_name, "
            "'" + t.replace("'", "''") + "' AS table_name, "
            "CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update "
            "FROM [" + s + "].[" + t + "]"
        )
        out.append((s, t, single))
    return out


def main() -> int:
    if not PROBES_DIR.exists():
        print(f"[freshness] missing probes dir: {PROBES_DIR}", flush=True)
        return 2

    probe_files = sorted(p for p in PROBES_DIR.glob("probe_*.sql"))
    print(f"[freshness] found {len(probe_files)} probe chunks", flush=True)

    print("[freshness] connecting to PROD synapse ...", flush=True)
    conn = sc.connect()
    print("[freshness] connected", flush=True)

    rows_out: list[tuple[str, str, str]] = []
    err_lines: list[str] = []

    total = len(probe_files)
    for i, pf in enumerate(probe_files, 1):
        sql = pf.read_text(encoding="utf-8-sig")  # strips BOM if present
        try:
            cols, rows = run_query(conn, sql)
            for r in rows:
                schema = r[0]
                table  = r[1]
                mx     = r[2] if r[2] is not None else ""
                rows_out.append((schema, table, mx))
            print(f"[freshness] [{i:3d}/{total}] OK  {pf.name}  rows={len(rows)}", flush=True)
        except Exception as e:
            msg = str(e).splitlines()[0][:200]
            print(f"[freshness] [{i:3d}/{total}] FAIL {pf.name} -> {msg}", flush=True)
            err_lines.append(f"{pf.name}: {msg}")
            # Retry as single-table queries.
            singles = split_into_singles(sql)
            for s, t, single_sql in singles:
                try:
                    cols, rows = run_query(conn, single_sql)
                    for r in rows:
                        rows_out.append((r[0], r[1], r[2] if r[2] is not None else ""))
                    print(f"        retry OK  {s}.{t}", flush=True)
                except Exception as e2:
                    msg2 = str(e2).splitlines()[0][:200]
                    print(f"        retry FAIL {s}.{t} -> {msg2}", flush=True)
                    err_lines.append(f"  {s}.{t}: {msg2}")

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["schema", "table_name", "max_update"])
        for r in rows_out:
            w.writerow(r)

    if err_lines:
        ERR_LOG.write_text("\n".join(err_lines), encoding="utf-8")
    elif ERR_LOG.exists():
        ERR_LOG.unlink()

    print(f"[freshness] wrote {len(rows_out)} rows -> {OUT_CSV}", flush=True)
    print(f"[freshness] errors: {len(err_lines)}  log: {ERR_LOG if err_lines else '(none)'}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
