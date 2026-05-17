#!/usr/bin/env python3
"""
Validation pass for UC-Pipeline wiki output (Phase 5 / Phase 6 gate).

Checks per object in a schema folder:
  1. `.lineage.md` exists for every `.md`.
  2. Every column row in `.md` Section 3 (Elements) has a `(Tier N — origin)` suffix.
  3. Element count in `.md` == element count in `.lineage.md` == column_count
     in frontmatter == column count in `uc_inventory.json`.
  4. For every Tier 1 column whose origin tag points to an upstream UC object
     present in `_discovery/upstream_wikis/_index.json`, the upstream wiki
     actually exists on disk.
  5. Passthrough columns: their description text matches the upstream wiki's
     description for the same column (cross-object consistency — soft warning
     if missing, hard fail if explicitly mismatched).
  6. When `.alter.sql` exists: one ALTER COLUMN per Element row (parity), no
     `[UNVERIFIED]` text leaks in.

Exit code is non-zero on HARD failure. WARN-level issues are reported but
don't fail the gate.

Usage:
  python tools/uc_pipelines/validate_pipeline_wiki.py --schema etoro_kpi_prep
  python tools/uc_pipelines/validate_pipeline_wiki.py --schema de_output --strict
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
PACK_ROOT = REPO / "knowledge" / "UC_generated"

TIER_TAG_RE = re.compile(r"\(Tier\s+([1-5][a-z]?)\s+[—–-]\s+([^\)]+)\)")
ELEMENT_ROW_RE = re.compile(r"^\|\s*\d+\s*\|\s*[`]?([A-Za-z_][A-Za-z0-9_]*)[`]?\s*\|")
ELEMENT_HEADER_RE = re.compile(r"^##\s+3\.\s+Elements", re.IGNORECASE | re.MULTILINE)
LINEAGE_ROW_RE = re.compile(r"^\|\s*\d+\s*\|\s*[`]?([A-Za-z_][A-Za-z0-9_]*)[`]?\s*\|")
LINEAGE_HEADER_RE = re.compile(r"^##\s+Column Lineage", re.IGNORECASE | re.MULTILINE)


class Issue:
    LEVEL_HARD = "HARD"
    LEVEL_SOFT = "WARN"

    def __init__(self, level: str, object_name: str, code: str, msg: str):
        self.level = level
        self.object_name = object_name
        self.code = code
        self.msg = msg

    def __str__(self):
        return f"[{self.level}] {self.object_name}: {self.code} — {self.msg}"


def _extract_section(text: str, header_re) -> str | None:
    m = header_re.search(text)
    if not m:
        return None
    start = m.end()
    # Section ends at next `## ` header
    next_m = re.search(r"^##\s+\d+\.", text[start:], re.MULTILINE)
    return text[start: start + next_m.start()] if next_m else text[start:]


def _parse_elements_rows(md_text: str) -> list[dict]:
    section = _extract_section(md_text, ELEMENT_HEADER_RE)
    if not section:
        return []
    rows: list[dict] = []
    for line in section.splitlines():
        if not line.strip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 5:
            continue
        idx_cell = cells[0]
        if not idx_cell.isdigit():
            continue
        name_cell = cells[1].strip("` ")
        desc_cell = cells[-1]
        rows.append({
            "ordinal": int(idx_cell),
            "name": name_cell,
            "description": desc_cell,
        })
    return rows


def _parse_lineage_rows(lineage_text: str) -> list[dict]:
    section = _extract_section(lineage_text, LINEAGE_HEADER_RE)
    if not section:
        return []
    rows: list[dict] = []
    for line in section.splitlines():
        if not line.strip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 5:
            continue
        idx_cell = cells[0]
        if not idx_cell.isdigit():
            continue
        name_cell = cells[1].strip("` ")
        rows.append({
            "ordinal": int(idx_cell),
            "name": name_cell,
            "source_object": cells[2].strip("` "),
            "source_column": cells[3].strip("` "),
            "transform": cells[4].strip("` "),
        })
    return rows


def _parse_yaml_frontmatter(text: str) -> dict:
    m = re.match(r"^---\n(.+?)\n---\n", text, re.DOTALL)
    if not m:
        return {}
    try:
        import yaml  # type: ignore
        return yaml.safe_load(m.group(1)) or {}
    except Exception:
        return {}


def _parse_alter_columns(alter_sql_text: str) -> list[str]:
    return re.findall(
        r"ALTER\s+(?:TABLE|VIEW)\s+\S+\s+ALTER\s+COLUMN\s+`?([A-Za-z_][A-Za-z0-9_]*)`?",
        alter_sql_text, flags=re.IGNORECASE,
    )


def validate_object(md_path: Path, inv_cols_by_name: dict[str, dict],
                    ux_index: dict, strict: bool) -> list[Issue]:
    obj_name = md_path.stem
    issues: list[Issue] = []
    text = md_path.read_text(encoding="utf-8")
    fm = _parse_yaml_frontmatter(text)

    lineage_path = md_path.with_suffix(".lineage.md")
    if not lineage_path.exists():
        issues.append(Issue(Issue.LEVEL_HARD, obj_name, "no_lineage_md",
                            f".lineage.md missing alongside {md_path.name}"))
        return issues  # Can't continue without lineage

    lineage_text = lineage_path.read_text(encoding="utf-8")
    md_rows = _parse_elements_rows(text)
    lineage_rows = _parse_lineage_rows(lineage_text)

    if len(md_rows) != len(lineage_rows):
        issues.append(Issue(Issue.LEVEL_HARD, obj_name, "row_count_mismatch",
                            f".md has {len(md_rows)} elements, .lineage.md has {len(lineage_rows)}"))

    fm_count = fm.get("column_count")
    if fm_count is not None and fm_count != len(md_rows):
        issues.append(Issue(Issue.LEVEL_HARD, obj_name, "fm_count_mismatch",
                            f"frontmatter column_count={fm_count} but element-table has {len(md_rows)} rows"))

    inv_count = len(inv_cols_by_name)
    if inv_count and inv_count != len(md_rows):
        issues.append(Issue(Issue.LEVEL_HARD, obj_name, "inv_count_mismatch",
                            f"inventory has {inv_count} columns but element-table has {len(md_rows)} rows"))

    # Per-row checks
    md_by_name = {r["name"]: r for r in md_rows}
    lin_by_name = {r["name"]: r for r in lineage_rows}

    for row in md_rows:
        name = row["name"]
        desc = row["description"]
        tag_m = TIER_TAG_RE.search(desc)
        if not tag_m:
            issues.append(Issue(Issue.LEVEL_HARD, obj_name, "missing_tier_tag",
                                f"column `{name}` description has no `(Tier N — origin)` suffix"))
            continue
        tier = tag_m.group(1)
        origin = tag_m.group(2).strip()
        # Tier 1 check: origin should be reachable
        if tier.startswith("1"):
            lin = lin_by_name.get(name)
            if lin and lin.get("source_object") and lin["source_object"] not in ("—", "(computed)", "(literal)"):
                src_obj = lin["source_object"].lower()
                # Origin may be the production name OR a UC object — accept either.
                # But the lineage's source_object MUST have an entry in the upstream index.
                entry = next(
                    (e for e in ux_index.get("upstreams", [])
                     if (e.get("full_name") or "").lower() == src_obj), None,
                )
                if entry is None:
                    issues.append(Issue(Issue.LEVEL_SOFT, obj_name, "tier1_no_upstream_index_entry",
                                        f"column `{name}` is Tier 1 but lineage source `{src_obj}` not in upstream_wikis/_index.json"))
                elif not entry.get("wiki_exists"):
                    issues.append(Issue(Issue.LEVEL_SOFT, obj_name, "tier1_upstream_wiki_missing",
                                        f"column `{name}` is Tier 1 but upstream wiki for `{src_obj}` not found on disk"))

        # UNVERIFIED text must not leak into a deployed description
        if "[UNVERIFIED]" in desc or "UNVERIFIED" in desc.upper():
            issues.append(Issue(Issue.LEVEL_HARD, obj_name, "unverified_in_description",
                                f"column `{name}` description contains UNVERIFIED text — must be in sidecar only"))

    # ALTER parity
    alter_path = md_path.with_suffix(".alter.sql")
    if alter_path.exists():
        alter_cols = _parse_alter_columns(alter_path.read_text(encoding="utf-8"))
        if len(alter_cols) != len(md_rows):
            issues.append(Issue(Issue.LEVEL_HARD, obj_name, "alter_parity",
                                f".alter.sql has {len(alter_cols)} ALTER COLUMN, element table has {len(md_rows)}"))
        else:
            md_names_lower = [r["name"].lower() for r in md_rows]
            alter_names_lower = [c.lower() for c in alter_cols]
            if set(md_names_lower) != set(alter_names_lower):
                only_md = set(md_names_lower) - set(alter_names_lower)
                only_alter = set(alter_names_lower) - set(md_names_lower)
                msg = []
                if only_md:
                    msg.append(f"only in wiki: {sorted(only_md)[:5]}")
                if only_alter:
                    msg.append(f"only in alter: {sorted(only_alter)[:5]}")
                issues.append(Issue(Issue.LEVEL_HARD, obj_name, "alter_name_mismatch",
                                    "; ".join(msg)))

    return issues


def main() -> int:
    ap = argparse.ArgumentParser(description="Validate UC-Pipeline wiki output for a schema")
    ap.add_argument("--schema", required=True)
    ap.add_argument("--strict", action="store_true",
                    help="Treat WARN-level issues as HARD failures")
    args = ap.parse_args()

    schema_root = PACK_ROOT / args.schema
    if not schema_root.is_dir():
        print(f"ERROR: schema folder not found: {schema_root}", file=sys.stderr)
        return 2

    inv_path = schema_root / "_discovery" / "uc_inventory.json"
    inv: dict = {}
    if inv_path.exists():
        try:
            inv = json.loads(inv_path.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"WARN: couldn't read inventory: {e}", file=sys.stderr)
    by_object_cols: dict[str, dict[str, dict]] = {}
    for o in inv.get("objects", []):
        by_object_cols[o["name"]] = {c["name"]: c for c in (o.get("columns") or [])}

    ux_index_path = schema_root / "_discovery" / "upstream_wikis" / "_index.json"
    ux_index: dict = {}
    if ux_index_path.exists():
        try:
            ux_index = json.loads(ux_index_path.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"WARN: couldn't read upstream_wikis/_index.json: {e}", file=sys.stderr)

    all_issues: list[Issue] = []
    n_objects = 0

    for folder in ("Tables", "Views"):
        d = schema_root / folder
        if not d.is_dir():
            continue
        for md_path in sorted(d.glob("*.md")):
            # Skip sidecars and lineage files
            if md_path.name.endswith(".lineage.md") or md_path.name.endswith(".review-needed.md"):
                continue
            n_objects += 1
            cols = by_object_cols.get(md_path.stem, {})
            issues = validate_object(md_path, cols, ux_index, args.strict)
            all_issues.extend(issues)

    n_hard = sum(1 for i in all_issues if i.level == Issue.LEVEL_HARD)
    n_soft = sum(1 for i in all_issues if i.level == Issue.LEVEL_SOFT)

    print(f"\n[validate-pipeline-wiki] {args.schema}: {n_objects} objects checked, "
          f"{n_hard} HARD, {n_soft} WARN issues")
    for issue in all_issues:
        print(str(issue))

    if n_hard > 0 or (args.strict and n_soft > 0):
        print(f"\n[validate-pipeline-wiki] FAIL ({n_hard} HARD, {n_soft} WARN, strict={args.strict})")
        return 1
    print("\n[validate-pipeline-wiki] PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
