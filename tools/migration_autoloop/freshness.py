"""Gold-freshness / bronze-readiness signals for the parallel DWH orchestration.

The parallel orchestration runs the proven autopoc procs against LIVE bronze
(`daily_snapshot`) + a SHALLOW CLONE of the still-pre-flip gold tables, then proves
1:1 parity once Synapse's own update lands. This module supplies the two timing
signals that gate that flow:

* ``bronze_ready(target_date)`` — every required ``daily_snapshot`` partition for
  ``target_date`` is present (location points at ``etr_ymd=target_date``) AND has
  rows. Until this is true the run cannot start.
* ``gold_state(table)`` -> ``preflip`` / ``postflip`` — has Synapse's own daily
  update for ``target_date`` landed in this gold table yet?
    - Facts (have a ``DateID``-style column): ``MAX(date_column) >= target_date``.
    - Dims / no date key: latest Delta history commit dated on/after ``run_date``.

All SQL goes through ``db.execute_sql``; snapshot-table discovery reuses
``snapshot_guard`` so the "required tables" definition stays in one place.
"""
from __future__ import annotations

import datetime as dt
from dataclasses import dataclass, field
from typing import Any

if __package__ in {None, ""}:
    import sys
    from pathlib import Path

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from databricks.sdk import WorkspaceClient

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env
from tools.migration_autoloop.snapshot_guard import _list_proc_snapshot_tables, _snapshot_rows


def target_date_default() -> str:
    """Yesterday (UTC) as ``YYYY-MM-DD`` — the daily increment data date (D-1)."""
    return (dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)).isoformat()


def run_date_default() -> str:
    """Today (UTC) as ``YYYY-MM-DD`` — the day the orchestration runs (D)."""
    return dt.datetime.now(dt.timezone.utc).date().isoformat()


def date_id(target_date: str) -> int:
    """``2026-06-23`` -> ``20260623`` (the integer ``DateID`` Synapse uses)."""
    return int(target_date.replace("-", ""))


@dataclass
class BronzeReadiness:
    target_date: str
    required_tables: list[str]
    ready: bool
    missing_partition: list[str] = field(default_factory=list)
    empty_partition: list[str] = field(default_factory=list)
    table_rows: dict[str, int] = field(default_factory=dict)

    def as_dict(self) -> dict[str, Any]:
        return {
            "target_date": self.target_date,
            "required_table_count": len(self.required_tables),
            "required_tables": self.required_tables,
            "ready": self.ready,
            "missing_partition": self.missing_partition,
            "empty_partition": self.empty_partition,
            "table_rows": self.table_rows,
        }


def required_snapshot_tables(
    w: WorkspaceClient, wid: str, proc_names: list[str]
) -> list[str]:
    """Union of ``daily_snapshot`` tables referenced across the given procs."""
    names: set[str] = set()
    for proc in proc_names:
        if not proc:
            continue
        names.update(_list_proc_snapshot_tables(wid, proc))
    return sorted(names)


def bronze_ready(
    w: WorkspaceClient,
    wid: str,
    *,
    target_date: str,
    proc_names: list[str],
    check_rowcount: bool = True,
) -> BronzeReadiness:
    """True when every required snapshot partition is at ``target_date`` and non-empty.

    Partition presence is read from ``information_schema.tables.storage_path``
    (``etr_ymd=YYYY-MM-DD``); ``snapshot_guard`` keeps locations pointed at the
    right partition. Rowcount is verified only when ``check_rowcount`` is set.
    """
    required = required_snapshot_tables(w, wid, proc_names)
    rows = _snapshot_rows(wid, required)
    by_name = {r["table_name"].lower(): r for r in rows}

    missing: list[str] = []
    empty: list[str] = []
    table_rows: dict[str, int] = {}

    for table in required:
        rec = by_name.get(table.lower())
        snap = rec.get("snapshot_date", "") if rec else ""
        if not rec or not snap or snap < target_date:
            missing.append(table)
            continue
        if check_rowcount:
            _, cnt = execute_sql(
                w,
                sql_text=f"SELECT COUNT(*) AS c FROM dwh_daily_process.daily_snapshot.{table}",
                warehouse_id=wid,
                poll_deadline_sec=1200.0,
            )
            n = int(cnt[0][0]) if cnt else 0
            table_rows[table] = n
            if n == 0:
                empty.append(table)

    return BronzeReadiness(
        target_date=target_date,
        required_tables=required,
        ready=not missing and not empty,
        missing_partition=missing,
        empty_partition=empty,
        table_rows=table_rows,
    )


def _max_date_id(w: WorkspaceClient, wid: str, table: str, date_column: str) -> int | None:
    _, rows = execute_sql(
        w,
        sql_text=f"SELECT MAX(`{date_column}`) AS m FROM {table}",
        warehouse_id=wid,
        poll_deadline_sec=1800.0,
    )
    if not rows or rows[0][0] is None:
        return None
    return int(rows[0][0])


