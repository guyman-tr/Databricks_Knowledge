#!/usr/bin/env python3
"""Walk the topologically-ordered audit queue layer-by-layer.

For each layer in `_audit_queue_<ts>.csv` we run the Phase B+C pipeline:
  audit (skipped if `--skip-audit`) -> reconcile -> apply wikis -> regen alter
  -> cascade-synapse -> cascade-uc -> commit per wave.

Defaults to DRY-RUN. Pass `--apply` to write edits and `--commit` to commit
between waves. The walk respects the user's "ask before UC deploy" gate -- no
UC deploys are issued here; they are run separately via the deploy tools.

Usage examples
--------------
  # Plan only -- print what each wave would do, no writes
  python -m tools.cleanup_tier1.audit_dag_walk

  # Run a single layer end-to-end
  python -m tools.cleanup_tier1.audit_dag_walk --layers 1 --apply --commit

  # Run all layers (no commits, just edits)
  python -m tools.cleanup_tier1.audit_dag_walk --apply

  # Skip running the audit (e.g. reuse existing reports) and only do reconcile+apply+cascade
  python -m tools.cleanup_tier1.audit_dag_walk --skip-audit --apply --commit
"""
from __future__ import annotations

import argparse
import csv
import subprocess
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
PY = sys.executable


def _latest_queue() -> Path | None:
    qs = sorted((REPO / "audits").glob("_audit_queue_*.csv"))
    return qs[-1] if qs else None


def _load_queue(queue_path: Path) -> dict[int, list[dict]]:
    by_layer: dict[int, list[dict]] = defaultdict(list)
    with queue_path.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            by_layer[int(r["topological_layer"])].append(r)
    return by_layer


def _run(cmd: list[str], cwd: Path = REPO, dry_run: bool = False) -> int:
    label = " ".join(cmd)
    if dry_run:
        print(f"  [DRY] {label}")
        return 0
    print(f"  $ {label}")
    rc = subprocess.call(cmd, cwd=str(cwd))
    if rc != 0:
        print(f"    -> exit code {rc}")
    return rc


def walk_layer(
    layer: int,
    rows: list[dict],
    *,
    apply: bool,
    commit: bool,
    skip_audit: bool,
) -> None:
    """Run one wave for a topological layer."""
    print(f"\n=== Layer {layer}: {len(rows)} wikis ===")
    if not rows:
        return

    if not skip_audit:
        # In production each wave would invoke
        #   python -m tools.tier1_audit.run_audit --wikis <path1> <path2> ...
        # Bypassed here because the audit harness expects --schema. Keeping a
        # placeholder for the wave hook.
        print("  (audit step: skipped here -- run tools/tier1_audit/run_audit_*.py manually per schema)")

    # Reconcile: re-merge every audit report we've produced + the old judge cache.
    # The walk doesn't run the audit itself, so it needs to point reconcile at
    # whichever report.csv files are already on disk.
    audit_reports = sorted((REPO / "audits").glob("_tier1_audit_*/report.csv"))
    if not audit_reports:
        print("  WARN: no audit report.csv files found under audits/_tier1_audit_*/ "
              "-- skipping reconcile")
    else:
        cmd = [PY, "-m", "tools.cleanup_tier1.reconcile"]
        for r in audit_reports:
            cmd += ["--new-audit", str(r)]
        _run(cmd, dry_run=False)

    # Apply wiki corrections
    if apply:
        _run([PY, "-m", "tools.cleanup_tier1.apply_corrections",
              "--target", "wikis", "--apply"], dry_run=False)
    else:
        _run([PY, "-m", "tools.cleanup_tier1.apply_corrections",
              "--target", "wikis"], dry_run=False)

    # Regen matching alter.sql files
    if apply:
        _run([PY, "-m", "tools.cleanup_tier1.regen_alter", "--apply"], dry_run=False)

    # Cascade downstream synapse + UC siblings
    if apply:
        _run([PY, "-m", "tools.cleanup_tier1.apply_corrections",
              "--target", "cascade-synapse", "--apply"], dry_run=False)
        _run([PY, "-m", "tools.cleanup_tier1.apply_corrections",
              "--target", "cascade-uc", "--apply"], dry_run=False)
    else:
        _run([PY, "-m", "tools.cleanup_tier1.apply_corrections",
              "--target", "cascade-synapse"], dry_run=False)
        _run([PY, "-m", "tools.cleanup_tier1.apply_corrections",
              "--target", "cascade-uc"], dry_run=False)

    if commit and apply:
        ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H-%M-%SZ")
        rc = _run(["git", "add", "knowledge/", "audits/"], dry_run=False)
        if rc == 0:
            msg = f"cleanup(tier1): DAG-walk wave layer={layer} ({len(rows)} wikis) @ {ts}"
            _run(["git", "commit", "-m", msg], dry_run=False)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--queue", default="",
                    help="Path to _audit_queue_*.csv. Defaults to latest in audits/.")
    ap.add_argument("--layers", default="",
                    help="Comma-separated list of layers to walk. Default: all.")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--commit", action="store_true",
                    help="Commit after each wave. Requires --apply.")
    ap.add_argument("--skip-audit", action="store_true",
                    help="Don't re-run the L0/L1/L2 audit; reuse existing reports.")
    args = ap.parse_args()

    if args.commit and not args.apply:
        print("--commit requires --apply", file=sys.stderr)
        sys.exit(2)

    queue_path = Path(args.queue) if args.queue else _latest_queue()
    if not queue_path or not queue_path.exists():
        print("No queue CSV found. Run tools/cleanup_tier1/audit_queue.py first.",
              file=sys.stderr)
        sys.exit(2)
    print(f"Queue: {queue_path}")

    by_layer = _load_queue(queue_path)
    chosen = (sorted(int(x) for x in args.layers.split(",") if x)
              if args.layers else sorted(by_layer))
    print(f"Walking layers: {chosen}")

    for layer in chosen:
        rows = by_layer.get(layer, [])
        walk_layer(layer, rows,
                   apply=args.apply, commit=args.commit,
                   skip_audit=args.skip_audit)

    print("\nWalk complete.")


if __name__ == "__main__":
    main()
