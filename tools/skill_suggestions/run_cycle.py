#!/usr/bin/env python3
"""Single-command autonomous cycle: scan queue then process manifest."""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path


def _run(cmd: list[str]) -> int:
    proc = subprocess.run(cmd, text=True)
    return proc.returncode


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--status", default="new", help="Queue status to scan")
    ap.add_argument("--limit", type=int, default=25, help="Max rows to scan")
    ap.add_argument("--claim", action="store_true", default=True, help="Claim rows during scan")
    ap.add_argument(
        "--skip-scan",
        action="store_true",
        help="Skip scan stage and run directly from existing --manifest file.",
    )
    ap.add_argument(
        "--manifest",
        default="tools/skill_suggestions/work_manifest.json",
        help="Manifest output path and run_once input path",
    )
    ap.add_argument("--dry-run", action="store_true", help="Run process stage in dry-run mode")
    ap.add_argument(
        "--execution-mode",
        choices=["full", "ingest_only"],
        default="full",
        help="Forwarded to run_once",
    )
    ap.add_argument("--no-status-update", action="store_true")
    ap.add_argument("--no-notify", action="store_true")
    ap.add_argument("--stop-on-error", action="store_true")
    ap.add_argument("--auto-stash-dataplatform", action="store_true")
    ap.add_argument("--workspace-cwd", default=".")
    args = ap.parse_args()

    manifest_path = Path(args.manifest)
    manifest_path.parent.mkdir(parents=True, exist_ok=True)

    if not args.skip_scan:
        scan_cmd = [
            sys.executable,
            "tools/skill_suggestions/scan.py",
            "--status",
            args.status,
            "--limit",
            str(args.limit),
            "--output",
            str(manifest_path),
        ]
        if args.claim:
            scan_cmd.append("--claim")

        print("== scan ==")
        rc = _run(scan_cmd)
        if rc != 0:
            return rc
    elif not manifest_path.exists():
        raise SystemExit(f"--skip-scan set but manifest does not exist: {manifest_path}")

    run_cmd = [
        sys.executable,
        "tools/skill_suggestions/run_once.py",
        "--manifest",
        str(manifest_path),
        "--execution-mode",
        args.execution_mode,
        "--workspace-cwd",
        args.workspace_cwd,
    ]
    if args.dry_run:
        run_cmd.append("--dry-run")
    if args.no_status_update:
        run_cmd.append("--no-status-update")
    if args.no_notify:
        run_cmd.append("--no-notify")
    if args.stop_on_error:
        run_cmd.append("--stop-on-error")
    if args.auto_stash_dataplatform:
        run_cmd.append("--auto-stash-dataplatform")

    # Inherit timeout env if caller set it.
    os.environ.setdefault("CURSOR_AGENT_TIMEOUT_SECONDS", "180")

    print("== run_once ==")
    return _run(run_cmd)


if __name__ == "__main__":
    sys.exit(main())
