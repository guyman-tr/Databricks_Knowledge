#!/usr/bin/env python3
"""Pre-commit / CI gate that runs `verify_tier1_claims` against staged or
changed wiki files only.

Modes
-----
  --precommit   Verify wikis staged for commit (git diff --cached --name-only)
  --ci          Verify wikis changed vs the merge-base of the current branch
                with `origin/main` (or the branch passed via --base).
  --files ...   Verify the explicit list of files passed on the command line.

In all modes the script invokes
  python -m tools.cleanup_tier1.verify_tier1_claims --strict <files>
which exits non-zero on the first failing Tier-1 claim.

Wire-in
-------
Append to `.git/hooks/pre-commit`:

  #!/bin/sh
  exec python -m tools.cleanup_tier1.precommit_verify --precommit

Or add to your CI workflow (GitHub Actions / etc.):

  - run: python -m tools.cleanup_tier1.precommit_verify --ci --base origin/main
"""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def _git(*args: str) -> list[str]:
    out = subprocess.check_output(["git", *args], cwd=str(REPO), text=True)
    return [line.strip() for line in out.splitlines() if line.strip()]


def _staged_wikis() -> list[Path]:
    files = _git("diff", "--cached", "--name-only", "--diff-filter=AM")
    return _filter_wikis(files)


def _ci_wikis(base: str) -> list[Path]:
    files = _git("diff", f"{base}...HEAD", "--name-only", "--diff-filter=AM")
    return _filter_wikis(files)


def _filter_wikis(files: list[str]) -> list[Path]:
    out: list[Path] = []
    for f in files:
        if not f.endswith(".md"):
            continue
        # Only Synapse + UC_generated wikis carry Tier 1 tags
        if not (f.startswith("knowledge/synapse/Wiki/")
                or f.startswith("knowledge/UC_generated/")):
            continue
        # Skip sidecars
        stem = Path(f).stem.lower()
        if any(part in stem for part in
               (".lineage", ".review-needed", ".deploy-report", ".alter")):
            continue
        p = REPO / f
        if p.exists():
            out.append(p)
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--precommit", action="store_true")
    mode.add_argument("--ci", action="store_true")
    mode.add_argument("--files", nargs="+", default=[])
    ap.add_argument("--base", default="origin/main",
                    help="Base ref for --ci diff. Defaults to origin/main.")
    args = ap.parse_args()

    if args.precommit:
        wikis = _staged_wikis()
        label = "staged"
    elif args.ci:
        wikis = _ci_wikis(args.base)
        label = f"changed vs {args.base}"
    else:
        wikis = [Path(p).resolve() for p in args.files]
        label = "explicit"

    if not wikis:
        print(f"No {label} Tier-1-bearing wikis to verify. OK.")
        return

    print(f"Verifying {len(wikis)} {label} wiki(s) in --strict mode")
    cmd = [
        sys.executable, "-m", "tools.cleanup_tier1.verify_tier1_claims",
        "--strict", "--summary", "--",
    ]
    cmd += [str(p) for p in wikis]
    rc = subprocess.call(cmd, cwd=str(REPO))
    sys.exit(rc)


if __name__ == "__main__":
    main()
