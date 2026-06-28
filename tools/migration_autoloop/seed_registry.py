#!/usr/bin/env python3
"""Create/update canonical pipeline registry from seed inventory."""
from __future__ import annotations

import argparse
import csv
from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.registry import RegistryRow, load_registry, save_registry


def read_seed(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        raise FileNotFoundError(f"seed file not found: {path}")
    with path.open("r", encoding="utf-8", newline="") as fh:
        return list(csv.DictReader(fh))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--seed-csv",
        default="tools/migration_autoloop/seeds/adf_pipelines.csv",
        help="ADF pipeline seed CSV (pipeline_name,source,notes)",
    )
    ap.add_argument(
        "--registry-csv",
        default="tools/migration_autoloop/runtime/pipeline_registry.csv",
        help="Canonical status registry CSV",
    )
    ap.add_argument(
        "--reset-status",
        action="store_true",
        help="Reset all seeded rows to status=pending and retry_count=0.",
    )
    args = ap.parse_args()

    seed_path = Path(args.seed_csv)
    registry_path = Path(args.registry_csv)
    seed_rows = read_seed(seed_path)
    registry = load_registry(registry_path)

    added = 0
    updated = 0
    for item in seed_rows:
        name = (item.get("pipeline_name") or "").strip()
        if not name:
            continue
        source = (item.get("source") or "seed").strip()
        notes = (item.get("notes") or "").strip()

        existing = registry.get(name)
        if existing is None:
            registry[name] = RegistryRow(
                pipeline_name=name,
                source=source,
                status="pending",
                notes=notes,
            )
            added += 1
            continue

        if args.reset_status:
            existing.status = "pending"
            existing.retry_count = 0
            existing.last_error = ""
            existing.last_run_id = ""
            existing.evidence_path = ""
        if source:
            existing.source = source
        if notes:
            existing.notes = notes
        updated += 1

    save_registry(registry_path, registry.values())
    print(
        f"registry={registry_path} seeded={len(seed_rows)} added={added} updated={updated} total={len(registry)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