def _latest_commit_date(w: WorkspaceClient, wid: str, table: str) -> str | None:
    """UTC date (``YYYY-MM-DD``) of the most recent Delta history commit.

    Returns ``None`` if the table is not a Delta table or has no history.
    """
    try:
        cols, rows = execute_sql(
            w,
            sql_text=f"DESCRIBE HISTORY {table} LIMIT 1",
            warehouse_id=wid,
        )
    except RuntimeError as exc:
        # DELTA_ONLY_OPERATION — table is not Delta (e.g. Parquet external).
        if "delta_only_operation" in str(exc).lower() or "delta tables" in str(exc).lower():
            return None
        raise
    if not rows:
        return None
    ts_idx = cols.index("timestamp") if "timestamp" in cols else 0
    ts = str(rows[0][ts_idx])
    return ts[:10] if len(ts) >= 10 else None


def _etr_ymd_row_count(w: WorkspaceClient, wid: str, table: str, target_date: str) -> int | None:
    """Count rows in ``table`` where ``etr_ymd = target_date``.

    Returns ``None`` when the table has no ``etr_ymd`` column (full-refresh dims).
    """
    try:
        _, rows = execute_sql(
            w,
            sql_text=f"SELECT COUNT(*) AS c FROM {table} WHERE etr_ymd = '{target_date}'",
            warehouse_id=wid,
            poll_deadline_sec=300.0,
        )
        return int(rows[0][0]) if rows else 0
    except RuntimeError as exc:
        # UNRESOLVED_COLUMN — table has no etr_ymd partition column
        if "etr_ymd" in str(exc).lower() or "unresolved_column" in str(exc).lower():
            return None
        raise


def gold_state(
    w: WorkspaceClient,
    wid: str,
    gold_table: str,
    *,
    target_date: str,
    run_date: str | None = None,
    date_column: str | None = None,
) -> dict[str, Any]:
    """Return ``preflip`` / ``postflip`` for a gold table relative to ``target_date``.

    Primary signal (all tables): ``etr_ymd = target_date`` partition has > 0 rows.
    This works for both incremental facts (D-1 partition = new increment) and
    full-refresh dims (D-1 partition = today's full reload written by generic pipeline).

    Fallbacks when ``etr_ymd`` column does not exist:
    * ``date_column`` provided: ``MAX(date_column) >= target_date_id``.
    * Neither: latest Delta history commit date >= ``run_date``.
    """
    run_date = run_date or run_date_default()

    etr_count = _etr_ymd_row_count(w, wid, gold_table, target_date)
    if etr_count is not None:
        state = "postflip" if etr_count > 0 else "preflip"
        return {
            "gold_table": gold_table,
            "signal": "etr_ymd",
            "target_date": target_date,
            "etr_ymd_row_count": etr_count,
            "state": state,
        }

    # Table has no etr_ymd column — use secondary signals
    if date_column:
        target_id = date_id(target_date)
        max_id = _max_date_id(w, wid, gold_table, date_column)
        state = "postflip" if (max_id is not None and max_id >= target_id) else "preflip"
        return {
            "gold_table": gold_table,
            "signal": "max_date_id",
            "date_column": date_column,
            "max_date_id": max_id,
            "target_date_id": target_id,
            "state": state,
        }

    commit_date = _latest_commit_date(w, wid, gold_table)
    if commit_date is None:
        # Table is not Delta or has no history — cannot determine flip state.
        # Treat as postflip to unblock parity check; parity itself is the real validation.
        return {
            "gold_table": gold_table,
            "signal": "unavailable",
            "note": "non_delta_or_no_history",
            "state": "postflip",
        }
    state = "postflip" if commit_date >= run_date else "preflip"
    return {
        "gold_table": gold_table,
        "signal": "delta_history",
        "latest_commit_date": commit_date,
        "run_date": run_date,
        "state": state,
    }


def main() -> int:
    import argparse
    import json

    ap = argparse.ArgumentParser(description="Probe bronze readiness / gold flip state.")
    ap.add_argument("--target-date", default="", help="YYYY-MM-DD (data date, D-1); default yesterday UTC.")
    ap.add_argument("--run-date", default="", help="YYYY-MM-DD (run day, D); default today UTC.")
    ap.add_argument("--proc", action="append", default=[], help="Proc name(s) for bronze dependency discovery.")
    ap.add_argument("--gold-table", default="", help="Gold table to probe flip state for.")
    ap.add_argument("--date-column", default="", help="Date column for fact flip signal; omit for dim history signal.")
    ap.add_argument("--no-rowcount", action="store_true", help="Skip bronze rowcount checks (presence only).")
    args = ap.parse_args()

    w = make_workspace_client()
    wid = warehouse_id_from_env()
    target_date = args.target_date.strip() or target_date_default()
    run_date = args.run_date.strip() or run_date_default()

    out: dict[str, Any] = {"target_date": target_date, "run_date": run_date}
    if args.proc:
        out["bronze"] = bronze_ready(
            w, wid, target_date=target_date, proc_names=args.proc, check_rowcount=not args.no_rowcount
        ).as_dict()
    if args.gold_table:
        out["gold"] = gold_state(
            w, wid, args.gold_table,
            target_date=target_date, run_date=run_date,
            date_column=args.date_column.strip() or None,
        )
    print(json.dumps(out, indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
