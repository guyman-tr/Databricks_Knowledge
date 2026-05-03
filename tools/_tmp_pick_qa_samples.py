"""Pick a handful of UC targets from bronze deploy-index files for QA."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path("knowledge/ProdSchemas")

# Capture: object name, uc_target, status. uc_target is in backticks like `main.dwh.foo`.
ROW = re.compile(
    r"^\|\s*\[([^\]]+)\]\([^)]+\)\s*\|\s*`([^`]+)`\s*\|\s*([^|]+?)\s*\|"
)


def list_indices() -> list[Path]:
    return sorted(ROOT.rglob("_deploy-index.md"))


def deployed_targets(idx: Path) -> list[tuple[str, str]]:
    out: list[tuple[str, str]] = []
    for line in idx.read_text(encoding="utf-8").splitlines():
        m = ROW.match(line)
        if not m:
            continue
        name, target, status = m.group(1), m.group(2), m.group(3).strip()
        if status.startswith("Deployed"):
            out.append((name, target))
    return out


def main() -> None:
    print("=== Available DBs (deployed counts) ===")
    for idx in list_indices():
        deployed = deployed_targets(idx)
        if deployed:
            print(f"  {idx.parent.name:30s} {len(deployed):4d} deployed -> {idx}")

    # Pick a curated sample
    picks = [
        ("etoro", 2),
        ("WalletDB", 1),
        ("FiatDwhDB", 1),
        ("CalendarDB", 1),
        ("UserApiDB", 1),
    ]
    print("\n=== Picked QA samples ===")
    seen: set[str] = set()
    for db_name, n in picks:
        for idx in list_indices():
            if idx.parent.name == db_name:
                deployed = deployed_targets(idx)
                # Pick from middle of list for variety
                if not deployed:
                    continue
                step = max(1, len(deployed) // (n + 1))
                for i in range(n):
                    pos = step * (i + 1)
                    if pos >= len(deployed):
                        pos = len(deployed) - 1 - i
                    if 0 <= pos < len(deployed):
                        name, tgt = deployed[pos]
                        if tgt in seen:
                            continue
                        seen.add(tgt)
                        print(f"  {db_name:15s}  {tgt}  ({name})")
                break


if __name__ == "__main__":
    main()
