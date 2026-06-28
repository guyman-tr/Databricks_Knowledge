#!/usr/bin/env python3
"""Run one migration unit from the manifest and update registry atomically."""
from __future__ import annotations

import argparse
import json
import shlex
import subprocess
import uuid
from dataclasses import asdict
from pathlib import Path
from typing import Any

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env
from tools.migration_autoloop.memory_bank import append_memory_event
from tools.migration_autoloop.registry import RegistryRow, load_manifest, load_registry, now_utc_iso, save_registry


def _sql_quote(value: str) -> str:
    return value.replace("'", "''")


def load_pipeline_tables(map_csv: Path, pipeline_name: str) -> list[str]:
    if not map_csv.exists():
        return []
    import csv

    out: list[str] = []
    with map_csv.open("r", encoding="utf-8", newline="") as fh:
        reader = csv.DictReader(fh)
        for row in reader:
            if (row.get("pipeline_name") or "").strip() != pipeline_name:
                continue
            table_name = (row.get("uc_table") or "").strip()
            if table_name:
                out.append(table_name)
    return sorted(set(out))


def fetch_active_tables(w: Any, warehouse_id: str) -> list[str]:
    sql = """
SELECT migration_table_name
FROM dwh_daily_process.qa.gold_phase_table_mapping
WHERE is_active = 1
ORDER BY migration_table_name
""".strip()
    cols, rows = execute_sql(w, sql_text=sql, warehouse_id=warehouse_id)
    if not cols:
        return []
    idx = cols.index("migration_table_name")
    return [str(r[idx]) for r in rows if r[idx]]


def fetch_latest_qa_status(
    w: Any,
    warehouse_id: str,
    uc_tables: list[str],
) -> dict[str, Any]:
    if not uc_tables:
        return {"compared_count": 0, "mismatch_count": 0, "error_count": 0, "rows": []}

    in_clause = ", ".join(f"'{_sql_quote(t)}'" for t in uc_tables)
    sql = f"""
WITH ranked AS (
  SELECT
    uc_table,
    synapse_table,
    gold_table,
    status,
    insert_date,
    ROW_NUMBER() OVER (PARTITION BY uc_table ORDER BY insert_date DESC) AS rn
  FROM dwh_daily_process.qa.gold_phase_comparison
  WHERE uc_table IN ({in_clause})
)
SELECT uc_table, synapse_table, gold_table, status, insert_date
FROM ranked
WHERE rn = 1
ORDER BY uc_table
""".strip()
    cols, rows = execute_sql(w, sql_text=sql, warehouse_id=warehouse_id)
    items: list[dict[str, Any]] = []
    for row in rows:
        item = {cols[i]: row[i] for i in range(min(len(cols), len(row)))}
        items.append(item)

    mismatch_count = sum(1 for r in items if str(r.get("status", "")).lower() == "mismatch")
    error_count = sum(1 for r in items if str(r.get("status", "")).lower() == "error")
    return {
        "compared_count": len(items),
        "mismatch_count": mismatch_count,
        "error_count": error_count,
        "rows": items,
    }


def run_shell_hook(command: str, pipeline_name: str, dry_run: bool) -> tuple[bool, str]:
    if not command.strip():
        return True, "no command configured"
    rendered = command.replace("{pipeline_name}", pipeline_name)
    if dry_run:
        return True, f"dry-run skipped: {rendered}"
    proc = subprocess.run(shlex.split(rendered), text=True, capture_output=True)
    if proc.returncode == 0:
        return True, (proc.stdout or "ok").strip()[:2000]
    err = (proc.stderr or proc.stdout or "unknown failure").strip()
    return False, err[:2000]


def write_evidence(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False, default=str), encoding="utf-8")


