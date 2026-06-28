#!/usr/bin/env python3
"""POC E2E: parity prep + fact_guru_copiers block job."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def _run(cmd: list[str]) -> int:
    print("+", " ".join(cmd), flush=True)
    return subprocess.call(cmd, cwd=ROOT)


def main() -> int:
    steps = [
        [sys.executable, "tools/migration_autoloop/patch_guru_copiers_autopoc.py"],
        [sys.executable, "tools/migration_autoloop/runtime/prepare_guru_copiers_parity.py", "--apply"],
        [sys.executable, "tools/migration_autoloop/runtime/run_block_job.py", "--block-id", "fact_guru_copiers"],
    ]
    for cmd in steps:
        rc = _run(cmd)
        if rc != 0:
            return rc
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
