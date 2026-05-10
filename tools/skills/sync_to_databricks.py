"""
One-shot deploy: curate skills locally then upload to Databricks Workspace.

Pipeline:
  1. Re-run sync_to_assistant.py logic in-process to refresh
     %USERPROFILE%\.assistant\skills\dwh-domain\ (curated, no underscore-prefixed
     working files).
  2. Shell out to `databricks workspace import-dir --overwrite` to upload that
     curated tree to /Workspace/Users/<email>/.assistant/skills/dwh-domain/.

Usage:
    python tools\skills\sync_to_databricks.py
    python tools\skills\sync_to_databricks.py --profile guyman --user-email guyman@etoro.com
    python tools\skills\sync_to_databricks.py --workspace-base /Workspace/Shared/.assistant/skills

Defaults (override via flag or env):
  --profile        DATABRICKS_PROFILE       (default: "guyman")
  --user-email     DATABRICKS_USER_EMAIL    (default: "guyman@etoro.com")
  --workspace-base DATABRICKS_WORKSPACE_BASE
                   (default: "/Workspace/Users/<email>/.assistant/skills")
  --dest-name      "dwh-domain"

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
    parser.add_argument("--dest-name", default="dwh-domain")
    parser.add_argument("--skip-stage", action="store_true",
                        help="Skip the local stage refresh (use existing %USERPROFILE%\\.assistant\\skills\\dwh-domain content as-is)")
    parser.add_argument("--skip-upload", action="store_true",
                        help="Refresh the local stage but do NOT push to Databricks")
    args = parser.parse_args(argv)

    base = args.workspace_base or f"/Workspace/Users/{args.user_email}/.assistant/skills"
    workspace_path = f"{base.rstrip('/')}/{args.dest_name}"

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
    print(f"Stage 2 — upload to Databricks Workspace via profile '{args.profile}'")
    print("=" * 72)
    rc = upload_to_workspace(LOCAL_STAGE, workspace_path, args.profile)
    if rc != 0:
        print(f"\n[error] databricks workspace import-dir exited {rc}", file=sys.stderr)
        return rc

    print(f"\nDeployed to: {workspace_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
