#!/usr/bin/env python3
"""Run one migration flow and emit date-slice trust report."""
from __future__ import annotations

import argparse
import datetime as dt
import json
import math
import re
import subprocess
import sys
from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env
from tools.migration_autoloop.flow_catalog import FLOW_CATALOG

NUMERIC_TYPES = ("bigint", "int", "smallint", "tinyint", "double", "float", "decimal", "numeric", "real")
DATE_TYPES = ("date", "timestamp", "datetime")
PREFERRED_METRIC_KEYS = ("amount", "commission", "pnl", "notional", "equity", "rate", "fee")
TECH_EXCLUDE = {"updatedate", "etr_y", "etr_ym", "etr_ymd", "year", "month", "day"}


def _target_date(value: str) -> dt.date:
    if value.strip():
        return dt.date.fromisoformat(value.strip())
    return dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)


def _parse_fqn(fqn: str) -> tuple[str, str, str]:
    parts = fqn.split(".")
    if len(parts) != 3:
        raise ValueError(f"Expected 3-part table name, got: {fqn}")
    return parts[0], parts[1], parts[2]


def _date_from_id(date_id: int) -> dt.date:
    return dt.datetime.strptime(str(date_id), "%Y%m%d").date()


def _one_row(sql: str, poll_deadline_sec: float = 1800.0) -> dict[str, object]:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    cols, rows = execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=poll_deadline_sec)
    if not rows:
        return {}
    return {c: rows[0][i] for i, c in enumerate(cols)}


def _query_table_columns(table_fqn: str) -> list[dict[str, object]]:
    catalog, schema, table = _parse_fqn(table_fqn)
    sql = f"""
SELECT column_name, data_type, ordinal_position
FROM system.information_schema.columns
WHERE table_catalog='{catalog}'
  AND table_schema='{schema}'
  AND table_name='{table}'
ORDER BY ordinal_position
""".strip()
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    cols, rows = execute_sql(w, sql_text=sql, warehouse_id=wid)
    out: list[dict[str, object]] = []
    for r in rows:
        out.append({c: r[i] for i, c in enumerate(cols)})
    return out


def _date_filter(
    columns: list[dict[str, object]],
    target_date: dt.date,
    *,
    preferred_column: str = "",
    dialect: str = "dbx",
) -> tuple[str, str]:
    target_id = int(target_date.strftime("%Y%m%d"))
    target_id_str = str(target_id)
    name_to_type = {str(c["column_name"]): str(c["data_type"]).lower() for c in columns}
    int_candidates = ["DateModified", "DateID", "DateKey", "InsertDateID", "UpdateDateID", "DateRangeID"]
    date_render = (
        lambda c: f"DATE({c}) = DATE('{target_date.isoformat()}')"
        if dialect == "dbx"
        else f"CONVERT(date, {c}) = '{target_date.isoformat()}'"
    )
    if preferred_column and preferred_column in name_to_type:
        typ = name_to_type[preferred_column]
        if preferred_column == "DateRangeID":
            if dialect == "dbx":
                return f"LEFT(CAST(DateRangeID AS STRING), 8) = '{target_id_str}'", preferred_column
            return f"LEFT(CAST(DateRangeID AS VARCHAR(20)), 8) = '{target_id_str}'", preferred_column
        if any(t in typ for t in NUMERIC_TYPES):
            return f"{preferred_column} = {target_id}", preferred_column
        return date_render(preferred_column), preferred_column
    for c in int_candidates:
        if c in name_to_type:
            if c == "DateRangeID":
                if dialect == "dbx":
                    return f"LEFT(CAST(DateRangeID AS STRING), 8) = '{target_id_str}'", c
                return f"LEFT(CAST(DateRangeID AS VARCHAR(20)), 8) = '{target_id_str}'", c
            return f"{c} = {target_id}", c
    for name, typ in name_to_type.items():
        lname = name.lower()
        if "date" not in lname and "occurred" not in lname:
            continue
        if any(t in typ for t in DATE_TYPES):
            return date_render(name), name
    return "1=1", ""


def _metric_columns(columns: list[dict[str, object]]) -> list[str]:
    usable = []
    for c in columns:
        name = str(c["column_name"])
        typ = str(c["data_type"]).lower()
        lname = name.lower()
        if not any(t in typ for t in NUMERIC_TYPES):
            continue
        if lname in TECH_EXCLUDE:
            continue
        if lname.endswith("id") and "amount" not in lname:
            continue
        usable.append(name)
    preferred: list[str] = []
    for key in PREFERRED_METRIC_KEYS:
        for n in usable:
            if key in n.lower() and n not in preferred:
                preferred.append(n)
    if preferred:
        return preferred[:3]
    return usable[:3]


