"""
Load the Lakebridge profiler DuckDB extract into Delta tables under
`dwh_daily_process.lakebridge_profiler.<table>`.

This is the missing step in lakebridge v0.12.2 (create-profiler-dashboard only
uploads the raw .db file to the volume but never materializes Delta tables that
the dashboard JSON expects).

Strategy: DuckDB -> local Parquet -> UC Volume -> CTAS over read_files().
"""

from __future__ import annotations

import argparse
import os
import sys
import tempfile
from pathlib import Path

import duckdb
from databricks.sdk import WorkspaceClient


CATALOG = "dwh_daily_process"
SCHEMA = "lakebridge_profiler"
VOLUME_DIR = f"/Volumes/{CATALOG}/{SCHEMA}/extracts/parquet"
DEFAULT_EXTRACT = (
    Path.home()
    / ".databricks"
    / "labs"
    / "lakebridge_profilers"
    / "synapse_assessment"
    / "profiler_extract.db"
)


def list_tables(con: duckdb.DuckDBPyConnection) -> list[str]:
    rows = con.execute(
        "SELECT table_name FROM information_schema.tables "
        "WHERE table_schema='main' ORDER BY table_name"
    ).fetchall()
    return [r[0] for r in rows]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--extract-file", default=str(DEFAULT_EXTRACT))
    ap.add_argument("--profile", default="name-of-profile")
    ap.add_argument("--warehouse-id", default=None,
                    help="DBSQL warehouse id; auto-detect first running if omitted")
    args = ap.parse_args()

    extract = Path(args.extract_file)
    if not extract.exists():
        print(f"ERROR: extract file not found: {extract}", file=sys.stderr)
        return 1

    print(f"[duckdb] opening {extract}")
    con = duckdb.connect(str(extract), read_only=True)
    tables = list_tables(con)
    print(f"[duckdb] {len(tables)} tables to load")

    w = WorkspaceClient(profile=args.profile)
    warehouse_id = args.warehouse_id
    if not warehouse_id:
        for wh in w.warehouses.list():
            if wh.state and wh.state.value == "RUNNING":
                warehouse_id = wh.id
                print(f"[wh] using running warehouse: {wh.name} ({wh.id})")
                break
        if not warehouse_id:
            for wh in w.warehouses.list():
                warehouse_id = wh.id
                print(f"[wh] no running warehouse; using first: {wh.name} ({wh.id})")
                break
    if not warehouse_id:
        print("ERROR: no SQL warehouse available", file=sys.stderr)
        return 2

    failures: list[tuple[str, str]] = []
    with tempfile.TemporaryDirectory() as tmpdir:
        for i, t in enumerate(tables, 1):
            print(f"\n[{i}/{len(tables)}] {t}")
            local_parquet = Path(tmpdir) / f"{t}.parquet"
            con.execute(f"COPY (SELECT * FROM \"main\".\"{t}\") TO '{local_parquet.as_posix()}' (FORMAT PARQUET)")
            size_mb = local_parquet.stat().st_size / 1024 / 1024
            print(f"  parquet: {size_mb:.2f} MB")

            volume_path = f"{VOLUME_DIR}/{t}.parquet"
            with open(local_parquet, "rb") as f:
                w.files.upload(volume_path, f, overwrite=True)
            print(f"  uploaded -> {volume_path}")

            fqdn = f"`{CATALOG}`.`{SCHEMA}`.`{t}`"
            ctas = (
                f"CREATE OR REPLACE TABLE {fqdn} AS "
                f"SELECT * FROM read_files('{volume_path}', format => 'parquet')"
            )
            try:
                resp = w.statement_execution.execute_statement(
                    warehouse_id=warehouse_id,
                    statement=ctas,
                    wait_timeout="50s",
                )
                if resp.status and resp.status.state and resp.status.state.value not in ("SUCCEEDED",):
                    err = resp.status.error.message if resp.status.error else str(resp.status)
                    failures.append((t, err))
                    print(f"  CTAS FAILED: {err}")
                else:
                    n = w.statement_execution.execute_statement(
                        warehouse_id=warehouse_id,
                        statement=f"SELECT COUNT(*) FROM {fqdn}",
                        wait_timeout="50s",
                    )
                    cnt = n.result.data_array[0][0] if n.result and n.result.data_array else "?"
                    print(f"  CTAS ok, rows={cnt}")
            except Exception as e:  # noqa: BLE001
                failures.append((t, str(e)))
                print(f"  CTAS EXCEPTION: {e}")

    print("\n" + "=" * 60)
    print(f"Done. {len(tables) - len(failures)}/{len(tables)} tables loaded.")
    if failures:
        print("\nFailures:")
        for t, err in failures:
            print(f"  - {t}: {err[:200]}")
        return 3
    return 0


if __name__ == "__main__":
    sys.exit(main())
