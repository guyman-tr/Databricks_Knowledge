"""Create paired .alter.sql for wiki Tables/Views that have Generic Pipeline UC mapping but no alter file.

Uses `_generic_pipeline_mapping.json` (sql_dp_prod_we) and wiki element catalog for column COMMENT lines.
Run from repo root: python tools/scaffold_missing_uc_alter_files.py
"""
from __future__ import annotations

import importlib.util
import json
import re
from datetime import datetime, timezone
from pathlib import Path

WIKI_ROOT = Path(__file__).resolve().parents[1] / "knowledge" / "synapse" / "Wiki"
SCHEMAS = ["DWH_dbo", "BI_DB_dbo", "Dealing_dbo", "eMoney_dbo", "EXW_Wallet"]
MAPPING_PATH = WIKI_ROOT / "_generic_pipeline_mapping.json"

_mpath = Path(__file__).resolve().parent / "merge_wiki_column_comments_into_alter.py"
_spec = importlib.util.spec_from_file_location("_merge_wiki", _mpath)
_merge = importlib.util.module_from_spec(_spec)
assert _spec.loader
_spec.loader.exec_module(_merge)
parse_wiki_column_catalog = _merge.parse_wiki_column_catalog
format_comment_line = _merge.format_comment_line
sql_string_for_comment = _merge.sql_string_for_comment


def full_uc_qualifier(uc_table: str) -> str:
    """Match existing wiki alters: two-part mapping names get `main.` except pii_data.*."""
    t = uc_table.strip()
    if not t:
        return t
    parts = t.split(".")
    if len(parts) == 2:
        catalog, _tbl = parts
        if catalog == "pii_data":
            return t
        return f"main.{catalog}.{parts[1]}"
    if len(parts) >= 3:
        return t
    return t


def load_uc_by_syn_object() -> dict[tuple[str, str], str]:
    raw = json.loads(MAPPING_PATH.read_text(encoding="utf-8"))
    out: dict[tuple[str, str], str] = {}
    for m in raw.get("mappings", []):
        if m.get("database_name") != "sql_dp_prod_we":
            continue
        uc = (m.get("uc_table") or "").strip()
        sch = (m.get("schema_name") or "").strip()
        tbl = (m.get("table_name") or "").strip()
        if sch and tbl and uc:
            out[(sch, tbl)] = uc
    return out


def extract_table_blurb(md_text: str, max_len: int = 900) -> str:
    lines = md_text.splitlines()
    for i, line in enumerate(lines):
        if line.startswith("# ") and not line.startswith("## "):
            title = line[2:].strip()
            chunks = [title]
            for j in range(i + 1, min(i + 40, len(lines))):
                ln = lines[j]
                if ln.startswith("#") and not ln.startswith("###"):
                    break
                s = ln.strip()
                if s and not s.startswith("<!--"):
                    chunks.append(s)
            text = " ".join(chunks)
            text = re.sub(r"\s+", " ", text).strip()
            return text[:max_len] if text else ""
    return ""


def build_alter_content(
    *,
    syn_schema: str,
    object_name: str,
    full_uc: str,
    cols: list[tuple[str, str]],
    table_blurb: str,
) -> str:
    if not table_blurb:
        table_blurb = (
            f"Synapse {syn_schema}.{object_name}. "
            "Semantic documentation in paired wiki. Scaffolded for UC column comments."
        )
    esc_blurb = sql_string_for_comment(table_blurb, max_len=1024)
    gen = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    lines = [
        "-- =============================================================================",
        f"-- Databricks ALTER Script: {syn_schema}.{object_name}",
        f"-- Generated: {gen} | scaffold_missing_uc_alter_files.py",
        "-- Target: Unity Catalog table comment + column comments (1024 char limit)",
        f"-- UC Target: {full_uc}",
        "-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)",
        "-- =============================================================================",
        "",
        "-- ---- Table Comment ----",
        f"ALTER TABLE {full_uc} SET TBLPROPERTIES (",
        f"    'comment' = '{esc_blurb}'",
        ");",
        "",
        "-- ---- Table Tags ----",
        f"ALTER TABLE {full_uc} SET TAGS (",
        f"    'source_schema' = '{syn_schema}',",
        "    'source_system' = 'Synapse',",
        "    'pipeline' = 'dwh-semantic-doc',",
        "    'pipeline_version' = 'scaffold-uc-alter'",
        ");",
        "",
        "-- ---- Column Comments ----",
    ]
    for col, desc in cols:
        lines.append(format_comment_line(full_uc, col, desc))
    lines.append("")
    lines.append("-- ---- Column PII Tags ----")
    for col, _ in cols:
        lines.append(
            f"ALTER TABLE {full_uc} ALTER COLUMN {col} SET TAGS ('pii' = 'none');"
        )
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    if not MAPPING_PATH.exists():
        raise SystemExit(f"missing {MAPPING_PATH}")
    uc_map = load_uc_by_syn_object()
    created = 0
    skipped = 0
    for sch in SCHEMAS:
        base = WIKI_ROOT / sch
        if not base.exists():
            continue
        for md in sorted(base.rglob("*.md")):
            if md.name.endswith(".lineage.md") or md.name.endswith(".review-needed.md"):
                continue
            if md.name.startswith("_"):
                continue
            rel = md.relative_to(base)
            if len(rel.parts) < 2 or rel.parts[0] not in ("Tables", "Views"):
                continue
            stem = md.stem
            alt = md.with_name(stem + ".alter.sql")
            if alt.exists():
                continue
            uc_raw = uc_map.get((sch, stem))
            if not uc_raw:
                skipped += 1
                continue
            wtext = md.read_text(encoding="utf-8", errors="replace")
            cols = parse_wiki_column_catalog(wtext)
            if not cols:
                print(f"SKIP no wiki columns parsed: {sch}/{rel}")
                skipped += 1
                continue
            full_uc = full_uc_qualifier(uc_raw)
            blurb = extract_table_blurb(wtext)
            body = build_alter_content(
                syn_schema=sch,
                object_name=stem,
                full_uc=full_uc,
                cols=cols,
                table_blurb=blurb,
            )
            alt.write_text(body, encoding="utf-8")
            print(f"CREATED {alt.relative_to(WIKI_ROOT)}")
            created += 1
    print(f"Done: {created} created, {skipped} skipped (no mapping or no parsed columns)")


if __name__ == "__main__":
    main()