def write_inbox(path: Path, pipeline_name: str, reason: str, evidence_path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    text = (
        f"# Migration Autoloop Escalation\n\n"
        f"- Pipeline: `{pipeline_name}`\n"
        f"- Reason: `{reason}`\n"
        f"- Evidence: `{evidence_path}`\n"
    )
    path.write_text(text, encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--manifest-csv",
        default="tools/migration_autoloop/runtime/work_manifest.csv",
        help="Manifest emitted by detect_pending.py",
    )
    ap.add_argument(
        "--registry-csv",
        default="tools/migration_autoloop/runtime/pipeline_registry.csv",
        help="Canonical status registry CSV",
    )
    ap.add_argument(
        "--pipeline-table-map-csv",
        default="tools/migration_autoloop/seeds/pipeline_table_map.csv",
        help="Optional pipeline->UC table map (pipeline_name,uc_table).",
    )
    ap.add_argument(
        "--memory-bank-csv",
        default="tools/migration_autoloop/runtime/memory_bank.csv",
        help="CSV memory bank of recurring failures/fixes.",
    )
    ap.add_argument(
        "--pipeline-name",
        default="",
        help="Specific pipeline to process. Default: first row in manifest.",
    )
    ap.add_argument("--max-retry", type=int, default=3, help="Retry budget before escalation")
    ap.add_argument(
        "--deploy-hook",
        default="",
        help="Optional shell command for transpile/deploy stage. Supports {pipeline_name}.",
    )
    ap.add_argument(
        "--run-hook",
        default="",
        help="Optional shell command for runtime execution stage. Supports {pipeline_name}.",
    )
    ap.add_argument("--dry-run", action="store_true", help="Skip shell hooks; still query QA tables.")
    args = ap.parse_args()

    manifest_rows = load_manifest(Path(args.manifest_csv))
    if not manifest_rows:
        raise SystemExit(f"empty manifest: {args.manifest_csv}")

    target = None
    if args.pipeline_name:
        for row in manifest_rows:
            if row.pipeline_name == args.pipeline_name:
                target = row
                break
        if target is None:
            raise SystemExit(f"pipeline not found in manifest: {args.pipeline_name}")
    else:
        target = manifest_rows[0]

    registry_path = Path(args.registry_csv)
    registry = load_registry(registry_path)
    reg_row = registry.get(target.pipeline_name)
    if reg_row is None:
        reg_row = target
        registry[target.pipeline_name] = reg_row

    run_id = f"migration-autoloop-{uuid.uuid4().hex[:10]}"
    reg_row.status = "processing"
    reg_row.last_run_id = run_id
    reg_row.last_checked_at = now_utc_iso()
    save_registry(registry_path, registry.values())

    deploy_ok, deploy_msg = run_shell_hook(args.deploy_hook, reg_row.pipeline_name, args.dry_run)
    run_ok, run_msg = (False, "deploy stage failed")
    if deploy_ok:
        run_ok, run_msg = run_shell_hook(args.run_hook, reg_row.pipeline_name, args.dry_run)

    w = make_workspace_client()
    warehouse_id = warehouse_id_from_env()
    mapped_tables = load_pipeline_tables(Path(args.pipeline_table_map_csv), reg_row.pipeline_name)
    if not mapped_tables:
        mapped_tables = fetch_active_tables(w, warehouse_id)

    qa = fetch_latest_qa_status(w, warehouse_id, mapped_tables)
    compared = int(qa["compared_count"])
    mismatch = int(qa["mismatch_count"])
    errors = int(qa["error_count"])

    final_status = "done"
    final_error = ""
    if not deploy_ok:
        final_status = "blocked"
        final_error = f"deploy_hook_failed: {deploy_msg}"
    elif not run_ok:
        final_status = "blocked"
        final_error = f"run_hook_failed: {run_msg}"
    elif compared == 0:
        final_status = "blocked"
        final_error = "qa_parity_no_rows"
    elif mismatch > 0 or errors > 0:
        final_status = "qa_failed"
        final_error = f"qa_mismatch={mismatch} qa_error={errors}"

    reg_row.status = final_status
    reg_row.last_checked_at = now_utc_iso()
    reg_row.last_error = final_error
    reg_row.last_qa_compared_count = compared
    reg_row.last_qa_mismatch_count = mismatch
    reg_row.last_qa_error_count = errors
    if final_status in {"blocked", "qa_failed"}:
        reg_row.retry_count += 1

    evidence_path = Path(
        "tools/migration_autoloop/runtime/evidence"
    ) / f"{run_id}_{reg_row.pipeline_name.replace('/', '_').replace(' ', '_')}.json"
    evidence = {
        "run_id": run_id,
        "pipeline": reg_row.pipeline_name,
        "deploy_hook": {"ok": deploy_ok, "message": deploy_msg},
        "run_hook": {"ok": run_ok, "message": run_msg},
        "qa_summary": qa,
        "mapped_tables": mapped_tables,
        "registry_row": asdict(reg_row),
    }
    write_evidence(evidence_path, evidence)
    reg_row.evidence_path = str(evidence_path)

    if reg_row.retry_count >= args.max_retry and reg_row.status in {"blocked", "qa_failed"}:
        inbox_name = f"{run_id}_{reg_row.pipeline_name.replace('/', '_').replace(' ', '_')}.md"
        inbox_path = Path("tools/migration_autoloop/runtime/inbox") / inbox_name
        write_inbox(inbox_path, reg_row.pipeline_name, reg_row.last_error, evidence_path)
        reg_row.notes = f"escalated:{inbox_path}"

    save_registry(registry_path, registry.values())

    raw_error_text = final_error
    if final_status == "blocked":
        raw_error_text = " | ".join(x for x in [final_error, deploy_msg, run_msg] if x)
    if not raw_error_text:
        raw_error_text = "run_success"
    append_memory_event(
        Path(args.memory_bank_csv),
        event_ts=now_utc_iso(),
        run_id=run_id,
        pipeline_name=reg_row.pipeline_name,
        status=reg_row.status,
        raw_error_text=raw_error_text,
        retry_count=reg_row.retry_count,
        qa_compared_count=compared,
        qa_mismatch_count=mismatch,
        qa_error_count=errors,
        evidence_path=str(evidence_path),
    )

    print(
        json.dumps(
            {
                "run_id": run_id,
                "pipeline": reg_row.pipeline_name,
                "status": reg_row.status,
                "retry_count": reg_row.retry_count,
                "qa_compared": compared,
                "qa_mismatch": mismatch,
                "qa_error": errors,
                "evidence_path": str(evidence_path),
            },
            indent=2,
        )
    )
    return 0 if reg_row.status == "done" else 2


if __name__ == "__main__":
    raise SystemExit(main())

