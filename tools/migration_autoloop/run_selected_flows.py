#!/usr/bin/env python3
"""Run the currently selected three candidate autoloop flows."""
from __future__ import annotations

import argparse
import datetime as dt
import json
import subprocess
import sys
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[2]))


def _target_date(value: str) -> str:
    if value.strip():
        return value.strip()
    return (dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)).isoformat()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--target-date", default="", help="YYYY-MM-DD. Default: yesterday UTC.")
    ap.add_argument(
        "--selection-json",
        default="tools/migration_autoloop/out/adf_candidate_flows.json",
        help="Candidate selection artifact from map_adf_dependencies.py",
    )
    ap.add_argument(
        "--summary-json",
        default="tools/migration_autoloop/out/selected_flows_run_summary.json",
    )
    ap.add_argument(
        "--summary-md",
        default="tools/migration_autoloop/out/selected_flows_run_summary.md",
    )
    args = ap.parse_args()

    target_date = _target_date(args.target_date)
    selection = json.loads(Path(args.selection_json).read_text(encoding="utf-8"))
    selected = selection.get("selected_candidates", [])
    run_script = Path("tools/migration_autoloop/run_flow_autoloop_report.py")

    results: list[dict[str, object]] = []
    for row in selected:
        flow_id = str(row["flow_id"])
        out_json = f"tools/migration_autoloop/out/{flow_id}_trust_report_{target_date}.json"
        out_md = f"tools/migration_autoloop/out/{flow_id}_trust_report_{target_date}.md"
        cmd = [sys.executable, str(run_script), "--flow-id", flow_id, "--target-date", target_date, "--out-json", out_json, "--out-md", out_md]
        proc = subprocess.run(cmd, capture_output=True, text=True)
        rec: dict[str, object] = {
            "flow_id": flow_id,
            "return_code": proc.returncode,
            "stdout": proc.stdout.strip(),
            "stderr": proc.stderr.strip(),
            "report_json": out_json,
            "report_md": out_md,
        }
        if Path(out_json).exists():
            payload = json.loads(Path(out_json).read_text(encoding="utf-8"))
            rec["qa_pass_migration_vs_gold"] = bool(payload.get("qa_pass_migration_vs_gold"))
            rec["databricks_job_state"] = payload.get("databricks_job_state")
            rec["migration_vs_gold"] = payload.get("migration_vs_gold")
            rec["post_migration_vs_synapse"] = payload.get("post_migration_vs_synapse")
        results.append(rec)

    summary = {
        "target_date": target_date,
        "selection_json": args.selection_json,
        "selected_flow_ids": [str(r["flow_id"]) for r in selected],
        "results": results,
    }
    Path(args.summary_json).write_text(json.dumps(summary, indent=2), encoding="utf-8")

    lines = ["# Selected Flows Run Summary", "", f"- Target date: `{target_date}`", ""]
    for rec in results:
        lines.extend(
            [
                f"## {rec['flow_id']}",
                f"- Return code: `{rec['return_code']}`",
                f"- QA pass (migration vs gold): `{rec.get('qa_pass_migration_vs_gold')}`",
                f"- Databricks job state: `{rec.get('databricks_job_state')}`",
                f"- Report JSON: `{rec['report_json']}`",
                f"- Report MD: `{rec['report_md']}`",
                "",
            ]
        )
    Path(args.summary_md).write_text("\n".join(lines), encoding="utf-8")

    print(json.dumps({"summary_json": args.summary_json, "summary_md": args.summary_md}, indent=2))
    all_pass = all(bool(r.get("qa_pass_migration_vs_gold")) for r in results) if results else False
    return 0 if all_pass else 2


if __name__ == "__main__":
    raise SystemExit(main())
