#!/usr/bin/env python3
"""Run one migration proc and evaluate parity across mapped output tables."""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env
from tools.migration_autoloop.run_flow_autoloop_report import (
    _aggregates,
    _bool_pass,
    _date_filter,
    _metric_columns,
    _metric_deltas,
    _query_table_columns,
)


def _target_date(value: str) -> dt.date:
    if value.strip():
        return dt.date.fromisoformat(value.strip())
    return dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)


def _proc_body(proc_name: str) -> str:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    q = (
        "SELECT routine_definition "
        "FROM system.information_schema.routines "
        "WHERE routine_catalog='dwh_daily_process' "
        "AND routine_schema='migration_tables' "
        f"AND routine_name='{proc_name}'"
    )
    _, rows = execute_sql(w, sql_text=q, warehouse_id=wid, poll_deadline_sec=1200.0)
    return str(rows[0][0] or "") if rows else ""


def _mapped_tables(proc_name: str) -> list[tuple[str, str]]:
    body = _proc_body(proc_name)
    refs = sorted(
        {
            f"dwh_daily_process.migration_tables.{t.lower()}"
            for t in re.findall(
                r"dwh_daily_process\.migration_tables\.([A-Za-z0-9_]+)",
                body,
                flags=re.IGNORECASE,
            )
        }
    )
    if not refs:
        return []
    in_clause = ", ".join(f"'{x}'" for x in refs)
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    q = (
        "SELECT migration_table_name, gold_table_name "
        "FROM dwh_daily_process.qa.gold_phase_table_mapping "
        f"WHERE lower(migration_table_name) IN ({in_clause}) "
        "AND is_active = 1 "
        "ORDER BY migration_table_name"
    )
    cols, rows = execute_sql(w, sql_text=q, warehouse_id=wid)
    idx = {c: i for i, c in enumerate(cols)}
    return [(str(r[idx["migration_table_name"]]), str(r[idx["gold_table_name"]])) for r in rows]


def _call_proc(proc_name: str, target_date: dt.date, has_date_param: bool) -> None:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    if has_date_param:
        sql = (
            f"CALL dwh_daily_process.migration_tables.{proc_name}("
            f"CAST('{target_date.isoformat()}' AS TIMESTAMP)"
            ")"
        )
    else:
        sql = f"CALL dwh_daily_process.migration_tables.{proc_name}()"
    execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=3600.0)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--proc-name", required=True)
    ap.add_argument("--has-date-param", action="store_true")
    ap.add_argument("--target-date", default="")
    ap.add_argument("--out-json", default="")
    args = ap.parse_args()

    proc_name = args.proc_name.strip().lower()
    target_date = _target_date(args.target_date)
    out_json = (
        Path(args.out_json)
        if args.out_json.strip()
        else Path(f"tools/migration_autoloop/out/{proc_name}_parity_{target_date.isoformat()}.json")
    )

    mapped = _mapped_tables(proc_name)
    _call_proc(proc_name, target_date, args.has_date_param)

    rows = []
    for migration_table, gold_table in mapped:
        try:
            mig_cols = _query_table_columns(migration_table)
            gold_cols = _query_table_columns(gold_table)
            if args.has_date_param:
                where_mig, where_col = _date_filter(mig_cols, target_date, dialect="dbx")
                where_gold, _ = _date_filter(gold_cols, target_date, preferred_column=where_col, dialect="dbx")
            else:
                where_mig, where_gold = "1=1", "1=1"
            metrics = [m for m in _metric_columns(mig_cols) if m in {str(c["column_name"]) for c in gold_cols}][:3]
            post = _aggregates(migration_table, where_mig, metrics)
            gold = _aggregates(gold_table, where_gold, metrics)
            delta = _metric_deltas(post, gold, metrics)
            rows.append(
                {
                    "migration_table": migration_table,
                    "gold_table": gold_table,
                    "where_migration": where_mig,
                    "where_gold": where_gold,
                    "metrics": metrics,
                    "post": post,
                    "gold": gold,
                    "delta": delta,
                    "pass": _bool_pass(delta, metrics),
                }
            )
        except Exception as exc:  # noqa: BLE001
            rows.append({"migration_table": migration_table, "gold_table": gold_table, "pass": False, "error": str(exc)})

    report = {
        "proc_name": proc_name,
        "target_date": target_date.isoformat(),
        "has_date_param": args.has_date_param,
        "mapped_table_count": len(mapped),
        "pass_count": sum(1 for r in rows if r.get("pass")),
        "fail_count": sum(1 for r in rows if not r.get("pass")),
        "all_pass": all(bool(r.get("pass")) for r in rows) if rows else False,
        "rows": rows,
    }
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps({"report": str(out_json), "all_pass": report["all_pass"], "mapped_table_count": len(mapped)}, indent=2))
    return 0 if report["all_pass"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
