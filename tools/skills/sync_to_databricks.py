"""
One-shot deploy: curate skills locally then upload to Databricks Workspace.

**Workspace layout is FLAT (no `dwh-domain/` wrapper).** Each top-level folder
under `knowledge/skills/` is deployed as its own sibling under the workspace
skills base, e.g. `knowledge/skills/domain-trading/` →
`/Workspace/Users/<email>/.assistant/skills/domain-trading/`. Loose top-level
files (other than SKILL.md from `_router.md`) are skipped to avoid collisions
with existing folders of the same name.

Pipeline:
  1. Refresh local stage at %USERPROFILE%\.assistant\skills\dwh-domain\ (the
     stage path name is legacy; the workspace destination is flat).
  2. For each `domain-*` (and any other curated) folder in the stage, shell
     out to `databricks workspace import-dir --overwrite` to push it to
     `<workspace-base>/<folder-name>/`.

Usage:
    python tools\skills\sync_to_databricks.py
    python tools\skills\sync_to_databricks.py --profile guyman --user-email guyman@etoro.com
    python tools\skills\sync_to_databricks.py --workspace-base /Workspace/Shared/.assistant/skills
    python tools\skills\sync_to_databricks.py --only domain-trading domain-revenue-and-fees

Defaults (override via flag or env):
  --profile        DATABRICKS_PROFILE       (default: "guyman")
  --user-email     DATABRICKS_USER_EMAIL    (default: "guyman@etoro.com")
  --workspace-base DATABRICKS_WORKSPACE_BASE
                   (default: "/Workspace/Users/<email>/.assistant/skills")
  --only           list of folder names to restrict the deploy to (default: all)

Pre-requisites:
  - `databricks` CLI on PATH and the requested profile authenticated
    (`databricks auth login --profile <name>` once, refreshed when needed).
"""
from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SRC = REPO_ROOT / "knowledge" / "skills"
LOCAL_STAGE = Path(os.path.expandvars(r"%USERPROFILE%\.assistant\skills\dwh-domain"))


def is_curated(p: Path) -> bool:
    """Skip underscore-prefixed working files. Keep SKILL.md and named *.md."""
    if p.is_dir():
        return not p.name.startswith("_")
    if p.suffix != ".md":
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
            print(f"  {' ' * indent}{entry.name} -> {target}", flush=True)
            n += 1
    return n


def stage_local(stage_dir: Path) -> int:
    """Mirror SRC -> stage_dir (idempotent overwrite). Returns file count."""
    if not SRC.exists():
        print(f"Source missing: {SRC}", file=sys.stderr)
        sys.exit(2)
    if stage_dir.exists():
        shutil.rmtree(stage_dir)
    stage_dir.mkdir(parents=True, exist_ok=True)

    router_src = SRC / "_router.md"
    if router_src.exists():
        router_dst = stage_dir / "SKILL.md"
        shutil.copy2(router_src, router_dst)
        print(f"  _router.md -> {router_dst} (renamed to SKILL.md)", flush=True)
    else:
        print("WARN: knowledge/skills/_router.md missing", file=sys.stderr)

    n = 0
    for entry in sorted(SRC.iterdir()):
        if entry.is_dir() and is_curated(entry):
            n += copy_curated(entry, stage_dir / entry.name)
        elif entry.is_file() and entry.name == "_router.md":
            continue
        elif entry.is_file() and is_curated(entry):
            shutil.copy2(entry, stage_dir / entry.name)
            print(f"  {entry.name} -> {stage_dir / entry.name}", flush=True)
            n += 1
    return n


def upload_to_workspace(local_dir: Path, workspace_path: str, profile: str) -> int:
    cmd = [
        "databricks", "workspace", "import-dir",
        str(local_dir), workspace_path,
        "--overwrite", "--profile", profile,
    ]
    print(f"\n$ {' '.join(cmd)}", flush=True)
    return subprocess.call(cmd)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--profile", default=os.environ.get("DATABRICKS_PROFILE", "guyman"))
    parser.add_argument("--user-email", default=os.environ.get("DATABRICKS_USER_EMAIL", "guyman@etoro.com"))
    parser.add_argument("--workspace-base", default=os.environ.get("DATABRICKS_WORKSPACE_BASE"))
    parser.add_argument("--only", nargs="*", default=None,
                        help="Restrict the deploy to specific top-level folder names (default: all)")
    parser.add_argument("--skip-stage", action="store_true",
                        help="Skip the local stage refresh (use existing local stage content as-is)")
    parser.add_argument("--skip-upload", action="store_true",
                        help="Refresh the local stage but do NOT push to Databricks")
    args = parser.parse_args(argv)

    base = (args.workspace_base or f"/Workspace/Users/{args.user_email}/.assistant/skills").rstrip("/")

    print("=" * 72)
    print("Stage 1 — refresh local curated mirror")
    print("=" * 72)
    if args.skip_stage:
        print(f"  (skipped; using existing {LOCAL_STAGE})")
    else:
        n = stage_local(LOCAL_STAGE)
        print(f"\nMirrored {n} files (plus SKILL.md from router) to {LOCAL_STAGE}")

    if args.skip_upload:
        print("\n(--skip-upload set; not pushing to Databricks)")
        return 0

    print()
    print("=" * 72)
    print(f"Stage 2 — upload to Databricks Workspace (flat layout) via profile '{args.profile}'")
    print("=" * 72)

    folders = [p for p in sorted(LOCAL_STAGE.iterdir()) if p.is_dir() and not p.name.startswith("_")]
    if args.only:
        wanted = set(args.only)
        folders = [p for p in folders if p.name in wanted]
        missing = wanted - {p.name for p in folders}
        if missing:
            print(f"[warn] --only requested folders not present in stage: {sorted(missing)}", file=sys.stderr)

    if not folders:
        print("[error] no folders to deploy", file=sys.stderr)
        return 1

    deployed = []
    for folder in folders:
        workspace_path = f"{base}/{folder.name}"
        rc = upload_to_workspace(folder, workspace_path, args.profile)
        if rc != 0:
            print(f"\n[error] databricks workspace import-dir exited {rc} for {folder.name}", file=sys.stderr)
            return rc
        deployed.append(workspace_path)

    print(f"\nDeployed {len(deployed)} folder(s):")
    for p in deployed:
        print(f"  - {p}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
