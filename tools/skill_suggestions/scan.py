#!/usr/bin/env python3
"""Scan the skill suggestion queue and emit a JSON work manifest."""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.skill_suggestions.db import execute_sql, make_workspace_client, warehouse_id_from_env


TABLE_FQN = "main.de_output.de_output_skills_automation_user_suggestions_agent"


def _sql_quote(value: str) -> str:
    return value.replace("'", "''")


def _rows_to_dicts(columns: list[str], rows: list[list[Any]]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for row in rows:
        item = {columns[i]: row[i] for i in range(min(len(columns), len(row)))}
        out.append(item)
    return out


def _safe_component(text: str) -> str:
    return re.sub(r"[^a-zA-Z0-9._-]+", "_", text)


def _download_volume_prefix(
    *,
    row: dict[str, Any],
    output_root: Path,
    profile: str | None,
) -> str | None:
    """
    Best-effort helper:
    - If volume_path is already local, return it.
    - If path starts with /Volumes, recursively download payload files to local mirror path.
    This keeps the manifest deterministic and executable by run_once.py.
    """
    raw = row.get("volume_path")
    if not raw:
        return None
    vp = str(raw)
    if vp.startswith("/Volumes/"):
        row_id = str(row.get("id") or "unknown")
        target = output_root / "payloads" / _safe_component(row_id)
        if target.exists():
            shutil.rmtree(target)
        target.mkdir(parents=True, exist_ok=True)
        src = f"dbfs:{vp.rstrip('/')}/"
        cmd = [
            "databricks",
            "fs",
            "cp",
            src,
            str(target),
            "--recursive",
            "--overwrite",
        ]
        if profile:
            cmd.extend(["--profile", profile])
        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            raise RuntimeError(
                f"volume payload download failed for {row_id}: {(proc.stderr or proc.stdout).strip()}"
            )
        return str(target)
    if Path(vp).exists():
        return vp
    return vp


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--status", default="new", help="Queue status to scan (default: new)")
    ap.add_argument("--limit", type=int, default=25, help="Max rows to scan")
    ap.add_argument(
        "--profile",
        default=None,
        help="Databricks profile override (otherwise resolved from env/default logic).",
    )
    ap.add_argument(
        "--claim",
        action="store_true",
        help="Claim rows by setting status=processing when currently status=new",
    )
    ap.add_argument(
        "--output",
        default="tools/skill_suggestions/work_manifest.json",
        help="Manifest output path",
    )
    args = ap.parse_args()

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    w = make_workspace_client(profile=args.profile)
    warehouse_id = warehouse_id_from_env()
    status = _sql_quote(args.status)
    scan_sql = f"""
SELECT
  id,
  submitted_at,
  submitter,
  request_type,
  target_skill,
  title,
  body_text,
  volume_path,
  status,
  pr_url,
  processed_at,
  agent_notes
FROM {TABLE_FQN}
WHERE status = '{status}'
ORDER BY submitted_at ASC
LIMIT {int(args.limit)}
""".strip()

    cols, rows = execute_sql(w, sql_text=scan_sql, warehouse_id=warehouse_id)
    items = _rows_to_dicts(cols, rows)

    claimed_ids: list[str] = []
    if args.claim:
        for item in items:
            row_id = str(item.get("id"))
            if not row_id:
                continue
            claim_sql = f"""
UPDATE {TABLE_FQN}
SET status = 'processing',
    agent_notes = CONCAT(COALESCE(agent_notes, ''), '\\n[scan] claimed for processing')
WHERE id = '{_sql_quote(row_id)}'
  AND status = 'new'
""".strip()
            execute_sql(w, sql_text=claim_sql, warehouse_id=warehouse_id)
            claimed_ids.append(row_id)

    output_root = output_path.parent
    manifest = {
        "table": TABLE_FQN,
        "status_filter": args.status,
        "claimed": args.claim,
        "count": len(items),
        "claimed_ids": claimed_ids,
        "items": [],
    }
    for item in items:
        item["local_payload_path"] = _download_volume_prefix(
            row=item,
            output_root=output_root,
            profile=args.profile,
        )
        manifest["items"].append(item)

    output_path.write_text(json.dumps(manifest, indent=2, default=str), encoding="utf-8")
    print(str(output_path))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
