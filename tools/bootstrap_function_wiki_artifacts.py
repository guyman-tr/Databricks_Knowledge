"""
One-shot (or --force) generator for function `.lineage.md` files.

Synapse TVFs/scalars documented under `Wiki/{Schema}/Functions/` use `_Not_Migrated`
for UC. Phase 10B lineage files were often never created; this fills the gap from
wiki §3 Source Objects + metadata.

Stub `.alter.sql` for knowledge-only functions is owned by `_batch_generate_lib.py`
(`generate-alter-dwh` / `python _batch_generate_lib.py {Schema} --offline`).

Usage:
  python tools/bootstrap_function_wiki_artifacts.py
  python tools/bootstrap_function_wiki_artifacts.py --schema BI_DB_dbo --force
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
WIKI = REPO / "knowledge" / "synapse" / "Wiki"


def parse_props(content: str) -> dict[str, str]:
    props: dict[str, str] = {}
    for m in re.finditer(r"\|\s*\*\*([^*]+)\*\*\s*\|\s*([^|]*)\|", content):
        props[m.group(1).strip()] = m.group(2).strip()
    return props


def extract_source_objects_section(content: str) -> str:
    m = re.search(
        r"## 3\.\s*Source Objects\s*\n(.*?)(?=\n## \d|\n---|\Z)",
        content,
        re.DOTALL,
    )
    if not m:
        return ""
    return m.group(1).strip()


def build_lineage_md(schema: str, fn_name: str, content: str) -> str:
    props = parse_props(content)
    obj_type = props.get("Object Type", "Function")
    uc = props.get("UC Target", "_Not_Migrated").strip().strip("`")
    src_block = extract_source_objects_section(content)
    if not src_block:
        src_md = "| *(none parsed)* | — | Wiki §3 missing or non-standard |"
    else:
        lines = []
        for line in src_block.splitlines():
            line = line.strip()
            if not line.startswith("|") or re.match(r"^\|[\s:-]+\|", line):
                continue
            parts = [p.strip() for p in line.split("|")]
            parts = [p for p in parts if p]
            if len(parts) >= 2 and parts[0].lower() not in ("object", "*object*"):
                lines.append(f"| {parts[0]} | {parts[1]} | Referenced in function body |")
        src_md = "\n".join(lines) if lines else "| *(see wiki §3)* | — | Non-tabular section |"

    return f"""# Object lineage — {schema}.{fn_name}

> **Synapse**: {obj_type}. **Unity Catalog**: `{uc}` (no Generic Pipeline gold table / TVF mapping in UC for this object).

## Referenced objects (wiki §3 — Source Objects)

| Object | Schema | Notes |
|--------|--------|-------|
{src_md}

## Output contract

See wiki **§4. Output Columns** (table-valued functions) or **§4** scalar return note.

## Pipeline notes

- **Phase 10B (repo)**: Functions stay in-repo; UC External Lineage injection does not apply until a UC entity exists.
- **ALTER**: Companion `{fn_name}.alter.sql` is a **comment-only stub** when UC Target is `_Not_Migrated` — `deploy-alter-dwh` must skip executable statements for these files.
"""


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--schema", default="BI_DB_dbo")
    ap.add_argument("--force", action="store_true", help="Overwrite existing .lineage.md")
    args = ap.parse_args()

    fn_dir = WIKI / args.schema / "Functions"
    if not fn_dir.is_dir():
        print(f"ERROR: {fn_dir} not found", file=sys.stderr)
        sys.exit(1)

    n = 0
    for md in sorted(fn_dir.glob("*.md")):
        if md.name.startswith("_"):
            continue
        if ".review-needed" in md.name or ".lineage" in md.name:
            continue
        out = md.with_suffix(".lineage.md")
        if out.exists() and not args.force:
            continue
        content = md.read_text(encoding="utf-8")
        fn_name = md.stem
        out.write_text(build_lineage_md(args.schema, fn_name, content), encoding="utf-8")
        n += 1
        print(f"Wrote {out.relative_to(REPO)}")

    print(f"Done. {n} lineage file(s) written.")


if __name__ == "__main__":
    main()
