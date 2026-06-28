#!/usr/bin/env python3
"""Update status fields for a skill suggestion row."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.skill_suggestions.db import execute_sql, make_workspace_client, warehouse_id_from_env


TABLE_FQN = "main.de_output.de_output_skills_automation_user_suggestions_agent"
ALLOWED_STATUS = {"new", "processing", "pushed", "skipped_overlap", "error"}


def _sql_quote(value: str) -> str:
    return value.replace("'", "''")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--id", required=True, help="Submission row id")
    ap.add_argument("--status", required=True, help="new|processing|pushed|skipped_overlap|error")
    ap.add_argument("--pr-url", default=None, help="PR URL to store")
    ap.add_argument("--agent-notes", default=None, help="Status notes to append")
    ap.add_argument(
        "--set-processed-now",
        action="store_true",
        help="Set processed_at = current_timestamp()",
    )
    args = ap.parse_args()

    if args.status not in ALLOWED_STATUS:
        raise SystemExit(f"invalid --status: {args.status}")

    assignments = [f"status = '{_sql_quote(args.status)}'"]
    if args.pr_url is not None:
        assignments.append(f"pr_url = '{_sql_quote(args.pr_url)}'")
    if args.agent_notes is not None:
        assignments.append(
            f"agent_notes = CONCAT(COALESCE(agent_notes, ''), '\\n', '{_sql_quote(args.agent_notes)}')"
        )
    if args.set_processed_now:
        assignments.append("processed_at = current_timestamp()")

    sql_text = f"""
UPDATE {TABLE_FQN}
SET {", ".join(assignments)}
WHERE id = '{_sql_quote(args.id)}'
""".strip()

    w = make_workspace_client()
    execute_sql(w, sql_text=sql_text, warehouse_id=warehouse_id_from_env())
    print("ok")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
