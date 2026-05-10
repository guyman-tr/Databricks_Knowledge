"""
One-shot rewriter: convert relative wiki links in skill markdown bodies to
absolute GitHub URLs pointing at the wiki repo (Databricks_Knowledge).

Why: when the domain-knowledge repo lives separately from the wiki repo, the
relative `../../synapse/Wiki/<path>` links break. Resolving them to absolute
GitHub URLs means the links work for any consumer (Databricks Assistant,
Cursor, GitHub web view) regardless of how/where the repo is checked out.

Patterns rewritten (markdown link form `](<url>)`):
  ../../synapse/Wiki/<rest>   ->  <BASE>/knowledge/synapse/Wiki/<rest>
  ../../uc_domains/<rest>     ->  <BASE>/knowledge/uc_domains/<rest>
  ../../ProdSchemas/<rest>    ->  <BASE>/knowledge/ProdSchemas/<rest>

where BASE = https://github.com/guyman-tr/Databricks_Knowledge/blob/master

Idempotent — running twice is a no-op.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SKILLS_DIR = REPO / "knowledge" / "skills"
BASE = "https://github.com/guyman-tr/Databricks_Knowledge/blob/master"

# Order matters: longest prefix first.
PREFIX_MAP = [
    ("../../synapse/Wiki/", f"{BASE}/knowledge/synapse/Wiki/"),
    ("../../uc_domains/",   f"{BASE}/knowledge/uc_domains/"),
    ("../../ProdSchemas/",  f"{BASE}/knowledge/ProdSchemas/"),
]

LINK_RE = re.compile(r"\]\((?P<url>[^)\s]+)\)")


def rewrite_url(url: str) -> str:
    for old, new in PREFIX_MAP:
        if url.startswith(old):
            return new + url[len(old):]
    return url


def rewrite_text(text: str) -> tuple[str, int]:
    n = 0

    def _sub(m: re.Match) -> str:
        nonlocal n
        url = m.group("url")
        new = rewrite_url(url)
        if new != url:
            n += 1
        return f"]({new})"

    return LINK_RE.sub(_sub, text), n


def main() -> int:
    if not SKILLS_DIR.exists():
        print(f"Source missing: {SKILLS_DIR}", file=sys.stderr)
        return 2

    total_files = 0
    total_links = 0
    for md in SKILLS_DIR.rglob("*.md"):
        text = md.read_text(encoding="utf-8")
        new_text, n = rewrite_text(text)
        if n > 0:
            md.write_text(new_text, encoding="utf-8")
            total_files += 1
            total_links += n
            print(f"  {md.relative_to(REPO)}  ({n} links)")

    print(f"\nRewrote {total_links} link(s) across {total_files} file(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
