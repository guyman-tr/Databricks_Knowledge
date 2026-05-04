#!/usr/bin/env python3
"""
Phase 2 — Confluence Discovery helper.

The actual CQL searches and page fetches run as MCP tool calls (the agent
drives those interactively via plugin-atlassian-atlassian). This script does
the post-processing half of P2:

  1. Read a feed file of MCP-collected raw search results (newline-delimited
     JSON, each line = one CQL hit).
  2. Read the cached page MDs in _discovery/confluence_pages/ (their YAML
     frontmatter is the source of truth for the index entry).
  3. Build _discovery/confluence_index.json — one record per kept page +
     the searches_run audit trail.

This split exists because MCP tool calls happen inside the agent loop, not
inside a Python subprocess.

Usage:
  python tools/uc_domains/discover_confluence.py \
      --domain spaceship \
      --pages-dir knowledge/uc_domains/spaceship/_discovery/confluence_pages \
      --searches-file knowledge/uc_domains/spaceship/_discovery/_searches.jsonl \
      --out knowledge/uc_domains/spaceship/_discovery/confluence_index.json

Cached page MD format (one file per page):
---
cloud_id: ...
page_id: ...
title: ...
space_key: BI
space_name: "BI / KPI"
url: https://...
matched_query: "title ~ \"Spaceship Voyager Fees\""
matched_keyword: "Spaceship Voyager Fees"
confidence: high | broad
last_modified: 2024-...
labels: [bi, spaceship]
---

# (markdown body cached from getConfluencePage)
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

try:
    import yaml  # type: ignore
except ImportError:
    yaml = None  # graceful degradation


FRONTMATTER_RE = None


def parse_frontmatter(text: str) -> tuple[dict, str]:
    """Very small YAML frontmatter parser. Returns (meta, body)."""
    if not text.startswith("---"):
        return {}, text
    end = text.find("\n---", 3)
    if end == -1:
        return {}, text
    head = text[3:end].strip()
    body = text[end + 4:].lstrip("\n")
    if yaml is not None:
        try:
            meta = yaml.safe_load(head) or {}
            if not isinstance(meta, dict):
                meta = {"raw_frontmatter": head}
        except Exception as e:
            meta = {"frontmatter_parse_error": str(e), "raw_frontmatter": head}
    else:
        # crude key:value parse
        meta = {}
        for line in head.splitlines():
            if ":" in line and not line.startswith(" "):
                k, _, v = line.partition(":")
                meta[k.strip()] = v.strip().strip("'").strip('"')
    return meta, body


def collect_pages(pages_dir: Path) -> list[dict]:
    if not pages_dir.exists():
        return []
    out = []
    for fp in sorted(pages_dir.glob("*.md")):
        try:
            text = fp.read_text(encoding="utf-8")
        except Exception as e:
            print(f"[warn] cannot read {fp}: {e}", file=sys.stderr)
            continue
        meta, body = parse_frontmatter(text)
        meta = dict(meta)  # copy
        meta["cached_path"] = str(fp.relative_to(pages_dir.parent.parent))
        meta["body_chars"] = len(body)
        out.append(meta)
    return out


def collect_searches(path: Path | None) -> list[dict]:
    if not path or not path.exists():
        return []
    out = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        try:
            out.append(json.loads(line))
        except Exception as e:
            print(f"[warn] skipping non-JSON searches line: {e}", file=sys.stderr)
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="Build confluence_index.json from cached pages")
    ap.add_argument("--domain", required=True)
    ap.add_argument("--pages-dir", required=True)
    ap.add_argument("--searches-file", default=None,
                    help="Optional newline-delimited JSON: one search audit line per CQL run")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    pages_dir = Path(args.pages_dir)
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)

    pages = collect_pages(pages_dir)
    searches = collect_searches(Path(args.searches_file) if args.searches_file else None)

    cloud_ids = sorted({p.get("cloud_id") for p in pages if p.get("cloud_id")})

    payload = {
        "domain": args.domain,
        "generated_at": dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
        "cloud_ids": cloud_ids,
        "searches_run": searches,
        "pages": pages,
        "stats": {
            "page_count": len(pages),
            "high_confidence_count": sum(1 for p in pages if p.get("confidence") == "high"),
            "search_runs": len(searches),
            "search_results_total": sum(int(s.get("results", 0) or 0) for s in searches),
        },
    }
    out.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[confluence] wrote {out} ({len(pages)} pages, "
          f"{payload['stats']['high_confidence_count']} high-confidence, "
          f"{len(searches)} searches recorded)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
