#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def _sql_escape(value: str) -> str:
    return value.replace("'", "''")


def _extract_table_not_found(raw: str) -> str:
    import re

    m = re.search(
        r"The table or view `([^`]+)`\.`([^`]+)`\.`([^`]+)` cannot be found",
        raw,
        flags=re.IGNORECASE,
    )
    if not m:
        return ""
    return f"{m.group(1)}.{m.group(2)}.{m.group(3)}"


def _first_line(text: str, default: str = "") -> str:
    for line in (text or "").splitlines():
        s = line.strip()
        if s:
            return s
    return default


def _human_summary(
    *,
    flow_key: str,
    proc_name: str,
    run_status: str,
    parity_pass: bool,
    mapped: int,
    pass_index: int,
    max_passes: int,
    report: dict,
    raw_notes: str,
) -> str:
    if run_status == "success":
        return (
            f"SUCCESS: {flow_key} ({proc_name}) matched parity checks for target date. "
            f"Attempts today: {pass_index}."
        )

    if mapped == 0:
        return (
            f"PARKED: No mapping exists yet between migration output and gold target for {flow_key}. "
            f"Parity cannot be evaluated until mapping is added."
        )

    missing_obj = _extract_table_not_found(raw_notes)
    if missing_obj:
        return (
            f"{run_status.upper()}: Source object missing: {missing_obj}. "
            "Run cannot complete until this table/view is created or remapped."
        )

    if "DATATYPE_MISMATCH" in raw_notes:
        return (
            f"{run_status.upper()}: SQL datatype mismatch in procedure logic. "
            "Procedure needs dialect patch before parity can run."
        )

    rows = report.get("rows")
    if isinstance(rows, list) and rows:
        first = rows[0] if isinstance(rows[0], dict) else {}
        post_rows = (first.get("post") or {}).get("rows_cnt")
        gold_rows = (first.get("gold") or {}).get("rows_cnt")
        if post_rows is not None and gold_rows is not None and not parity_pass:
            return (
                f"{run_status.upper()}: Parity mismatch. Migration rows={post_rows}, gold rows={gold_rows}. "
                f"Attempts today: {pass_index}/{max_passes}."
            )

    if pass_index >= max_passes:
        return (
            f"PARKED: Hit retry limit ({max_passes}) without success/parity for {flow_key}. "
            "Needs manual fix before retrying."
        )

    return (
        f"{run_status.upper()}: Run failed without parity. "
        f"Attempts today: {pass_index}/{max_passes}. "
        f"Last error: {_first_line(raw_notes, 'see report')}"
    )


def _next_pass_index(w, wid: str, flow_key: str, target_date: str) -> int:
    sql = f"""
SELECT COALESCE(COUNT(*), 0) AS c
FROM dwh_daily_process.qa.autoloop_flow_telemetry
WHERE flow_key = '{_sql_escape(flow_key)}'
  AND target_date = DATE '{_sql_escape(target_date)}'
"""
    cols, rows = execute_sql(w, sql_text=sql, warehouse_id=wid)
    if not rows:
        return 1
    idx = cols.index("c")
    return int(rows[0][idx] or 0) + 1


def _mapped_from_report(report: dict) -> int | None:
    if "mapped_table_count" in report:
        return int(report.get("mapped_table_count") or 0)
    if report.get("migration_table") and report.get("gold_table"):
        return 1
    rows = report.get("rows")
    if isinstance(rows, list):
        for row in rows:
            if not isinstance(row, dict):
                continue
            if row.get("migration_table") and row.get("gold_table"):
                return 1
    return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--flow-key", required=True)
    ap.add_argument("--proc-name", required=True)
    ap.add_argument("--target-date", required=True)
    ap.add_argument("--report-path", required=True)
    ap.add_argument("--return-code", type=int, required=True)
    # Model-cost args are accepted for backward compatibility but IGNORED.
    # We do not have a real token meter, so cost columns are written as NULL
    # rather than fabricated. Use Cursor's usage dashboard for real billing.
    ap.add_argument("--cost-low", type=float, default=None)
    ap.add_argument("--cost-mid", type=float, default=None)
    ap.add_argument("--cost-high", type=float, default=None)
    ap.add_argument("--cumulative-mid", type=float, default=None)
    ap.add_argument("--notes", default="")
    ap.add_argument("--max-passes", type=int, default=10)
    ap.add_argument("--park-reason", default="")
    args = ap.parse_args()

    report = {}
    rp = Path(args.report_path)
    if rp.exists():
        report = json.loads(rp.read_text(encoding="utf-8"))

    w = make_workspace_client()
    wid = warehouse_id_from_env()
    mapped = _mapped_from_report(report)

    if "all_pass" in report:
        parity_pass = bool(report.get("all_pass"))
    elif "qa_pass_migration_vs_gold" in report:
        parity_pass = bool(report.get("qa_pass_migration_vs_gold"))
    else:
        parity_pass = False
    pass_index = _next_pass_index(w, wid, args.flow_key, args.target_date)
    if args.return_code == 0 and parity_pass:
        run_status = "success"
    elif mapped == 0:
        run_status = "executed_no_mapping"
    else:
        run_status = "failed"
    if mapped == 0:
        run_status = "parked"
    if run_status != "success" and pass_index >= int(args.max_passes):
        run_status = "parked"
    raw_notes = args.notes.strip()
    if not raw_notes:
        raw_notes = json.dumps(
            {
                "report": args.report_path,
                "all_pass": parity_pass,
                "mapped_table_count": mapped,
                "pass_index": pass_index,
                "max_passes": int(args.max_passes),
            }
        )
    summary = _human_summary(
        flow_key=args.flow_key,
        proc_name=args.proc_name,
        run_status=run_status,
        parity_pass=parity_pass,
        mapped=(mapped or 0) if mapped is not None else -1,
        pass_index=pass_index,
        max_passes=int(args.max_passes),
        report=report,
        raw_notes=raw_notes,
    )
    notes = summary
    mapped_for_store = mapped if mapped is not None else -1

    sql = f"""
INSERT INTO dwh_daily_process.qa.autoloop_flow_telemetry
SELECT
  current_timestamp(),
  '{_sql_escape(args.flow_key)}',
  '{_sql_escape(args.proc_name)}',
  DATE '{_sql_escape(args.target_date)}',
  '{_sql_escape(run_status)}',
  {str(parity_pass).lower()},
  {args.return_code},
  {mapped_for_store},
  {int(report.get("pass_count") or (1 if parity_pass else 0))},
  {int(report.get("fail_count") or (0 if parity_pass else 1))},
  '{_sql_escape(args.report_path)}',
  '{_sql_escape(json.dumps(report, ensure_ascii=True))}',
  CAST(NULL AS DOUBLE),
  CAST(NULL AS DOUBLE),
  CAST(NULL AS DOUBLE),
  CAST(NULL AS DOUBLE),
  '{_sql_escape(notes)}'
"""
    execute_sql(w, sql_text=sql, warehouse_id=wid)
    print("ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
