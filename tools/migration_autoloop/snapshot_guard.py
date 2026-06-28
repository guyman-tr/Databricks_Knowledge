#!/usr/bin/env python3
"""Validate/refresh daily_snapshot table locations for a target snapshot date."""
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


def _q(value: str) -> str:
    return value.replace("'", "''")


def _target_date_iso(arg: str | None) -> str:
    if arg:
        return arg
    return (dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)).isoformat()


def _list_proc_snapshot_tables(warehouse_id: str, proc_name: str) -> list[str]:
    w = make_workspace_client()
    cols, rows = execute_sql(
        w,
        sql_text=(
            "SELECT routine_definition "
            "FROM system.information_schema.routines "
            "WHERE routine_catalog='dwh_daily_process' "
            "AND routine_schema='migration_tables' "
            f"AND routine_name='{_q(proc_name)}'"
        ),
        warehouse_id=warehouse_id,
    )
    if not rows:
        return []
    body = str(rows[0][cols.index("routine_definition")])
    names = re.findall(r"dwh_daily_process\.daily_snapshot\.([A-Za-z0-9_]+)", body, flags=re.IGNORECASE)
    return sorted({n for n in names})


def _snapshot_rows(warehouse_id: str, table_names: list[str] | None) -> list[dict[str, str]]:
    w = make_workspace_client()
    where = [
        "table_catalog='dwh_daily_process'",
        "table_schema='daily_snapshot'",
    ]
    if table_names:
        in_clause = ", ".join(f"'{_q(t.lower())}'" for t in table_names)
        where.append(f"lower(table_name) IN ({in_clause})")
    sql = (
        "SELECT table_name, storage_path, CAST(last_altered AS STRING) AS last_altered "
        "FROM system.information_schema.tables "
        f"WHERE {' AND '.join(where)} "
        "ORDER BY table_name"
    )
    cols, rows = execute_sql(w, sql_text=sql, warehouse_id=warehouse_id)
    out: list[dict[str, str]] = []
    for row in rows:
        item = {cols[i]: ("" if row[i] is None else str(row[i])) for i in range(len(cols))}
        m = re.search(r"etr_ymd=([0-9]{4}-[0-9]{2}-[0-9]{2})", item.get("storage_path", ""))
        item["snapshot_date"] = m.group(1) if m else ""
        out.append(item)
    return out


def _path_for_date(path: str, target_date: str) -> str:
    y, m, _ = target_date.split("-")
    out = re.sub(r"etr_ymd=[0-9]{4}-[0-9]{2}-[0-9]{2}", f"etr_ymd={target_date}", path)
    out = re.sub(r"etr_ym=[0-9]{4}-[0-9]{2}", f"etr_ym={y}-{m}", out)
    out = re.sub(r"etr_y=[0-9]{4}", f"etr_y={y}", out)
    return out


def ensure_snapshot_date(
    *,
    warehouse_id: str,
    target_date: str,
    proc_name: str,
    auto_refresh: bool,
) -> dict[str, object]:
    required_tables = _list_proc_snapshot_tables(warehouse_id, proc_name)
    rows = _snapshot_rows(warehouse_id, required_tables)
    w = make_workspace_client()
    refreshed: list[dict[str, str]] = []
    stale: list[dict[str, str]] = []

    for r in rows:
        table = r["table_name"]
        path = r.get("storage_path", "")
        current = r.get("snapshot_date", "")
        if not path or not current:
            continue
        if current >= target_date:
            continue
        stale.append({"table_name": table, "snapshot_date": current, "storage_path": path})
        if auto_refresh:
            new_path = _path_for_date(path, target_date)
            execute_sql(
                w,
                sql_text=f"ALTER TABLE dwh_daily_process.daily_snapshot.{table} SET LOCATION '{_q(new_path)}'",
                warehouse_id=warehouse_id,
            )
            # Smoke check table resolves at new location.
            execute_sql(
                w,
                sql_text=f"SELECT COUNT(*) AS c FROM dwh_daily_process.daily_snapshot.{table}",
                warehouse_id=warehouse_id,
            )
            refreshed.append({"table_name": table, "old_path": path, "new_path": new_path})

    post_rows = _snapshot_rows(warehouse_id, required_tables)
    unresolved = [r for r in post_rows if r.get("snapshot_date", "") and r["snapshot_date"] < target_date]
    return {
        "target_date": target_date,
        "proc_name": proc_name,
        "required_table_count": len(required_tables),
        "stale_before_count": len(stale),
        "refreshed_count": len(refreshed),
        "unresolved_count": len(unresolved),
        "stale_before": stale,
        "refreshed": refreshed,
        "post_snapshot_rows": post_rows,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--target-date", default="", help="YYYY-MM-DD; default is yesterday UTC.")
    ap.add_argument(
        "--proc-name",
        default="sp_fact_customerunrealized_pnl_dl_to_synapse_autopoc",
        help="Procedure to parse for daily_snapshot dependencies.",
    )
    ap.add_argument("--auto-refresh", action="store_true", help="Apply ALTER TABLE SET LOCATION for stale tables.")
    ap.add_argument(
        "--out-json",
        default="tools/migration_autoloop/runtime/snapshot_guard.json",
        help="Output JSON report path.",
    )
    args = ap.parse_args()

    target_date = _target_date_iso(args.target_date.strip() or None)
    report = ensure_snapshot_date(
        warehouse_id=warehouse_id_from_env(),
        target_date=target_date,
        proc_name=args.proc_name,
        auto_refresh=args.auto_refresh,
    )

    out_path = Path(args.out_json)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps({"report": str(out_path), **{k: report[k] for k in ["target_date", "stale_before_count", "refreshed_count", "unresolved_count"]}}, indent=2))
    return 0 if int(report["unresolved_count"]) == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())

