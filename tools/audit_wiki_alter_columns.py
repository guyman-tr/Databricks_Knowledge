"""Audit wiki column catalogs vs ALTER COLUMN COMMENT in paired .alter.sql files."""
from __future__ import annotations

import importlib.util
import json
import re
from pathlib import Path

WIKI_ROOT = Path(__file__).resolve().parents[1] / "knowledge" / "synapse" / "Wiki"
SCHEMAS = ["DWH_dbo", "BI_DB_dbo", "Dealing_dbo"]

_merge_path = Path(__file__).resolve().parent / "merge_wiki_column_comments_into_alter.py"
_spec = importlib.util.spec_from_file_location("_merge_wiki_audit", _merge_path)
_merge_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader
_spec.loader.exec_module(_merge_mod)
parse_wiki_column_catalog = _merge_mod.parse_wiki_column_catalog

# Works even when ALTER TABLE <ref> is multi-token or malformed (e.g. placeholder text).
ALT_COL_COMMENT_RE = re.compile(
    r"ALTER\s+COLUMN\s+([^\s]+)\s+COMMENT\s+",
    re.IGNORECASE,
)


def parse_wiki_columns_strict(text: str) -> list[str]:
    """Same rules as merge_wiki_column_comments_into_alter (typed Elements rows only)."""
    return [name for name, _desc in parse_wiki_column_catalog(text)]


def parse_alter_columns(text: str) -> list[str]:
    out: list[str] = []
    for m in ALT_COL_COMMENT_RE.finditer(text):
        name = m.group(1).strip().strip("`")
        if name.lower() == "column":
            continue
        out.append(name)
    return out


def find_md_pairs(schema_dir: Path):
    for md in sorted(schema_dir.rglob("*.md")):
        rel = md.relative_to(schema_dir)
        parts = rel.parts
        if len(parts) < 2:
            continue
        if md.name.endswith(".lineage.md") or md.name.endswith(".review-needed.md"):
            continue
        if md.name.startswith("_"):
            continue
        if parts[0] not in ("Tables", "Views", "Functions"):
            continue
        stem = md.stem
        alter = md.with_name(stem + ".alter.sql")
        yield md, alter if alter.exists() else None


