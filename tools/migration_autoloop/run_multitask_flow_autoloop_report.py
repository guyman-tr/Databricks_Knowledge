#!/usr/bin/env python3
"""Run one multi-task migration flow and emit consolidated trust evidence."""
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.flow_catalog import MULTI_TASK_FLOW_CATALOG
from tools.migration_autoloop.run_flow_autoloop_report import (
    _date_from_id,
    _dbx_max_date_id_on_or_before,
    _aggregates,
    _bool_pass,
    _call_proc,
    _date_filter,
    _metric_columns,
    _metric_deltas,
    _synapse_aggregates,
    _synapse_columns,
    _target_date,
    _query_table_columns,
)


def _run_child(child: object, target_date: object, include_synapse: bool) -> dict[str, object]:
    migration_cols = _query_table_columns(child.migration_table)
    where_mig, where_col = _date_filter(migration_cols, target_date, dialect="dbx")

    gold_cols = _query_table_columns(child.gold_table)
    where_gold, where_gold_col = _date_filter(gold_cols, target_date, preferred_column=where_col, dialect="dbx")

    compare_date = target_date
    if child.compare_on_common_date and child.date_slice_column:
        target_id = int(target_date.strftime("%Y%m%d"))
        mig_max = _dbx_max_date_id_on_or_before(child.migration_table, child.date_slice_column, target_id)
        gold_max = _dbx_max_date_id_on_or_before(child.gold_table, child.date_slice_column, target_id)
        if mig_max is not None and gold_max is not None:
            compare_id = min(mig_max, gold_max)
            compare_date = _date_from_id(compare_id)
            where_mig, where_col = _date_filter(
                migration_cols,
                compare_date,
                preferred_column=child.date_slice_column,
                dialect="dbx",
            )
            where_gold, where_gold_col = _date_filter(
                gold_cols,
                compare_date,
                preferred_column=child.date_slice_column,
                dialect="dbx",
            )

    metrics = [m for m in _metric_columns(migration_cols) if m in {str(c["column_name"]) for c in gold_cols}]
    pre = _aggregates(child.migration_table, where_mig, metrics)
    _call_proc(child.procedure_name, target_date, child.has_date_param)
    post = _aggregates(child.migration_table, where_mig, metrics)
    gold = _aggregates(child.gold_table, where_gold, metrics)
    mig_vs_gold = _metric_deltas(post, gold, metrics)
    qa_pass = _bool_pass(mig_vs_gold, metrics)

    if include_synapse:
        syn_cols = _synapse_columns(child.synapse_table)
        where_syn, where_syn_col = _date_filter(syn_cols, target_date, preferred_column=where_col, dialect="synapse")
        syn_metrics = [m for m in metrics if m in {str(c["column_name"]) for c in syn_cols}] if syn_cols else metrics
        syn = _synapse_aggregates(child.synapse_table, where_syn, syn_metrics)
        if syn.get("enabled") and not syn.get("error"):
            aligned_post = {"rows_cnt": post["rows_cnt"]}
            aligned_syn = {"rows_cnt": syn["rows_cnt"]}
            for m in syn_metrics:
                aligned_post[f"sum_{m}"] = post.get(f"sum_{m}", 0.0)
                aligned_syn[f"sum_{m}"] = syn.get(f"sum_{m}", 0.0)
            post_vs_syn = _metric_deltas(aligned_post, aligned_syn, syn_metrics)
        else:
            post_vs_syn = {"error": syn.get("error", "synapse_not_enabled")}
    else:
        where_syn = ""
        where_syn_col = ""
        syn = {"enabled": False, "error": "skipped"}
        post_vs_syn = {"error": "skipped"}

    return {
        "flow_id": child.flow_id,
        "migration_table": child.migration_table,
        "gold_table": child.gold_table,
        "synapse_table": child.synapse_table,
        "procedure_name": child.procedure_name,
        "has_date_param": child.has_date_param,
        "where_clause": where_mig,
        "where_column_used": where_col,
        "where_clause_gold": where_gold,
        "where_column_used_gold": where_gold_col,
        "comparison_date_migration_vs_gold": compare_date.isoformat(),
        "where_clause_synapse": where_syn,
        "where_column_used_synapse": where_syn_col,
        "metrics": metrics,
        "pre_migration": pre,
        "post_migration": post,
        "gold": gold,
        "migration_vs_gold": mig_vs_gold,
        "qa_pass_migration_vs_gold": qa_pass,
        "synapse_final": syn,
        "post_migration_vs_synapse": post_vs_syn,
    }


def _write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(
            fh,
            fieldnames=[
                "flow_id",
                "procedure_name",
                "migration_table",
                "gold_table",
                "synapse_table",
                "metrics",
                "pre_rows",
                "post_rows",
                "gold_rows",
                "delta_rows_post_vs_gold",
                "qa_pass_migration_vs_gold",
                "post_vs_synapse",
                "error",
            ],
        )
        writer.writeheader()
        for row in rows:
            err = str(row.get("error", "") or "").replace("\r", " ").replace("\n", " | ").strip()
            writer.writerow(
                {
                    "flow_id": row.get("flow_id"),
                    "procedure_name": row.get("procedure_name"),
                    "migration_table": row.get("migration_table"),
                    "gold_table": row.get("gold_table"),
                    "synapse_table": row.get("synapse_table"),
                    "metrics": "|".join(str(m) for m in row.get("metrics", [])),
                    "pre_rows": int((row.get("pre_migration") or {}).get("rows_cnt", 0.0)) if row.get("pre_migration") else "",
                    "post_rows": int((row.get("post_migration") or {}).get("rows_cnt", 0.0))
                    if row.get("post_migration")
                    else "",
                    "gold_rows": int((row.get("gold") or {}).get("rows_cnt", 0.0)) if row.get("gold") else "",
                    "delta_rows_post_vs_gold": (row.get("migration_vs_gold") or {}).get("delta_rows", "")
                    if row.get("migration_vs_gold")
                    else "",
                    "qa_pass_migration_vs_gold": bool(row.get("qa_pass_migration_vs_gold")),
                    "post_vs_synapse": json.dumps(row.get("post_migration_vs_synapse") or {}, separators=(",", ":")),
                    "error": err,
                }
            )


