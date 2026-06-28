#!/usr/bin/env python3
"""Monitor Databricks job run and notify via AgentMail on completion."""
from __future__ import annotations

import argparse
import datetime as dt
import json
import subprocess
import time


def _run(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, text=True)


def _latest_runs(job_id: int, profile: str) -> list[dict]:
    out = _run(
        [
            "databricks",
            "jobs",
            "list-runs",
            "--job-id",
            str(job_id),
            "--limit",
            "5",
            "--output",
            "json",
            "--profile",
            profile,
        ]
    )
    return json.loads(out)


def _get_run(run_id: int, profile: str) -> dict:
    out = _run(
        [
            "databricks",
            "jobs",
            "get-run",
            str(run_id),
            "--output",
            "json",
            "--profile",
            profile,
        ]
    )
    return json.loads(out)


def _notify(subject: str, body: str, status: str, to_addr: str) -> int:
    return subprocess.call(
        [
            "python",
            "tools/notify/notify.py",
            "--subject",
            subject,
            "--body",
            body,
            "--status",
            status,
            "--channel",
            "email",
            "--to",
            to_addr,
        ]
    )


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--job-id", type=int, required=True)
    ap.add_argument("--profile", default="guyman")
    ap.add_argument("--to", default="guyman@etoro.com")
    ap.add_argument("--poll-sec", type=int, default=30)
    args = ap.parse_args()

    started = dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    runs = _latest_runs(args.job_id, args.profile)

    active = None
    for r in runs:
        lc = ((r.get("state") or {}).get("life_cycle_state") or "")
        if lc not in {"TERMINATED", "SKIPPED", "INTERNAL_ERROR"}:
            active = r
            break
    if active is None and runs:
        active = runs[0]
    if active is None:
        _notify(
            "Fact_CustomerUnrealized monitor: no run",
            f"job_id={args.job_id}\nNo run found to monitor.",
            "warn",
            args.to,
        )
        return 0

    run_id = int(active["run_id"])
    while True:
        run = _get_run(run_id, args.profile)
        state = run.get("state") or {}
        lc = state.get("life_cycle_state") or ""
        rs = state.get("result_state") or ""
        msg = state.get("state_message") or ""
        if lc in {"TERMINATED", "SKIPPED", "INTERNAL_ERROR"}:
            ok = rs == "SUCCESS"
            status = "ok" if ok else "fail"
            subject = f"Fact_CustomerUnrealized run {run_id}: {lc}/{rs or 'n/a'}"
            body = "\n".join(
                [
                    f"job_id={args.job_id}",
                    f"run_id={run_id}",
                    f"life_cycle_state={lc}",
                    f"result_state={rs}",
                    f"state_message={msg}",
                    f"run_page_url={run.get('run_page_url', '')}",
                    f"monitored_since_utc={started}",
                ]
            )
            _notify(subject, body, status, args.to)
            return 0
        time.sleep(args.poll_sec)


if __name__ == "__main__":
    raise SystemExit(main())

