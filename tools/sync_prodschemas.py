#!/usr/bin/env python3
"""sync_prodschemas.py — mirror Tier 1 wikis from PROD source repos.

Purpose
-------
The 6 PROD source repos are read-only (we cannot push changes to them). This
Knowledge repo holds the canonical Tier 1 wiki snapshot for use by the UC
bronze comment generator and the upstream-wiki-router skill.

Per-repo flow
-------------
1. `git fetch origin` and `git pull --ff-only` (skipped if local is dirty —
   warning logged, current working state mirrored anyway).
2. Capture HEAD commit sha.
3. Recursively discover directories named exactly "Wiki" (excluding .git/).
4. **Strict allowlist**: copy ONLY files under those discovered Wiki/ dirs.
   The .sql DDL files, .sln, scripts, READMEs, and anything else outside a
   Wiki/ tree is never copied.
5. Mirror to knowledge/ProdSchemas/{repo}/{db}/Wiki/... (nested by repo to
   future-proof against db-name collisions across repos).
6. Diff vs prior manifest; report added / modified / deleted / unchanged.

Outputs
-------
- knowledge/ProdSchemas/{repo}/{db}/Wiki/...     mirrored content
- knowledge/ProdSchemas/_sync_manifest.json      provenance + drift detection

Optional
--------
--emit-routing regenerates knowledge/synapse/Wiki/_upstream_wiki_routing.json
so it points at the local ProdSchemas paths (existing skill keeps working).
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
GITHUB_ROOT_DEFAULT = Path(r"C:\Users\guyman\Documents\github")

DEFAULT_SOURCE_REPOS = [
    "BankingDBs",
    "ComplianceDBs",
    "CryptoDBs",
    "DB_Schema",
    "ExperianceDBs",
    "PaymentsDBs",
]

PRODSCHEMAS_DIR = REPO_ROOT / "knowledge" / "ProdSchemas"
MANIFEST_PATH = PRODSCHEMAS_DIR / "_sync_manifest.json"
ROUTING_PATH = REPO_ROOT / "knowledge" / "synapse" / "Wiki" / "_upstream_wiki_routing.json"


# ---------------------------------------------------------------------------
# git helpers
# ---------------------------------------------------------------------------

def git(args: list[str], cwd: Path, check: bool = True) -> tuple[str, str, int]:
    """Run a git command. Returns (stdout, stderr, returncode)."""
    result = subprocess.run(
        ["git", *args],
        cwd=str(cwd),
        capture_output=True,
        text=True,
        check=False,
    )
    if check and result.returncode != 0:
        raise RuntimeError(
            f"git {' '.join(args)} failed in {cwd}:\n{result.stderr.strip()}"
        )
    return result.stdout.strip(), result.stderr.strip(), result.returncode


def repo_status(repo_path: Path) -> dict:
    head, _, _ = git(["rev-parse", "HEAD"], repo_path)
    branch, _, _ = git(["rev-parse", "--abbrev-ref", "HEAD"], repo_path)
    porcelain, _, _ = git(["status", "--porcelain"], repo_path)
    return {"head": head, "branch": branch, "dirty": bool(porcelain.strip())}


def fetch_and_pull(repo_path: Path, log) -> dict:
    """git fetch + pull --ff-only. Skip pull if dirty."""
    status = repo_status(repo_path)
    if status["dirty"]:
        log(
            f"  WARN: {repo_path.name} has local changes — skipping git pull, "
            f"mirroring current working state at {status['head'][:8]}"
        )
        return status
    try:
        git(["fetch", "origin"], repo_path)
        git(["pull", "--ff-only"], repo_path)
        new_status = repo_status(repo_path)
        if new_status["head"] != status["head"]:
            log(f"  pulled: {status['head'][:8]} -> {new_status['head'][:8]}")
        else:
            log(f"  up to date at {status['head'][:8]}")
        return new_status
    except RuntimeError as e:
        log(f"  WARN: git fetch/pull failed in {repo_path.name}: {e}")
        return status


# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------

def find_wiki_dirs(repo_path: Path) -> list[Path]:
    """Find all directories named exactly 'Wiki' inside repo_path.

    Uses os.walk with explicit .git/.vs/.cursor/.specify pruning so we don't
    waste time descending into version-control or IDE metadata dirs.
    """
    found: list[Path] = []
    SKIP = {".git", ".vs", ".vscode", ".cursor", ".claude", ".specify", ".github", ".GitActionScripts"}
    for dirpath, dirnames, _ in os.walk(repo_path):
        # prune in-place
        dirnames[:] = [d for d in dirnames if d not in SKIP]
        for d in dirnames:
            if d == "Wiki":
                found.append(Path(dirpath) / d)
    return found


def db_name_from_wiki_path(wiki_path: Path, repo_path: Path) -> str:
    """Given C:/.../DB_Schema/etoro/Wiki, return 'etoro'.

    The db is the immediate parent of the Wiki/ directory. If Wiki/ sits at
    the repo root (rare), the db name is the repo name itself.
    """
    parent = wiki_path.parent
    if parent == repo_path:
        return repo_path.name
    rel = parent.relative_to(repo_path)
    # Use the deepest segment as db name; multi-level Wiki paths get joined.
    parts = rel.parts
    if len(parts) == 1:
        return parts[0]
    return "_".join(parts)


# ---------------------------------------------------------------------------
# Hashing
# ---------------------------------------------------------------------------

def file_sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def wiki_tree_fingerprint(wiki_dir: Path) -> tuple[str, int]:
    """Return (sha256-of-sorted-file-list-with-content-hashes, file_count)."""
    items: list[str] = []
    for f in sorted(wiki_dir.rglob("*")):
        if f.is_file():
            rel = f.relative_to(wiki_dir).as_posix()
            items.append(f"{rel}\t{file_sha256(f)}")
    h = hashlib.sha256()
    h.update("\n".join(items).encode("utf-8"))
    return h.hexdigest(), len(items)


# ---------------------------------------------------------------------------
# Mirror
# ---------------------------------------------------------------------------

def mirror_wiki_tree(src: Path, dest: Path) -> tuple[int, int, int, int]:
    """Mirror only the files under src into dest.

    Returns (added, modified, deleted, unchanged).
    """
    added = modified = deleted = unchanged = 0

    src_files: set[str] = set()
    for f in src.rglob("*"):
        if f.is_file():
            src_files.add(f.relative_to(src).as_posix())

    dest_files: set[str] = set()
    if dest.exists():
        for f in dest.rglob("*"):
            if f.is_file():
                dest_files.add(f.relative_to(dest).as_posix())

    for rel in src_files:
        src_f = src / rel
        dest_f = dest / rel
        dest_f.parent.mkdir(parents=True, exist_ok=True)
        if not dest_f.exists():
            shutil.copy2(src_f, dest_f)
            added += 1
        elif file_sha256(src_f) != file_sha256(dest_f):
            shutil.copy2(src_f, dest_f)
            modified += 1
        else:
            unchanged += 1

    for rel in dest_files - src_files:
        (dest / rel).unlink()
        deleted += 1

    # Remove now-empty directories (bottom-up).
    if dest.exists():
        for dirpath, dirnames, filenames in os.walk(dest, topdown=False):
            if not dirnames and not filenames:
                p = Path(dirpath)
                if p != dest:
                    p.rmdir()

    return added, modified, deleted, unchanged


# ---------------------------------------------------------------------------
# Manifest + routing
# ---------------------------------------------------------------------------

def load_prior_manifest() -> dict:
    if MANIFEST_PATH.exists():
        try:
            return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            return {}
    return {}


def write_manifest(manifest: dict) -> None:
    PRODSCHEMAS_DIR.mkdir(parents=True, exist_ok=True)
    MANIFEST_PATH.write_text(
        json.dumps(manifest, indent=2, sort_keys=False),
        encoding="utf-8",
    )


def emit_routing(manifest: dict, log) -> None:
    """Regenerate _upstream_wiki_routing.json pointing at local copies.

    Schema mirrors the existing routing file so the upstream-wiki-router
    skill keeps working without changes.
    """
    upstream_dbs: dict = {}
    name_collisions: dict[str, list[str]] = {}

    for db_key, info in manifest.get("databases", {}).items():
        db_name = info["db_name"]
        if db_name in upstream_dbs:
            name_collisions.setdefault(db_name, [upstream_dbs[db_name]["repo"]]).append(info["source_repo"])
            # Keep first one wins (existing routing-file behavior). Composite
            # key under db_key still gives unambiguous access if needed.
            continue

        local_wiki = PRODSCHEMAS_DIR / info["source_repo"] / db_name / "Wiki"
        schemas: list[str] = []
        schema_details: list[dict] = []
        if local_wiki.exists():
            for schema_dir in sorted(local_wiki.iterdir()):
                if not schema_dir.is_dir():
                    continue
                tables_dir = schema_dir / "Tables"
                views_dir = schema_dir / "Views"
                file_count = sum(1 for _ in schema_dir.rglob("*.md") if _.is_file())
                schemas.append(schema_dir.name)
                schema_details.append(
                    {
                        "name": schema_dir.name,
                        "file_count": file_count,
                        "has_tables": tables_dir.is_dir(),
                        "has_views": views_dir.is_dir(),
                    }
                )

        upstream_dbs[db_name] = {
            "repo": info["source_repo"],
            "repo_path": str(REPO_ROOT),
            "wiki_path": f"knowledge/ProdSchemas/{info['source_repo']}/{db_name}/Wiki",
            "schemas": schemas,
            "schema_details": schema_details,
            "total_wiki_files": info["file_count"],
        }

    routing = {
        "_metadata": {
            "generated": datetime.now(timezone.utc).isoformat(),
            "source": "tools/sync_prodschemas.py --emit-routing",
            "wiki_root": str(PRODSCHEMAS_DIR).replace("\\", "/"),
            "total_upstream_databases": len(upstream_dbs),
            "name_collisions": name_collisions,
        },
        "upstream_databases": upstream_dbs,
    }
    ROUTING_PATH.write_text(
        json.dumps(routing, indent=2, sort_keys=False),
        encoding="utf-8",
    )
    log(f"  wrote {ROUTING_PATH.relative_to(REPO_ROOT)}")
    log(f"  total databases: {len(upstream_dbs)}")
    if name_collisions:
        log(f"  WARN: db-name collisions across repos: {list(name_collisions)}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Sync Tier 1 wikis from PROD repos into knowledge/ProdSchemas/"
    )
    parser.add_argument(
        "--repos",
        nargs="*",
        default=DEFAULT_SOURCE_REPOS,
        help=f"Source repo names under github root (default: {' '.join(DEFAULT_SOURCE_REPOS)})",
    )
    parser.add_argument(
        "--github-root",
        default=str(GITHUB_ROOT_DEFAULT),
        help="Root path containing source repos",
    )
    parser.add_argument(
        "--no-pull",
        action="store_true",
        help="Skip git fetch/pull, just mirror current state",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Discover and report only, don't copy or write manifest",
    )
    parser.add_argument(
        "--emit-routing",
        action="store_true",
        help="Regenerate _upstream_wiki_routing.json post-sync",
    )
    args = parser.parse_args()

    github_root = Path(args.github_root)
    PRODSCHEMAS_DIR.mkdir(parents=True, exist_ok=True)

    sync_started = datetime.now(timezone.utc).isoformat()
    log = print

    log("=" * 70)
    log(f"sync_prodschemas: {len(args.repos)} repo(s)")
    log(f"  source: {github_root}")
    log(f"  dest:   {PRODSCHEMAS_DIR.relative_to(REPO_ROOT)}")
    if args.dry_run:
        log("  *** DRY-RUN: discovery + report only ***")
    if args.no_pull:
        log("  --no-pull: skipping git fetch/pull")
    log("=" * 70)

    new_manifest = {
        "_metadata": {
            "sync_started": sync_started,
            "github_root": str(github_root),
            "source_repos": args.repos,
            "tool": "tools/sync_prodschemas.py",
        },
        "databases": {},
    }

    grand_added = grand_modified = grand_deleted = grand_unchanged = 0
    skipped_repos: list[str] = []

    for repo_name in args.repos:
        repo_path = github_root / repo_name
        log(f"\n[{repo_name}]")
        if not repo_path.exists():
            log(f"  SKIP — repo not found at {repo_path}")
            skipped_repos.append(repo_name)
            continue
        if not (repo_path / ".git").exists():
            log(f"  SKIP — not a git repo (no .git/)")
            skipped_repos.append(repo_name)
            continue

        if not args.no_pull and not args.dry_run:
            status = fetch_and_pull(repo_path, log)
        else:
            status = repo_status(repo_path)
            log(f"  HEAD: {status['head'][:8]} (branch={status['branch']}, no-pull mode)")

        wiki_dirs = find_wiki_dirs(repo_path)
        log(
            f"  found {len(wiki_dirs)} Wiki/ director"
            f"{'y' if len(wiki_dirs) == 1 else 'ies'}"
        )

        for wiki_dir in wiki_dirs:
            db_name = db_name_from_wiki_path(wiki_dir, repo_path)
            db_key = f"{repo_name}/{db_name}"
            dest_wiki = PRODSCHEMAS_DIR / repo_name / db_name / "Wiki"
            rel_src = wiki_dir.relative_to(repo_path).as_posix()
            log(f"    {rel_src} -> ProdSchemas/{repo_name}/{db_name}/Wiki")

            if args.dry_run:
                src_count = sum(1 for _ in wiki_dir.rglob("*") if _.is_file())
                log(f"      (dry-run) source files: {src_count}")
                continue

            added, modified, deleted, unchanged = mirror_wiki_tree(wiki_dir, dest_wiki)
            grand_added += added
            grand_modified += modified
            grand_deleted += deleted
            grand_unchanged += unchanged

            content_hash, file_count = wiki_tree_fingerprint(dest_wiki)
            new_manifest["databases"][db_key] = {
                "db_name": db_name,
                "source_repo": repo_name,
                "source_path": rel_src,
                "source_head": status["head"],
                "source_branch": status["branch"],
                "synced_at": datetime.now(timezone.utc).isoformat(),
                "file_count": file_count,
                "content_sha256": content_hash,
            }
            log(
                f"      added={added} modified={modified} deleted={deleted} "
                f"unchanged={unchanged} files={file_count}"
            )

    if not args.dry_run:
        write_manifest(new_manifest)

    log("\n" + "=" * 70)
    log("SUMMARY")
    log(f"  databases:  {len(new_manifest['databases'])}")
    log(
        f"  files:      added={grand_added} modified={grand_modified} "
        f"deleted={grand_deleted} unchanged={grand_unchanged}"
    )
    if skipped_repos:
        log(f"  skipped:    {', '.join(skipped_repos)}")
    if not args.dry_run:
        log(f"  manifest:   {MANIFEST_PATH.relative_to(REPO_ROOT)}")
    log("=" * 70)

    if args.emit_routing and not args.dry_run:
        log("\nEmit routing file...")
        emit_routing(new_manifest, log)

    return 0


if __name__ == "__main__":
    sys.exit(main())
