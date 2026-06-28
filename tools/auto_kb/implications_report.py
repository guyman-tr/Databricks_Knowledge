#!/usr/bin/env python3
"""Build a consolidated auto_kb skill implications report.

Reads all four auto_kb run-log tables from Unity Catalog, merges them into a
single row-level dataset, derives an implication label per row, and writes CSV
artifacts for fast daily review.
"""
from __future__ import annotations

import argparse
import csv
from collections import Counter, defaultdict
import datetime as dt
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.skill_suggestions.db import execute_sql, make_workspace_client, warehouse_id_from_env

DEFAULT_OUT_DIR = Path("Data_Skills_Automation/Auto_KB_Integrator/out")


def _implication(status: str, artifact_ref: str | None, pr_url: str | None) -> str:
    s = (status or "").strip().lower()
    has_artifact = bool((artifact_ref or "").strip())
    has_pr = bool((pr_url or "").strip())
    if s == "error":
        return "BLOCKER"
    if s == "done" and (has_artifact or has_pr):
        return "ACTIONABLE_CHANGE"
    if s == "done":
        return "DONE_NO_ARTIFACT"
    if s == "skipped":
        return "NO_CHANGE_SKIPPED"
    return "OTHER"


def fetch_rows(since_hours: int, limit: int) -> list[dict[str, str]]:
    sql = f"""
WITH merged AS (
  SELECT 'genie' app, run_id, item_id, item_kind, status, artifact_ref, pr_url, notes, processed_at
  FROM main.de_output.de_output_auto_kb_genie_runs
  WHERE processed_at >= current_timestamp() - INTERVAL {since_hours} HOURS
  UNION ALL
  SELECT 'uc_object' app, run_id, item_id, item_kind, status, artifact_ref, pr_url, notes, processed_at
  FROM main.de_output.de_output_auto_kb_uc_object_runs
  WHERE processed_at >= current_timestamp() - INTERVAL {since_hours} HOURS
  UNION ALL
  SELECT 'dbschema' app, run_id, item_id, item_kind, status, artifact_ref, pr_url, notes, processed_at
  FROM main.de_output.de_output_auto_kb_dbschema_runs
  WHERE processed_at >= current_timestamp() - INTERVAL {since_hours} HOURS
  UNION ALL
  SELECT 'confluence' app, run_id, item_id, item_kind, status, artifact_ref, pr_url, notes, processed_at
  FROM main.de_output.de_output_auto_kb_confluence_runs
  WHERE processed_at >= current_timestamp() - INTERVAL {since_hours} HOURS
  UNION ALL
  SELECT 'questions' app, run_id, item_id, item_kind, status, artifact_ref, pr_url, notes, processed_at
  FROM main.de_output.de_output_auto_kb_questions_runs
  WHERE processed_at >= current_timestamp() - INTERVAL {since_hours} HOURS
)
SELECT app, run_id, item_id, item_kind, status, artifact_ref, pr_url, notes, CAST(processed_at AS STRING) processed_at
FROM merged
ORDER BY processed_at DESC
LIMIT {limit}
""".strip()
    w = make_workspace_client()
    cols, rows = execute_sql(w, sql_text=sql, warehouse_id=warehouse_id_from_env())
    idx = {c: i for i, c in enumerate(cols)}
    out: list[dict[str, str]] = []
    for row in rows:
        rec = {c: str(row[idx[c]] if row[idx[c]] is not None else "") for c in cols}
        rec["implication"] = _implication(rec.get("status", ""), rec.get("artifact_ref"), rec.get("pr_url"))
        out.append(rec)
    return out


def write_rows_csv(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fields = [
        "app",
        "run_id",
        "item_id",
        "item_kind",
        "status",
        "implication",
        "artifact_ref",
        "pr_url",
        "notes",
        "processed_at",
    ]
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k, "") for k in fields})


def write_summary_csv(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    by_app_status: dict[tuple[str, str], int] = defaultdict(int)
    by_implication = Counter()
    for r in rows:
        by_app_status[(r.get("app", ""), r.get("status", ""))] += 1
        by_implication[r.get("implication", "OTHER")] += 1

    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["section", "key_1", "key_2", "count"])
        for (app, status), cnt in sorted(by_app_status.items()):
            w.writerow(["by_app_status", app, status, cnt])
        for imp, cnt in sorted(by_implication.items()):
            w.writerow(["by_implication", imp, "", cnt])


def _parse_processed_at(value: str) -> dt.datetime:
    # Databricks string casts usually look like "YYYY-MM-DD HH:MM:SS[.ffffff]".
    for fmt in ("%Y-%m-%d %H:%M:%S.%f", "%Y-%m-%d %H:%M:%S"):
        try:
            return dt.datetime.strptime(value, fmt)
        except ValueError:
            continue
    return dt.datetime.min


def latest_run_rows(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    latest_by_app: dict[str, tuple[dt.datetime, str]] = {}
    for r in rows:
        app = r.get("app", "")
        ts = _parse_processed_at(r.get("processed_at", ""))
        run_id = r.get("run_id", "")
        best = latest_by_app.get(app)
        if best is None or ts > best[0]:
            latest_by_app[app] = (ts, run_id)

    latest_ids = {app: run_id for app, (_, run_id) in latest_by_app.items()}
    return [r for r in rows if r.get("run_id", "") == latest_ids.get(r.get("app", ""), "")]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--since-hours", type=int, default=24, help="Lookback window for run-log rows")
    ap.add_argument("--limit", type=int, default=2000, help="Max merged rows to export")
    ap.add_argument("--out-dir", default=str(DEFAULT_OUT_DIR), help="Output directory for CSV reports")
    args = ap.parse_args()

    out_dir = Path(args.out_dir)
    rows_path = out_dir / "implications_rows.csv"
    summary_path = out_dir / "implications_summary.csv"
    rows_history_path = out_dir / "implications_rows_history.csv"
    summary_history_path = out_dir / "implications_summary_history.csv"
    rows_latest_path = out_dir / "implications_rows_latest_run.csv"
    summary_latest_path = out_dir / "implications_summary_latest_run.csv"

    rows = fetch_rows(since_hours=args.since_hours, limit=args.limit)
    latest_rows = latest_run_rows(rows)

    # Legacy/compat paths: keep writing full history here.
    write_rows_csv(rows_path, rows)
    write_summary_csv(summary_path, rows)
    # Explicit split outputs.
    write_rows_csv(rows_history_path, rows)
    write_summary_csv(summary_history_path, rows)
    write_rows_csv(rows_latest_path, latest_rows)
    write_summary_csv(summary_latest_path, latest_rows)

    print(f"rows={len(rows)}")
    print(f"latest_run_rows={len(latest_rows)}")
    print(f"rows_csv={rows_path}")
    print(f"summary_csv={summary_path}")
    print(f"rows_history_csv={rows_history_path}")
    print(f"summary_history_csv={summary_history_path}")
    print(f"rows_latest_csv={rows_latest_path}")
    print(f"summary_latest_csv={summary_latest_path}")
    blockers = sum(1 for r in latest_rows if r.get("implication") == "BLOCKER")
    actionable = sum(1 for r in latest_rows if r.get("implication") == "ACTIONABLE_CHANGE")
    print(f"latest_run_blockers={blockers} latest_run_actionable_changes={actionable}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
