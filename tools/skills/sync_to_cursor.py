"""
Mirror knowledge/skills/* (curated content only — no underscore-prefixed
audit/working files) to C:/Users/guyman/.cursor/skills/dwh-domain/.

Layout in .cursor/skills:
  dwh-domain/
    SKILL.md                                 (= knowledge/skills/_router.md)
    payments/SKILL.md                        (= knowledge/skills/payments/SKILL.md)
    payments/deposits-and-withdrawals.md     (verbatim copy)
    bridges/<name>.md                        (verbatim copy when written)

Files starting with `_` are working artifacts (graphs, briefs, candidates,
node summaries) and are NOT mirrored.

Usage: python tools/skills/sync_to_cursor.py
"""
from __future__ import annotations

import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SRC = REPO_ROOT / "knowledge" / "skills"
DST = Path(r"C:\Users\guyman\.cursor\skills\dwh-domain")


def is_curated(p: Path) -> bool:
    """Skip underscore-prefixed working files. Keep SKILL.md and named *.md."""
    if p.is_dir():
        return not p.name.startswith("_")
    if not p.suffix == ".md":
        return False
    return not p.name.startswith("_")


def copy_curated(src_dir: Path, dst_dir: Path, indent: int = 0) -> int:
    n = 0
    dst_dir.mkdir(parents=True, exist_ok=True)
    for entry in sorted(src_dir.iterdir()):
        if entry.is_dir():
            if is_curated(entry):
                n += copy_curated(entry, dst_dir / entry.name, indent + 2)
        elif entry.is_file() and is_curated(entry):
            target = dst_dir / entry.name
            shutil.copy2(entry, target)
            print(f"{' ' * indent}{entry.name} -> {target}", flush=True)
            n += 1
    return n


def main() -> int:
    if not SRC.exists():
        print(f"Source missing: {SRC}", file=sys.stderr)
        return 2

    # Wipe destination (idempotent overwrite — small folder, safe)
    if DST.exists():
        shutil.rmtree(DST)
    DST.mkdir(parents=True, exist_ok=True)

    # Top-level: rename _router.md -> SKILL.md when copying so .cursor/skills
    # treats the router as the entry point of the dwh-domain skill.
    router_src = SRC / "_router.md"
    if router_src.exists():
        router_dst = DST / "SKILL.md"
        shutil.copy2(router_src, router_dst)
        print(f"_router.md -> {router_dst} (renamed to SKILL.md)", flush=True)
    else:
        print("WARN: knowledge/skills/_router.md missing — destination will not have SKILL.md", file=sys.stderr)

    # Now copy all curated subfolders/files
    n = 0
    for entry in sorted(SRC.iterdir()):
        if entry.is_dir() and is_curated(entry):
            n += copy_curated(entry, DST / entry.name)
        elif entry.is_file() and entry.name == "_router.md":
            continue  # already handled
        elif entry.is_file() and is_curated(entry):
            shutil.copy2(entry, DST / entry.name)
            print(f"{entry.name} -> {DST / entry.name}", flush=True)
            n += 1

    print(f"\nMirrored {n} files (plus SKILL.md from router) to {DST}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
