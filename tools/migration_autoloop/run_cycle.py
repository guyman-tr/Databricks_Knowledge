#!/usr/bin/env python3
"""One unattended cycle: seed -> detect -> run N workers."""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.registry import load_manifest


def _run(cmd: list[str]) -> int:
    proc = subprocess.run(cmd, text=True)
    return proc.returncode


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--seed-csv", default="tools/migration_autoloop/seeds/adf_pipelines.csv")
    ap.add_argument("--registry-csv", default="tools/migration_autoloop/runtime/pipeline_registry.csv")
    ap.add_argument("--manifest-csv", default="tools/migration_autoloop/runtime/work_manifest.csv")
    ap.add_argument("--limit", type=int, default=3, help="Pipelines per cycle")
    ap.add_argument("--max-retry", type=int, default=3)
    ap.add_argument("--max-failures", type=int, default=2, help="Safety budget per cycle")
    ap.add_argument("--deploy-hook", default="", help="Forwarded to run_worker")
    ap.add_argument("--run-hook", default="", help="Forwarded to run_worker")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    seed_cmd = [
        sys.executable,
        "tools/migration_autoloop/seed_registry.py",
        "--seed-csv",
        args.seed_csv,
        "--registry-csv",
        args.registry_csv,
    ]
    print("== seed_registry ==")
    rc = _run(seed_cmd)
    if rc != 0:
        return rc

    detect_cmd = [
        sys.executable,
        "tools/migration_autoloop/detect_pending.py",
        "--registry-csv",
        args.registry_csv,
        "--manifest-csv",
        args.manifest_csv,
        "--limit",
        str(args.limit),
        "--max-retry",
        str(args.max_retry),
    ]
    print("== detect_pending ==")
    rc = _run(detect_cmd)
    if rc != 0:
        return rc

    manifest = load_manifest(Path(args.manifest_csv))
    if not manifest:
        print("Nothing pending. Done.")
        return 0

    failures = 0
    for row in manifest:
        cmd = [
            sys.executable,
            "tools/migration_autoloop/run_worker.py",
            "--manifest-csv",
            args.manifest_csv,
            "--registry-csv",
            args.registry_csv,
            "--pipeline-name",
            row.pipeline_name,
            "--max-retry",
            str(args.max_retry),
            "--deploy-hook",
            args.deploy_hook,
            "--run-hook",
            args.run_hook,
        ]
        if args.dry_run:
            cmd.append("--dry-run")
        print(f"== run_worker {row.pipeline_name} ==")
        rc = _run(cmd)
        if rc != 0:
            failures += 1
            if failures >= args.max_failures:
                print(f"Stopping: max_failures reached ({args.max_failures})")
                return 2

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

