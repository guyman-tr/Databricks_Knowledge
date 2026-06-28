#!/usr/bin/env python3
"""Emit work manifest of pipelines whose status != done."""
from __future__ import annotations

import argparse
from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.registry import RegistryRow, load_registry, write_manifest

PRIORITY = {"pending": 0, "qa_failed": 1, "blocked": 2, "processing": 3, "done": 9}


def eligible(row: RegistryRow, max_retry: int) -> bool:
    if row.status == "done":
        return False
    if row.retry_count >= max_retry and row.status in {"blocked", "qa_failed"}:
        return False
    return True


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--registry-csv",
        default="tools/migration_autoloop/runtime/pipeline_registry.csv",
        help="Canonical status registry CSV",
    )
    ap.add_argument(
        "--manifest-csv",
        default="tools/migration_autoloop/runtime/work_manifest.csv",
        help="Output manifest CSV",
    )
    ap.add_argument("--limit", type=int, default=10, help="Max pipelines to emit")
    ap.add_argument("--max-retry", type=int, default=3, help="Retry budget")
    args = ap.parse_args()

    registry = load_registry(Path(args.registry_csv))
    rows = [row for row in registry.values() if eligible(row, args.max_retry)]
    rows.sort(key=lambda r: (PRIORITY.get(r.status, 8), r.retry_count, r.pipeline_name.lower()))
    if args.limit > 0:
        rows = rows[: args.limit]

    write_manifest(Path(args.manifest_csv), rows)
    print(f"manifest={args.manifest_csv} count={len(rows)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