def _write_md(path: Path, report: dict[str, object]) -> None:
    lines = [
        f"# Multi-Task Autoloop Trust Report — {report['flow_id']}",
        "",
        f"- Databricks job: `{report['databricks_job_name']}`",
        f"- Pipeline: `{report['pipeline_name']}`",
        f"- Target date: `{report['target_date']}`",
        f"- Child tasks: `{report['child_count']}`",
        f"- Overall QA pass (migration vs gold): `{report['qa_pass_all_children']}`",
        f"- Child summary CSV: `{report['child_summary_csv']}`",
        "",
    ]
    for row in report.get("children", []):
        err = str(row.get("error", "") or "").replace("\r", " ").replace("\n", " | ").strip()
        if row.get("error"):
            lines.extend(
                [
                    f"## {row.get('flow_id')}",
                    f"- Procedure: `{row.get('procedure_name')}`",
                    f"- QA pass (migration vs gold): `{row.get('qa_pass_migration_vs_gold')}`",
                    f"- Error: `{err}`",
                    "",
                ]
            )
            continue
        lines.extend(
            [
                f"## {row.get('flow_id')}",
                f"- Procedure: `{row.get('procedure_name')}`",
                f"- QA pass (migration vs gold): `{row.get('qa_pass_migration_vs_gold')}`",
                f"- Pre/Post/Gold rows: `{int((row.get('pre_migration') or {}).get('rows_cnt', 0.0))}` / "
                f"`{int((row.get('post_migration') or {}).get('rows_cnt', 0.0))}` / "
                f"`{int((row.get('gold') or {}).get('rows_cnt', 0.0))}`",
                f"- Delta rows (post-gold): `{(row.get('migration_vs_gold') or {}).get('delta_rows', 0.0)}`",
                "",
            ]
        )
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--flow-id", default="fact_customeraction_etl", choices=sorted(MULTI_TASK_FLOW_CATALOG.keys()))
    ap.add_argument("--target-date", default="", help="YYYY-MM-DD. Default: yesterday UTC.")
    ap.add_argument("--skip-synapse", action="store_true", help="Skip synapse comparison for faster runs.")
    ap.add_argument("--out-json", default="")
    ap.add_argument("--out-md", default="")
    ap.add_argument("--out-csv", default="")
    args = ap.parse_args()

    flow = MULTI_TASK_FLOW_CATALOG[args.flow_id]
    target_date = _target_date(args.target_date)
    target_iso = target_date.isoformat()

    out_json = (
        Path(args.out_json)
        if args.out_json.strip()
        else Path(f"tools/migration_autoloop/out/{flow.flow_id}_trust_report_{target_iso}.json")
    )
    out_md = (
        Path(args.out_md)
        if args.out_md.strip()
        else Path(f"tools/migration_autoloop/out/{flow.flow_id}_trust_report_{target_iso}.md")
    )
    out_csv = (
        Path(args.out_csv)
        if args.out_csv.strip()
        else Path(f"tools/migration_autoloop/out/{flow.flow_id}_child_summary_{target_iso}.csv")
    )

    results: list[dict[str, object]] = []
    for child in flow.children:
        print(f"running_child={child.flow_id} proc={child.procedure_name}", flush=True)
        try:
            res = _run_child(child, target_date, include_synapse=not args.skip_synapse)
            results.append(res)
            print(
                f"child_done={child.flow_id} pass={res.get('qa_pass_migration_vs_gold')}",
                flush=True,
            )
        except Exception as exc:  # noqa: BLE001
            results.append(
                {
                    "flow_id": child.flow_id,
                    "migration_table": child.migration_table,
                    "gold_table": child.gold_table,
                    "synapse_table": child.synapse_table,
                    "procedure_name": child.procedure_name,
                    "error": str(exc),
                    "qa_pass_migration_vs_gold": False,
                }
            )
            print(f"child_error={child.flow_id} err={str(exc)[:160]}", flush=True)

    qa_pass_all = all(bool(r.get("qa_pass_migration_vs_gold")) for r in results) if results else False
    report = {
        "flow_id": flow.flow_id,
        "pipeline_name": flow.pipeline_name,
        "databricks_job_name": flow.databricks_job_name,
        "target_date": target_iso,
        "target_date_id": int(target_date.strftime("%Y%m%d")),
        "child_count": len(results),
        "qa_pass_all_children": qa_pass_all,
        "child_summary_csv": str(out_csv),
        "children": results,
    }

    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(report, indent=2), encoding="utf-8")
    _write_csv(out_csv, results)
    _write_md(out_md, report)

    print(
        json.dumps(
            {
                "flow_id": flow.flow_id,
                "target_date": target_iso,
                "qa_pass_all_children": qa_pass_all,
                "out_json": str(out_json),
                "out_md": str(out_md),
                "out_csv": str(out_csv),
            },
            indent=2,
        )
    )
    return 0 if qa_pass_all else 2


if __name__ == "__main__":
    raise SystemExit(main())
