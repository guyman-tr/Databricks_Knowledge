#!/usr/bin/env python3
"""
Build regenerate_downstream_sources.json from all wiki *.alter.sql files.

For each file:
  - source_synapse from path: Wiki/<Schema_dbo>/<Tables|Views>/<Object>.alter.sql
  - source_uc from line: -- UC Target: main.catalog.schema.table
  - Dedupe by source_uc (first file wins)

Optional: --dry-run only prints counts; default writes JSON next to Wiki README.

Usage:
  python tools/build_regenerate_downstream_config.py
  python tools/build_regenerate_downstream_config.py -o knowledge/synapse/Wiki/regenerate_downstream_sources.json
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WIKI_ROOT = ROOT / "knowledge" / "synapse" / "Wiki"

UC_TARGET_RE = re.compile(r"^\s*--\s*UC\s+Target:\s*(main\.[^\s]+)", re.IGNORECASE | re.MULTILINE)
ALTER_TABLE_MAIN_RE = re.compile(
    r"ALTER\s+TABLE\s+(main\.[^\s]+)\s+", re.IGNORECASE
)
COMMENT_COLUMN_RE = re.compile(
    r"ALTER\s+(?:TABLE|VIEW)\s+\S+\s+ALTER\s+COLUMN\s+\S+\s+COMMENT\s+'",
    re.IGNORECASE,
)


def synapse_from_path(rel: Path) -> str | None:
    parts = rel.parts
    if len(parts) < 3:
        return None
    schema = parts[0]
    kind = parts[1]
    if kind not in ("Tables", "Views"):
        return None
    stem = parts[2]
    if not stem.endswith(".alter.sql"):
        return None
    obj = stem[: -len(".alter.sql")]
    return f"{schema}.{obj}"


def extract_uc_target(text: str) -> str | None:
    m = UC_TARGET_RE.search(text)
    if m:
        return m.group(1).rstrip("`")
    m2 = ALTER_TABLE_MAIN_RE.search(text)
    if m2:
        return m2.group(1).rstrip("`")
    return None


def has_column_comments(text: str) -> bool:
    return bool(COMMENT_COLUMN_RE.search(text))


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "-o",
        "--output",
        type=Path,
        default=WIKI_ROOT / "regenerate_downstream_sources.json",
        help="Output JSON path",
    )
    ap.add_argument(
        "--include-no-comments",
        action="store_true",
        help="Include alters with no COLUMN COMMENT (discover will skip at runtime)",
    )
    args = ap.parse_args()

    by_uc: dict[str, dict] = {}
    skipped: list[tuple[str, str]] = []

    for path in sorted(WIKI_ROOT.glob("**/*.alter.sql")):
        rel = path.relative_to(ROOT)
        rel_s = str(rel).replace("\\", "/")
        if "_downstream" in rel_s.lower():
            continue
        # Generated propagation output, not a wiki root
        if ".downstream.alter.sql" in path.name.lower():
            skipped.append((rel_s, "generated .downstream.alter.sql"))
            continue
        syn = synapse_from_path(path.relative_to(WIKI_ROOT))
        if not syn:
            skipped.append((rel_s, "path not Tables/Views"))
            continue

        text = path.read_text(encoding="utf-8", errors="replace")
        uc = extract_uc_target(text)
        if not uc:
            skipped.append((rel_s, "no UC Target / ALTER TABLE main"))
            continue

        if not args.include_no_comments and not has_column_comments(text):
            skipped.append((rel_s, "no column COMMENT statements"))
            continue

        if uc in by_uc:
            skipped.append((rel_s, f"duplicate UC {uc} (kept {by_uc[uc]['alter_path']})"))
            continue

        by_uc[uc] = {
            "alter_path": rel_s,
            "source_uc": uc,
            "source_synapse": syn,
        }

    sources = sorted(by_uc.values(), key=lambda x: x["source_synapse"])

    out = {
        "include_uc_lineage": False,
        "generated_by": "tools/build_regenerate_downstream_config.py",
        "comment": "Full wiki scan: one discover_tree per source; merged name-based. Deduped by source_uc.",
        "sources": sources,
    }

    out_path = args.output
    if not out_path.is_absolute():
        out_path = ROOT / out_path
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(out, indent=2), encoding="utf-8")

    print(f"Wrote {len(sources)} unique sources -> {out_path}")
    print(f"Skipped {len(skipped)} paths (see stderr for first 30)")
    for rel_s, reason in skipped[:30]:
        print(f"  skip: {rel_s} — {reason}", flush=True)


if __name__ == "__main__":
    main()