def _aggregates(table_fqn: str, where_sql: str, metrics: list[str]) -> dict[str, float]:
    sum_expr = ", ".join([f"SUM(CAST({c} AS DECIMAL(38,10))) AS sum_{c}" for c in metrics])
    select = f"COUNT(*) AS rows_cnt{', ' + sum_expr if sum_expr else ''}"
    sql = f"SELECT {select} FROM {table_fqn} WHERE {where_sql}"
    row = _one_row(sql, poll_deadline_sec=3600.0)
    out: dict[str, float] = {"rows_cnt": float(row.get("rows_cnt") or 0.0)}
    for c in metrics:
        out[f"sum_{c}"] = float(row.get(f"sum_{c}") or 0.0)
    return out


def _call_proc(proc_name: str, target_date: dt.date, has_date_param: bool) -> None:
    if has_date_param:
        sql = f"CALL dwh_daily_process.migration_tables.{proc_name}(TIMESTAMP '{target_date.isoformat()}')"
    else:
        sql = f"CALL dwh_daily_process.migration_tables.{proc_name}()"
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=7200.0)


def _routine_dump(proc_name: str) -> tuple[str, str, list[str]]:
    sql = f"""
SELECT routine_definition
FROM system.information_schema.routines
WHERE routine_catalog='dwh_daily_process'
  AND routine_schema='migration_tables'
  AND routine_name='{proc_name}'
""".strip()
    row = _one_row(sql)
    body = str(row.get("routine_definition") or "")
    out_dir = Path("tools/migration_autoloop/runtime/proc_dumps")
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{proc_name}.sql"
    out_path.write_text(body, encoding="utf-8")
    interim = sorted(
        set(
            re.findall(
                r"dwh_daily_process\.migration_tables\.(Ext_[A-Za-z0-9_]+|stg_[A-Za-z0-9_]+|vw_[A-Za-z0-9_]+)",
                body,
                flags=re.IGNORECASE,
            )
        )
    )
    return body, str(out_path), interim[:6]


def _synapse_query_one(sql: str) -> dict[str, object]:
    try:
        from synapse_connect import connect, run_query
    except Exception as exc:  # noqa: BLE001
        return {"enabled": False, "error": f"import_failed: {exc}"}
    try:
        conn = connect(verbose=False)
    except Exception as exc:  # noqa: BLE001
        return {"enabled": False, "error": f"connect_failed: {exc}"}
    try:
        cols, rows = run_query(conn, sql)
        if not rows:
            return {"enabled": True, "row": {}}
        return {"enabled": True, "row": {c: rows[0][i] for i, c in enumerate(cols)}}
    except Exception as exc:  # noqa: BLE001
        return {"enabled": True, "error": str(exc)}
    finally:
        conn.close()


def _synapse_aggregates(table_fqn: str, where_sql: str, metrics: list[str]) -> dict[str, object]:
    select = "COUNT_BIG(*) AS rows_cnt"
    if metrics:
        select += ", " + ", ".join([f"SUM(CAST({c} AS DECIMAL(38,10))) AS sum_{c}" for c in metrics])
    sql = f"SELECT {select} FROM {table_fqn} WHERE {where_sql}"
    res = _synapse_query_one(sql)
    if not res.get("enabled"):
        return res
    if res.get("error"):
        return res
    row = res.get("row", {})
    out = {"enabled": True, "rows_cnt": float(row.get("rows_cnt") or 0.0)}
    for c in metrics:
        out[f"sum_{c}"] = float(row.get(f"sum_{c}") or 0.0)
    return out


def _synapse_columns(table_fqn: str) -> list[dict[str, object]]:
    schema, table = table_fqn.split(".", 1)
    sql = f"""
SELECT COLUMN_NAME AS column_name, DATA_TYPE AS data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = '{schema}'
  AND TABLE_NAME = '{table}'
ORDER BY ORDINAL_POSITION
""".strip()
    try:
        from synapse_connect import connect, run_query
    except Exception:
        return []
    try:
        conn = connect(verbose=False)
    except Exception:
        return []
    try:
        cols, rows = run_query(conn, sql)
        out: list[dict[str, object]] = []
        for r in rows:
            out.append({c: r[i] for i, c in enumerate(cols)})
        return out
    finally:
        conn.close()