def load_generic_pipeline_uc_synapse_objects() -> set[tuple[str, str]] | None:
    """(schema_name, table_name) for sql_dp_prod_we rows that have a uc_table.

    Source: `_generic_pipeline_mapping.json` (static Generic Pipeline export).
    If the file is missing or invalid, returns None (do not assume 'no UC').
    """
    p = WIKI_ROOT / "_generic_pipeline_mapping.json"
    if not p.exists():
        return None
    try:
        data = json.loads(p.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return None
    out: set[tuple[str, str]] = set()
    for m in data.get("mappings", []):
        if m.get("database_name") != "sql_dp_prod_we":
            continue
        sch = (m.get("schema_name") or "").strip()
        tbl = (m.get("table_name") or "").strip()
        uc = (m.get("uc_table") or "").strip()
        if sch and tbl and uc:
            out.add((sch, tbl))
    return out


def parse_wiki_rel_parts(wiki_rel: str) -> tuple[str, str, str] | None:
    """Return (synapse_schema, folder, object_stem) e.g. (DWH_dbo, Tables, Dim_Mirror)."""
    parts = wiki_rel.replace("\\", "/").split("/")
    if len(parts) < 3:
        return None
    sch, folder, fname = parts[0], parts[1], parts[2]
    if folder not in ("Tables", "Views", "Functions"):
        return None
    return sch, folder, Path(fname).stem


def fmt_list(names: list[str], limit: int = 50) -> str:
    if not names:
        return ""
    if len(names) <= limit:
        return "`" + "`, `".join(names) + "`"
    head = names[:limit]
    return "`" + "`, `".join(head) + f"` … (+{len(names) - limit} more)"


def main() -> None:
    rows: list[dict] = []
    for sch in SCHEMAS:
        base = WIKI_ROOT / sch
        if not base.exists():
            continue
        for md_path, alt_path in find_md_pairs(base):
            text = md_path.read_text(encoding="utf-8", errors="replace")
            wiki_cols = parse_wiki_columns_strict(text)
            if not wiki_cols:
                continue
            rel = str(md_path.relative_to(WIKI_ROOT)).replace("\\", "/")
            if alt_path is None:
                rows.append(
                    {
                        "schema": sch,
                        "wiki": rel,
                        "alter": None,
                        "wiki_n": len(wiki_cols),
                        "alter_n": 0,
                        "missing_in_alter": wiki_cols,
                        "extra_in_alter": [],
                    }
                )
                continue
            alt_text = alt_path.read_text(encoding="utf-8", errors="replace")
            alt_cols = parse_alter_columns(alt_text)
            wset, aset = set(wiki_cols), set(alt_cols)
            missing = sorted(wset - aset)
            extra = sorted(aset - wset)
            rows.append(
                {
                    "schema": sch,
                    "wiki": rel,
                    "alter": str(alt_path.relative_to(WIKI_ROOT)).replace("\\", "/"),
                    "wiki_n": len(wiki_cols),
                    "alter_n": len(alt_cols),
                    "missing_in_alter": missing,
                    "extra_in_alter": extra,
                }
            )

    uc_synapse = load_generic_pipeline_uc_synapse_objects()

    def no_alter_expected(wiki_rel: str, alter_path: str | None) -> bool:
        """Skip when no paired .alter.sql is expected for UC COMMENT deployment.

        - If mapping file is missing: legacy rule — only Views/Functions without alter are skipped.
        - If mapping is loaded: skip any Table/View/Function without alter when that Synapse object
          is not listed in Generic Pipeline (no ``uc_table`` row → no gold UC target).
        """
        if alter_path is not None:
            return False
        parsed = parse_wiki_rel_parts(wiki_rel)
        if not parsed:
            return False
        syn_schema, _folder, stem = parsed
        if uc_synapse is None:
            return _folder in ("Views", "Functions")
        return (syn_schema, stem) not in uc_synapse

    mismatch = [
        r
        for r in rows
        if not no_alter_expected(r["wiki"], r["alter"])
        and (r["missing_in_alter"] or r["extra_in_alter"] or r["alter"] is None)
    ]
    parity_ok = sum(
        1
        for r in rows
        if r["alter"] is not None
        and not r["missing_in_alter"]
        and not r["extra_in_alter"]
    )
    skipped_total = sum(
        1 for r in rows if no_alter_expected(r["wiki"], r["alter"])
    )
    skipped_breakdown: dict[str, int] = {}
    for r in rows:
        if not no_alter_expected(r["wiki"], r["alter"]):
            continue
        p = parse_wiki_rel_parts(r["wiki"])
        if not p:
            continue
        _sch, folder, _stem = p
        key = (
            f"{folder} (mapping missing)"
            if uc_synapse is None and folder in ("Views", "Functions")
            else folder
        )
        skipped_breakdown[key] = skipped_breakdown.get(key, 0) + 1

    out = WIKI_ROOT / "_audit_wiki_alter_column_parity.md"
    lines = [
        "# Wiki vs alter.sql column COMMENT parity audit",
        "",
        "Automated scan: typed **Elements** rows in `.md` (same rules as merge script) vs "
        "`ALTER COLUMN ... COMMENT` lines in paired `.alter.sql`.",
        "",
        "**Caveats:**",
        "- Wiki side uses the same **typed Elements** parser as `merge_wiki_column_comments_into_alter.py` "
        "(ordinal + column + SQL type + description). Value-map / narrative tables are ignored.",
        "- Odd column names (`+`, `%`, spaces in name) may be omitted from wiki counts — verify manually.",
        "- Alter side matches `ALTER COLUMN … COMMENT` even if `ALTER TABLE` reference is malformed.",
        "- **No `.alter.sql` expected** when `_generic_pipeline_mapping.json` lists no UC row for that "
        "Synapse `(schema_name, table_name)` (same stem as the wiki file). Mapping is a static snapshot "
        f"(`exported_at` in JSON). **Database:** `sql_dp_prod_we` only.",
        "- If the mapping file is missing, only **Views/Functions** without alter are skipped (legacy); "
        "tables without alter still need attention.",
        "- Objects with a paired `.alter.sql` are always audited (including manually maintained view alters).",
        "",
        "## Summary",
        "",
        "| Metric | Count |",
        "|--------|------:|",
        f"| Wiki objects with parsed catalog columns | {len(rows)} |",
        f"| Skipped (no .alter — not in Generic UC mapping or legacy Views/Functions) | {skipped_total} |",
        f"| Parity OK (has `.alter.sql`, wiki vs parsed COMMENT columns match) | {parity_ok} |",
        f"| Needs attention | {len(mismatch)} |",
        "",
    ]
    if skipped_breakdown:
        lines.extend(
            [
                "### Skipped breakdown",
                "",
                "| Kind | Count |",
                "|------|------:|",
            ]
        )
        for k in sorted(skipped_breakdown.keys()):
            lines.append(f"| {k} | {skipped_breakdown[k]} |")
        lines.append("")
    lines.extend(
        [
            "",
            "## By schema (needs attention)",
            "",
        ]
    )
    by_sch: dict[str, list] = {}
    for r in mismatch:
        by_sch.setdefault(r["schema"], []).append(r)
    for sch in SCHEMAS:
        if sch not in by_sch:
            continue
        lines.append(f"### {sch}")
        lines.append("")
        lines.append(f"| Wiki | Alter? | wiki_n | alter_n | missing | extra |")
        lines.append("|------|--------|-------:|--------:|--------:|------|")
        for r in sorted(by_sch[sch], key=lambda x: x["wiki"]):
            alt_mark = "yes" if r["alter"] else "**NO**"
            mn = len(r["missing_in_alter"])
            en = len(r["extra_in_alter"])
            lines.append(
                f"| `{r['wiki']}` | {alt_mark} | {r['wiki_n']} | {r['alter_n']} | {mn} | {en} |"
            )
        lines.append("")

    lines.append("## Detail: missing and extra columns")
    lines.append("")
    for r in sorted(mismatch, key=lambda x: (x["schema"], x["wiki"])):
        lines.append(f"### `{r['wiki']}`")
        lines.append("")
        if r["alter"] is None:
            lines.append("- **Alter file:** missing")
        else:
            lines.append(f"- **Alter file:** `{r['alter']}`")
        lines.append(f"- **wiki_n:** {r['wiki_n']}  **alter_n:** {r['alter_n']}")
        if r["missing_in_alter"]:
            lines.append(
                f"- **Missing in alter ({len(r['missing_in_alter'])}):** {fmt_list(r['missing_in_alter'])}"
            )
        if r["extra_in_alter"]:
            lines.append(
                f"- **Extra in alter ({len(r['extra_in_alter'])}):** {fmt_list(r['extra_in_alter'])}"
            )
        lines.append("")

    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {out}")
    print(f"Total wiki objects with columns: {len(rows)}")
    print(f"Skipped (no alter expected): {skipped_total}")
    print(f"Parity OK (alter + match): {parity_ok}")
    print(f"Needs attention: {len(mismatch)}")


if __name__ == "__main__":
    main()
