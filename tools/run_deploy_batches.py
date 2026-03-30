"""
Loop deploy for ANY schema in small chunks (default 5 objects) so each batch
finishes quickly and the terminal gives a clear "batch done" signal.

Replaces run_dwh_dbo_deploy_batches.py (hardcoded to DWH_dbo).

Usage (from repo root):
  python tools/run_deploy_batches.py --schema DWH_dbo
  python tools/run_deploy_batches.py --schema eMoney_dbo --batch-size 10 -v
  python tools/run_deploy_batches.py --schema Dealing_dbo --start-batch 5 --max-seconds-per-batch 900

Stops when there are no | Generated | rows left in _deploy-index.md.
Exits non-zero if a child batch fails or times out.
"""
from __future__ import annotations

import argparse
import importlib.util
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
DEPLOY_SCRIPT = REPO / "tools" / "deploy_alter_batch.py"

_DEPLOY_MOD = None


def _load_deploy_module():
    global _DEPLOY_MOD
    if _DEPLOY_MOD is not None:
        return _DEPLOY_MOD
    spec = importlib.util.spec_from_file_location("deploy_alter_batch", DEPLOY_SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load {DEPLOY_SCRIPT}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    _DEPLOY_MOD = mod
    return mod


def _parse_generated_count(schema: str) -> int:
    mod = _load_deploy_module()
    di = REPO / "knowledge" / "synapse" / "Wiki" / schema / "_deploy-index.md"
    if not di.is_file():
        return 0
    return len(mod.parse_generated_objects(di, schema))


def _signal_batch_done(batch_num: int, elapsed_s: float, no_beep: bool) -> None:
    bar = "=" * 72
    print(f"\n{bar}", flush=True)
    print(f"  BATCH {batch_num} FINISHED  ({elapsed_s:.1f}s)", flush=True)
    print(f"{bar}\n", flush=True)
    if not no_beep:
        print("\a", end="", flush=True)
        try:
            import winsound
            winsound.MessageBeep(winsound.MB_ICONASTERISK)
        except (ImportError, OSError):
            pass


def main() -> None:
    ap = argparse.ArgumentParser(description="Loop ALTER deploy in small batches for any schema.")
    ap.add_argument("--schema", required=True, help="Schema folder name (e.g. DWH_dbo, eMoney_dbo)")
    ap.add_argument("--batch-size", type=int, default=5, help="Objects per batch (default 5)")
    ap.add_argument("--start-batch", type=int, default=1, help="First --deploy-batch value (increments each loop)")
    ap.add_argument("--fixed-batch", type=int, default=None, metavar="N",
                     help="Pass the same --deploy-batch N every iteration")
    ap.add_argument("--max-seconds-per-batch", type=int, default=0, metavar="SEC",
                     help="Kill child if it runs longer than SEC (0 = no timeout)")
    ap.add_argument("--no-beep", action="store_true", help="Disable terminal bell")
    ap.add_argument("-v", "--verbose", action="store_true", help="Pass -v to deploy script")
    ap.add_argument("--pause-seconds", type=float, default=2.0,
                     help="Sleep after each batch (default 2)")
    args = ap.parse_args()

    if not DEPLOY_SCRIPT.is_file():
        print(f"Missing {DEPLOY_SCRIPT}", file=sys.stderr)
        sys.exit(1)

    batch_num = args.start_batch
    loop = 0

    while True:
        remaining = _parse_generated_count(args.schema)
        if remaining == 0:
            print(f"=== No Generated rows left in {args.schema}/_deploy-index.md — done. ===")
            sys.exit(0)

        deploy_batch = args.fixed_batch if args.fixed_batch is not None else batch_num
        loop += 1
        print(
            f"\n>>> Loop {loop}: {remaining} Generated remaining — "
            f"running --schema {args.schema} batch-size={args.batch_size} deploy-batch={deploy_batch} <<<\n",
            flush=True,
        )

        cmd = [
            sys.executable,
            str(DEPLOY_SCRIPT),
            "--schema", args.schema,
            "--batch-size", str(args.batch_size),
            "--deploy-batch", str(deploy_batch),
        ]
        if args.verbose:
            cmd.append("-v")

        t0 = time.perf_counter()
        try:
            r = subprocess.run(
                cmd,
                cwd=str(REPO),
                timeout=args.max_seconds_per_batch if args.max_seconds_per_batch > 0 else None,
            )
        except subprocess.TimeoutExpired:
            print(
                f"\nERROR: Batch exceeded --max-seconds-per-batch ({args.max_seconds_per_batch}s).",
                file=sys.stderr,
            )
            sys.exit(124)

        elapsed = time.perf_counter() - t0
        if r.returncode != 0:
            print(f"\nERROR: deploy script exited {r.returncode}", file=sys.stderr)
            sys.exit(r.returncode)

        _signal_batch_done(deploy_batch, elapsed, args.no_beep)
        if args.fixed_batch is None:
            batch_num += 1

        if args.pause_seconds > 0:
            time.sleep(args.pause_seconds)


if __name__ == "__main__":
    main()