def _dbx_max_date_id_on_or_before(table_fqn: str, column: str, target_id: int) -> int | None:
    row = _one_row(
        f"SELECT MAX(CAST({column} AS BIGINT)) AS mx FROM {table_fqn} "
        f"WHERE CAST({column} AS BIGINT) <= {target_id}"
    )
    val = row.get("mx")
    return int(val) if val is not None else None


def _synapse_max_date_id_on_or_before(table_fqn: str, column: str, target_id: int) -> int | None:
    res = _synapse_query_one(
        f"SELECT MAX(CAST({column} AS BIGINT)) AS mx FROM {table_fqn} "
        f"WHERE CAST({column} AS BIGINT) <= {target_id}"
    )
    if not res.get("enabled") or res.get("error"):
        return None
    val = res.get("row", {}).get("mx")
    return int(val) if val is not None else None


def _metric_deltas(left: dict[str, float], right: dict[str, float], metrics: list[str]) -> dict[str, float]:
    out = {"delta_rows": left["rows_cnt"] - right["rows_cnt"]}
    for c in metrics:
        k = f"sum_{c}"
        out[f"delta_{k}"] = left.get(k, 0.0) - right.get(k, 0.0)
    return out


def _bool_pass(row_delta: dict[str, float], metrics: list[str], tol: float = 0.000001) -> bool:
    if int(row_delta["delta_rows"]) != 0:
        return False
    for c in metrics:
        if not math.isclose(row_delta.get(f"delta_sum_{c}", 0.0), 0.0, abs_tol=tol):
            return False
    return True


def _load_job_state(flow_id: str) -> str:
    path = Path("tools/migration_autoloop/out/adf_candidate_flows.json")
    if not path.exists():
        return "unknown"
    payload = json.loads(path.read_text(encoding="utf-8"))
    for row in payload.get("ordered_flows", []):
        if row.get("flow_id") == flow_id:
            return str(row.get("databricks_job_state") or "unknown")
    return "unknown"


def _ensure_flow_autopoc_proc(flow_id: str) -> dict[str, object]:
    patch_scripts = {
        "fact_currencypricewithsplit": Path("tools/migration_autoloop/patch_currencypricewithsplit_autopoc.py"),
    }
    patch_script = patch_scripts.get(flow_id)
    if patch_script is None:
        return {"patched": False}
    proc = subprocess.run(
        [sys.executable, str(patch_script)],
        check=True,
        capture_output=True,
        text=True,
    )
    return {"patched": True, "stdout": proc.stdout.strip()}


def _write_md(path: Path, report: dict[str, object]) -> None:
    lines = [
        f"# Autoloop Trust Report — {report['flow_id']}",
        "",
        f"- Pipeline: `{report['pipeline_name']}`",
        f"- Target date: `{report['target_date']}`",
        f"- Procedure: `{report['procedure_name']}`",
        f"- Migration table: `{report['migration_table']}`",
        f"- Gold table: `{report['gold_table']}`",
        f"- Synapse table: `{report['synapse_table']}`",
        f"- Databricks task state: `{report['databricks_job_state']}`",
        f"- QA pass (migration vs gold): `{report['qa_pass_migration_vs_gold']}`",
        "",
        "## Core metrics",
        f"- Pre rows: `{int(report['pre_migration']['rows_cnt'])}`",
        f"- Post rows: `{int(report['post_migration']['rows_cnt'])}`",
        f"- Gold rows: `{int(report['gold']['rows_cnt'])}`",
        f"- Delta rows (post-gold): `{report['migration_vs_gold']['delta_rows']}`",
        "",
        "## Interim triage",
    ]
    for row in report.get("interim_triage", []):
        lines.append(
            f"- `{row['table']}`: dbx_rows={int(row['dbx'].get('rows_cnt', 0.0))}, "
            f"syn_rows={int(row.get('synapse', {}).get('rows_cnt', 0.0)) if row.get('synapse', {}).get('enabled') else 'n/a'}, "
            f"delta={row.get('dbx_vs_synapse', {}).get('delta_rows', 'n/a')}"
        )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--flow-id", required=True, choices=sorted(FLOW_CATALOG.keys()))
    ap.add_argument("--target-date", default="", help="YYYY-MM-DD. Default: yesterday UTC.")
    ap.add_argument("--out-json", default="")
    ap.add_argument("--out-md", default="")
    args = ap.parse_args()

    flow = FLOW_CATALOG[args.flow_id]
    target_date = _target_date(args.target_date)
    out_json = (
        Path(args.out_json)
        if args.out_json.strip()
        else Path(f"tools/migration_autoloop/out/{flow.flow_id}_trust_report_{target_date.isoformat()}.json")
    )
    out_md = (
        Path(args.out_md)
        if args.out_md.strip()
        else Path(f"tools/migration_autoloop/out/{flow.flow_id}_trust_report_{target_date.isoformat()}.md")
    )

    autopoc_patch = _ensure_flow_autopoc_proc(flow.flow_id)
    cols = _query_table_columns(flow.migration_table)
    preferred_slice_col = flow.date_slice_column.strip()
    where_sql, where_col = _date_filter(
        cols,
        target_date,
        preferred_column=preferred_slice_col,
        dialect="dbx",
    )
    gold_cols = _query_table_columns(flow.gold_table)
    where_gold, where_gold_col = _date_filter(
        gold_cols,
        target_date,
        preferred_column=preferred_slice_col or where_col,
        dialect="dbx",
    )
    metrics = [m for m in _metric_columns(cols) if m in {str(c["column_name"]) for c in gold_cols}]

    _, proc_dump_path, interim_tables = _routine_dump(flow.procedure_name)
    pre = _aggregates(flow.migration_table, where_sql, metrics)
    _call_proc(flow.procedure_name, target_date, flow.has_date_param)
    post = _aggregates(flow.migration_table, where_sql, metrics)
    gold = _aggregates(flow.gold_table, where_gold, metrics)
    migration_vs_gold = _metric_deltas(post, gold, metrics)

    syn_cols = _synapse_columns(flow.synapse_table)
    where_syn, where_syn_col = _date_filter(
        syn_cols,
        target_date,
        preferred_column=preferred_slice_col or where_col,
        dialect="synapse",
    )
    syn_metrics = [m for m in metrics if m in {str(c["column_name"]) for c in syn_cols}] if syn_cols else metrics

    compare_date_gold = target_date
    compare_date_syn = target_date
    if flow.compare_on_common_date and preferred_slice_col:
        target_id = int(target_date.strftime("%Y%m%d"))
        mig_max = _dbx_max_date_id_on_or_before(flow.migration_table, preferred_slice_col, target_id)
        gold_max = _dbx_max_date_id_on_or_before(flow.gold_table, preferred_slice_col, target_id)
        syn_max = _synapse_max_date_id_on_or_before(flow.synapse_table, preferred_slice_col, target_id)
        if mig_max is not None and gold_max is not None:
            compare_date_gold = _date_from_id(min(mig_max, gold_max))
        if mig_max is not None and syn_max is not None:
            compare_date_syn = _date_from_id(min(mig_max, syn_max))

    where_sql_compare_gold, _ = _date_filter(
        cols,
        compare_date_gold,
        preferred_column=preferred_slice_col or where_col,
        dialect="dbx",
    )
    where_gold_compare, _ = _date_filter(
        gold_cols,
        compare_date_gold,
        preferred_column=preferred_slice_col or where_gold_col or where_col,
        dialect="dbx",
    )
    post_for_gold = _aggregates(flow.migration_table, where_sql_compare_gold, metrics)
    gold = _aggregates(flow.gold_table, where_gold_compare, metrics)
    migration_vs_gold = _metric_deltas(post_for_gold, gold, metrics)

    where_sql_compare_syn, _ = _date_filter(
        cols,
        compare_date_syn,
        preferred_column=preferred_slice_col or where_col,
        dialect="dbx",
    )
    where_syn_compare, _ = _date_filter(
        syn_cols,
        compare_date_syn,
        preferred_column=preferred_slice_col or where_col,
        dialect="synapse",
    )
    post_for_syn = _aggregates(flow.migration_table, where_sql_compare_syn, syn_metrics)
    syn = _synapse_aggregates(flow.synapse_table, where_syn_compare, syn_metrics)
    post_vs_syn: dict[str, object] = {}
    if syn.get("enabled") and not syn.get("error"):
        # Align metrics that exist on both sides for delta math.
        aligned_post = {"rows_cnt": post_for_syn["rows_cnt"]}
        aligned_syn = {"rows_cnt": syn["rows_cnt"]}
        for m in syn_metrics:
            aligned_post[f"sum_{m}"] = post_for_syn.get(f"sum_{m}", 0.0)
            aligned_syn[f"sum_{m}"] = syn.get(f"sum_{m}", 0.0)
        post_vs_syn = _metric_deltas(aligned_post, aligned_syn, syn_metrics)
    else:
        post_vs_syn = {"error": syn.get("error", "synapse_not_enabled")}

    interim_triage: list[dict[str, object]] = []
    for t in interim_tables:
        dbx_fqn = f"dwh_daily_process.migration_tables.{t}"
        syn_fqn = f"DWH_dbo.{t}"
        try:
            t_cols = _query_table_columns(dbx_fqn)
            t_where, t_where_col = _date_filter(t_cols, target_date, dialect="dbx")
            t_metrics = _metric_columns(t_cols)[:1]
            dbx_vals = _aggregates(dbx_fqn, t_where, t_metrics)
            syn_t_cols = _synapse_columns(syn_fqn)
            t_where_syn, _ = _date_filter(
                syn_t_cols, target_date, preferred_column=t_where_col, dialect="synapse"
            )
            t_syn_metrics = [m for m in t_metrics if m in {str(c["column_name"]) for c in syn_t_cols}] if syn_t_cols else t_metrics
            syn_vals = _synapse_aggregates(syn_fqn, t_where_syn, t_syn_metrics)
            rec: dict[str, object] = {"table": t, "dbx": dbx_vals, "synapse": syn_vals}
            if syn_vals.get("enabled") and not syn_vals.get("error"):
                aligned_dbx = {"rows_cnt": dbx_vals["rows_cnt"]}
                aligned_syn2 = {"rows_cnt": syn_vals["rows_cnt"]}
                for m in t_syn_metrics:
                    aligned_dbx[f"sum_{m}"] = dbx_vals.get(f"sum_{m}", 0.0)
                    aligned_syn2[f"sum_{m}"] = syn_vals.get(f"sum_{m}", 0.0)
                rec["dbx_vs_synapse"] = _metric_deltas(aligned_dbx, aligned_syn2, t_syn_metrics)
            interim_triage.append(rec)
        except Exception as exc:  # noqa: BLE001
            interim_triage.append({"table": t, "error": str(exc)})

    report: dict[str, object] = {
        "flow_id": flow.flow_id,
        "pipeline_name": flow.pipeline_name,
        "target_date": target_date.isoformat(),
        "target_date_id": int(target_date.strftime("%Y%m%d")),
        "migration_table": flow.migration_table,
        "gold_table": flow.gold_table,
        "synapse_table": flow.synapse_table,
        "procedure_name": flow.procedure_name,
        "has_date_param": flow.has_date_param,
        "databricks_job_state": _load_job_state(flow.flow_id),
        "autopoc_patch": autopoc_patch,
        "where_clause": where_sql,
        "where_column_used": where_col,
        "where_clause_gold": where_gold,
        "where_column_used_gold": where_gold_col,
        "where_clause_synapse": where_syn_compare,
        "where_column_used_synapse": where_syn_col,
        "comparison_date_migration_vs_gold": compare_date_gold.isoformat(),
        "comparison_date_post_migration_vs_synapse": compare_date_syn.isoformat(),
        "where_clause_migration_compare_gold": where_sql_compare_gold,
        "where_clause_gold_compare": where_gold_compare,
        "where_clause_migration_compare_synapse": where_sql_compare_syn,
        "metrics": metrics,
        "proc_dump_path": proc_dump_path,
        "pre_migration": pre,
        "post_migration": post,
        "gold": gold,
        "migration_vs_gold": migration_vs_gold,
        "synapse_final": syn,
        "post_migration_vs_synapse": post_vs_syn,
        "interim_triage": interim_triage,
    }
    report["qa_pass_migration_vs_gold"] = _bool_pass(migration_vs_gold, metrics)

    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(report, indent=2), encoding="utf-8")
    _write_md(out_md, report)
    print(
        json.dumps(
            {
                "flow_id": flow.flow_id,
                "target_date": target_date.isoformat(),
                "qa_pass_migration_vs_gold": report["qa_pass_migration_vs_gold"],
                "out_json": str(out_json),
                "out_md": str(out_md),
            },
            indent=2,
        )
    )
    return 0 if report["qa_pass_migration_vs_gold"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
