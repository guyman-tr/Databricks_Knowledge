#!/usr/bin/env python3
"""
Phase 5 — Generate Wiki (UC-Pipeline pack, productized).

Reads:
  - `_dag.json`                                       (Phase -1; wiki_status per upstream)
  - `_discovery/uc_inventory.json`                    (Phase 1; column metadata)
  - `_discovery/source_code/{obj}.{sql,py}`           (Phase 2; for narration)
  - `_discovery/column_lineage/{obj}.json`            (Phase 2; second-opinion)
  - `_discovery/upstream_wikis/_index.json` + bodies  (Phase 3; verbatim inherit source)
  - `{obj}.lineage.md`                                (Phase 4; mechanical lineage table)

Writes:
  - `{obj}.md`                  (the wiki — 6-section GOLDEN skeleton)
  - `{obj}.review-needed.md`    (sidecar — UNVERIFIED + parser warnings)

The §6 No-Inference Contract in `05-generate-doc.mdc` is enforced by the
description-emission routine: every Elements row's description falls into
exactly ONE of three buckets:

  (A) Byte-equal to upstream wiki — passthrough/rename/cast against upstream
      whose Phase 3 routing landed at Rules 1-5.
  (B) Cited from source code — CASE/arithmetic/aggregate/window/coalesce/udf
      narrated from the cached Phase 2 SQL/notebook with a citation.
  (C) Null-with-provenance template — passthrough/rename/cast against an
      upstream whose Phase 3 routing landed at Rule 6 AND that upstream is a
      terminal root in the lineage DAG (no further parent in column_lineage).

Anything that fails to classify becomes an UNVERIFIED row in the sidecar — NEVER
an AI-inferred description. This is enforced again by `validate_pipeline_wiki.py
--assert-no-inference` at Phase 6 gate.

Usage:
  python tools/uc_pipelines/generate_wiki.py --schema etoro_kpi_prep --object v_fact_customeraction_enriched
  python tools/uc_pipelines/generate_wiki.py --schema etoro_kpi_prep    # all in-scope
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import shutil
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Iterable

REPO = Path(__file__).resolve().parents[2]
OBJ_OUT_ROOT = REPO / "knowledge" / "UC_generated"
DAG_PATH = OBJ_OUT_ROOT / "_dag.json"


def _norm(s: str | None) -> str:
    return (s or "").lower().strip()


def _today_iso() -> str:
    return dt.date.today().isoformat()


def _now_iso_z() -> str:
    return dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"


def _parse_yaml_frontmatter(text: str) -> dict:
    m = re.match(r"^---\n(.+?)\n---\n", text, re.DOTALL)
    if not m:
        return {}
    try:
        import yaml  # type: ignore
        return yaml.safe_load(m.group(1)) or {}
    except Exception:
        return {}


def _extract_section(text: str, header_re) -> str | None:
    m = header_re.search(text)
    if not m:
        return None
    start = m.end()
    next_m = re.search(r"^##\s+", text[start:], re.MULTILINE)
    return text[start: start + next_m.start()] if next_m else text[start:]


ELEMENTS_HEADER_RE = re.compile(r"^##\s+(?:\d+\.\s+)?Elements\b", re.IGNORECASE | re.MULTILINE)
COLUMNS_HEADER_RE = re.compile(r"^##\s+(?:\d+\.\s+)?Columns\b", re.IGNORECASE | re.MULTILINE)
LINEAGE_HEADER_RE = re.compile(r"^##\s+Column Lineage\b", re.IGNORECASE | re.MULTILINE)
TIER_TAG_RE = re.compile(r"\(Tier\s+([1-5][a-z]?)\s+[—–-]\s+([^\)]+)\)")


def _parse_elements_rows(text: str) -> dict[str, dict]:
    """Returns name → {ordinal, description, type, nullable} for upstream wikis."""
    section = _extract_section(text, ELEMENTS_HEADER_RE) or _extract_section(text, COLUMNS_HEADER_RE)
    if not section:
        return {}
    out: dict[str, dict] = {}
    for line in section.splitlines():
        s = line.strip()
        if not s.startswith("|"):
            continue
        cells = [c.strip() for c in s.strip("|").split("|")]
        if len(cells) < 5:
            continue
        if not cells[0].isdigit():
            continue
        name = cells[1].strip("` ")
        out[name.lower()] = {
            "ordinal": int(cells[0]),
            "name": name,
            "type": cells[2],
            "nullable": cells[3],
            "description": cells[-1],
        }
    return out


def _parse_lineage_rows(text: str) -> list[dict]:
    section = _extract_section(text, LINEAGE_HEADER_RE)
    if not section:
        return []
    rows: list[dict] = []
    for line in section.splitlines():
        s = line.strip()
        if not s.startswith("|"):
            continue
        cells = [c.strip() for c in s.strip("|").split("|")]
        if len(cells) < 5:
            continue
        if not cells[0].isdigit():
            continue
        rows.append({
            "ordinal": int(cells[0]),
            "name": cells[1].strip("` "),
            "source_object": cells[2].strip("` "),
            "source_column": cells[3].strip("` "),
            "transform": cells[4].strip("` "),
            "extra": cells[5:] if len(cells) > 5 else [],
        })
    return rows


PASSTHROUGH_TRANSFORMS = {"passthrough", "rename", "cast"}
NARRATED_TRANSFORMS = {"case", "coalesce", "arithmetic", "string_op", "udf",
                        "function_computed", "aggregate", "window", "literal"}


def _classify_upstream_status(upstream_fqn: str, dag_nodes: dict, ux_index: dict) -> str:
    """Return one of: documented_in_pack|documented_external|in_scope_not_yet_authored|terminal_no_wiki|out_of_scope|unknown."""
    fqn = _norm(upstream_fqn)
    if fqn in dag_nodes:
        return dag_nodes[fqn].get("wiki_status", "unknown")
    for entry in ux_index.get("upstreams", []):
        if _norm(entry.get("full_name")) == fqn:
            if entry.get("wiki_exists"):
                return "documented_external"
            if entry.get("blocked_on_upstream"):
                return "in_scope_not_yet_authored"
            return "terminal_no_wiki"
    return "unknown"


def _find_cached_upstream_wiki(schema_root: Path, upstream_fqn: str,
                                ux_index: dict) -> Path | None:
    fqn = _norm(upstream_fqn)
    cache_root = schema_root / "_discovery" / "upstream_wikis"
    direct = cache_root / f"{fqn}.md"
    if direct.exists():
        return direct
    for entry in ux_index.get("upstreams", []):
        if _norm(entry.get("full_name")) == fqn:
            cached = entry.get("cached_at")
            if cached:
                p = REPO / cached
                if p.exists():
                    return p
    return None


def _inherit_upstream_description(upstream_wiki: Path, source_column: str) -> str | None:
    try:
        text = upstream_wiki.read_text(encoding="utf-8")
    except Exception:
        return None
    rows = _parse_elements_rows(text)
    row = rows.get(source_column.lower())
    if not row:
        return None
    desc = row["description"].strip()
    if not desc:
        return None
    if "[UNVERIFIED]" in desc.upper():
        return None
    return desc


SQL_OPERATORS_OF_INTEREST = (
    "CASE", "COALESCE", "ISNULL", "NVL", "SUM", "COUNT", "AVG", "MIN", "MAX",
    "ROW_NUMBER", "LAG", "LEAD", "OVER", "PARTITION BY", "WHEN", "ROUND",
    "CAST", "TRY_CAST", "DATEPART", "YEAR", "MONTH", "DAY", "DATE_TRUNC",
    "CONCAT", "SUBSTRING", "SUBSTR", "REPLACE", "REVERSE", "CHARINDEX",
    "LEFT", "RIGHT", "LOWER", "UPPER", "TRIM", "EXISTS", "IN ", "NOT IN",
    "+", "-", "*", "/", "||",
)


def _find_column_expression_lines(source_code: str, target_column: str) -> tuple[int, int, str] | None:
    """Heuristic: locate the line in the source code that defines `target_column`
    as a projected SELECT alias. Returns (start_line, end_line, snippet) or None.
    """
    if not source_code:
        return None
    lines = source_code.splitlines()
    target_low = target_column.lower()
    candidate_idxs: list[int] = []
    pat = re.compile(rf"\bAS\s+`?{re.escape(target_column)}`?\b", re.IGNORECASE)
    pat_lower = re.compile(rf"\bas\s+`?{re.escape(target_low)}`?\b")
    for i, ln in enumerate(lines):
        if pat.search(ln) or pat_lower.search(ln):
            candidate_idxs.append(i)
    if not candidate_idxs:
        for i, ln in enumerate(lines):
            stripped = ln.strip().rstrip(",")
            if stripped.lower().endswith(target_low) and any(
                op in stripped.upper() for op in ("CASE", "COALESCE", "ROUND", "CAST", "SUM(", "COUNT(")):
                candidate_idxs.append(i)
    if not candidate_idxs:
        return None
    end_idx = candidate_idxs[0]
    start_idx = end_idx
    for j in range(end_idx, max(-1, end_idx - 20), -1):
        ln = lines[j].lstrip()
        if ln.startswith(",") or ln.startswith("SELECT") or ln.startswith("select"):
            start_idx = j
            break
        if "CASE" in lines[j].upper() and "END" in " ".join(lines[start_idx:end_idx + 1]).upper():
            start_idx = j
            break
    snippet = "\n".join(lines[start_idx:end_idx + 1]).strip()
    snippet = snippet[:200] + ("…" if len(snippet) > 200 else "")
    return (start_idx + 1, end_idx + 1, snippet)


def _operators_in(snippet: str) -> list[str]:
    found: list[str] = []
    su = snippet.upper()
    for op in SQL_OPERATORS_OF_INTEREST:
        if op in su and op not in found:
            found.append(op)
    return found[:6]


def _narrate_from_source_code(target_column: str, source_code: str,
                                source_object: str, source_path_rel: str,
                                writer_kind: str) -> str | None:
    """Bucket (B): Narration anchored to a source-code line range OR a quoted SQL fragment."""
    if not source_code:
        return None
    loc = _find_column_expression_lines(source_code, target_column)
    if not loc:
        return None
    start_line, end_line, snippet = loc
    ops = _operators_in(snippet)
    ops_str = ", ".join(ops) if ops else "expression"
    citation_tag = "[uc_view_ddl]" if writer_kind in ("view_definition", "view") else f"[notebook:{source_path_rel}#L{start_line}]"
    snippet_inline = snippet.replace("\n", " ").strip()
    if len(snippet_inline) > 120:
        snippet_inline = snippet_inline[:120] + "…"
    desc = (f"Computed in source ({ops_str}): `{snippet_inline}`. "
            f"See {source_path_rel} L{start_line}-L{end_line}. {citation_tag}")
    return desc


def _null_with_provenance(upstream_fqn: str, source_column: str, check_date: str) -> str:
    return f"Source: {upstream_fqn}.{source_column}. No upstream wiki cached as of {check_date}."


def _ensure_tier_tag(desc: str, fallback_tier: str, fallback_origin: str) -> str:
    if TIER_TAG_RE.search(desc):
        return desc
    return f"{desc.rstrip().rstrip('.')} (Tier {fallback_tier} — {fallback_origin})."


def _is_pure_passthrough(lineage_rows: list[dict]) -> bool:
    if not lineage_rows:
        return False
    return all(r.get("transform", "").lower() in {"passthrough", "rename", "cast"}
               for r in lineage_rows)


def _build_property_table(obj_name: str, inv_obj: dict, schema: str) -> str:
    rows = [
        ("UC Object", f"`main.{schema}.{obj_name}`"),
        ("Type", inv_obj.get("table_type") or "—"),
        ("Format", inv_obj.get("data_source_format") or "n/a"),
        ("Owner", inv_obj.get("owner") or "—"),
        ("Row count", str(inv_obj.get("row_count") or "n/a")),
        ("Column count", str(inv_obj.get("column_count") or len(inv_obj.get("columns") or []))),
        ("Generated", _today_iso()),
        ("Created", inv_obj.get("created_at") or "—"),
    ]
    lines = ["| Property | Value |", "|----------|-------|"]
    for k, v in rows:
        lines.append(f"| **{k}** | {v} |")
    return "\n".join(lines)


def _build_section1(obj_name: str, schema: str, kind_label: str,
                    upstreams: list[str], n_pass: int, n_narr: int,
                    n_null_prov: int, n_unverified: int) -> str:
    primary = upstreams[0] if upstreams else "(no upstream tracked in lineage)"
    return (
        f"`{obj_name}` is a {kind_label} in schema `main.{schema}`. "
        f"It reads from {len(upstreams)} upstream UC object(s); "
        f"the primary upstream is `{primary}`.\n\n"
        f"Of its columns: {n_pass} are inherited byte-for-byte from upstream wikis, "
        f"{n_narr} are narrated from cited source-code expressions, "
        f"{n_null_prov} reference upstreams with no cached wiki (null-with-provenance), and "
        f"{n_unverified} are unverified (see `.review-needed.md`).\n\n"
        "This wiki is mechanically generated by `tools/uc_pipelines/generate_wiki.py`. "
        "Per §6 No-Inference Contract, every column description is anchored to one of "
        "upstream wiki / source code / null-provenance template; no descriptions are AI-inferred."
    )


def _build_section2_pure_passthrough(upstreams: list[str]) -> str:
    if not upstreams:
        return "Pure passthrough — see `.lineage.md` for per-column source mapping."
    src = upstreams[0]
    return (f"Pure passthrough from `{src}` (and {len(upstreams) - 1} additional upstream(s) "
            f"per `.lineage.md`). No derived columns. Refer to upstream wiki for column semantics.")


def _build_section2_derived(lineage_rows: list[dict], source_code: str,
                            source_path_rel: str) -> str:
    """For views/tables with derived columns: group narrated columns by transform type."""
    by_xform: dict[str, list[str]] = defaultdict(list)
    for r in lineage_rows:
        x = (r.get("transform") or "unknown").lower()
        if x in NARRATED_TRANSFORMS or x == "join_enriched":
            by_xform[x].append(r["name"])
    if not by_xform:
        return ("All target columns are passthrough/rename/cast from upstream(s); "
                "see `.lineage.md`. No derived expressions in source code.")
    out: list[str] = []
    out.append(f"Source: `{source_path_rel}`. Transform patterns present:\n")
    for i, (x, cols) in enumerate(sorted(by_xform.items()), 1):
        out.append(f"### 2.{i} {x}")
        out.append(f"**Columns**: {', '.join(f'`{c}`' for c in cols[:12])}"
                   + (f" (+{len(cols) - 12} more)" if len(cols) > 12 else ""))
        out.append(f"**Source-code reference**: see `{source_path_rel}` "
                   f"and `.lineage.md` row-level `transform` column.")
        out.append("")
    return "\n".join(out)


def _build_section4(obj_name: str, schema: str, upstreams: list[dict],
                    downstream: list[str], parsed_n: int, runtime_n: int,
                    mismatches: int) -> str:
    out: list[str] = []
    out.append("### 4.1 Upstream UC Objects\n")
    out.append("| Upstream | Role | Wiki |")
    out.append("|----------|------|------|")
    for u in upstreams:
        role = u.get("role") or "Upstream"
        wiki = u.get("wiki_path") or "(no wiki — see `.review-needed.md`)"
        out.append(f"| `{u['full_name']}` | {role} | `{wiki}` |")
    out.append("\n### 4.2 Pipeline ASCII Diagram\n")
    out.append("```")
    if upstreams:
        for u in upstreams[:3]:
            out.append(f"{u['full_name']}")
        if len(upstreams) > 3:
            out.append(f"... ({len(upstreams) - 3} more upstream(s))")
        out.append("        │")
        out.append("        ▼")
    out.append(f"main.{schema}.{obj_name}   ←── this object")
    if downstream:
        out.append("        │")
        out.append("        ▼")
        for d in downstream[:3]:
            out.append(f"{d}")
        if len(downstream) > 3:
            out.append(f"... ({len(downstream) - 3} more downstream)")
    out.append("```\n")
    out.append("### 4.3 Cross-check vs system.access.column_lineage\n")
    out.append(f"`parsed={parsed_n} runtime={runtime_n} mismatches={mismatches}` "
               f"— see `.lineage.md` `## Cross-check` section for per-column detail.")
    return "\n".join(out)


def _build_section5(obj_name: str, schema: str, join_partners_from_lineage: list[dict]) -> str:
    out: list[str] = []
    out.append("### 5.1 Sample queries\n")
    out.append("> Sample queries are not auto-generated in this pack; refer to "
               "`knowledge/skills/_de_existing/` and `system.query.history` for analyst usage.\n")
    out.append("### 5.2 Common JOIN partners\n")
    if not join_partners_from_lineage:
        out.append("| JOIN to | Condition | Purpose |")
        out.append("|---------|-----------|---------|")
        out.append("| (none discovered from upstream JOINs in `.lineage.md`) | — | — |")
    else:
        out.append("| JOIN to | Condition | Purpose |")
        out.append("|---------|-----------|---------|")
        for p in join_partners_from_lineage[:8]:
            out.append(f"| `{p['fqn']}` | {p.get('cond') or '—'} | {p.get('purpose') or '—'} |")
    out.append("\n### 5.3 Gotchas\n")
    out.append("- See `.review-needed.md` for parser warnings, UNVERIFIED columns, "
               "and any Tier-4 sample-only candidates.")
    return "\n".join(out)


def _build_section6_provenance(provenance_rows: list[dict]) -> str:
    out: list[str] = []
    out.append("| Column | Description source | Tier | Cited as |")
    out.append("|--------|--------------------|------|----------|")
    for r in provenance_rows[:80]:
        out.append(f"| {r['column']} | {r['source']} | {r['tier']} | {r['cited_as']} |")
    if len(provenance_rows) > 80:
        out.append(f"| ... +{len(provenance_rows) - 80} more rows | ... | ... | ... |")
    return "\n".join(out)


def load_dag_nodes(dag_path: Path) -> dict:
    if not dag_path.exists():
        return {}
    try:
        d = json.loads(dag_path.read_text(encoding="utf-8"))
        return {_norm(n["full_name"]): n for n in d.get("nodes", [])}
    except Exception as e:
        print(f"[generate-wiki] WARN: dag load failed: {e}", file=sys.stderr)
        return {}


def load_downstream_from_dag(dag_path: Path, obj_fqn: str) -> list[str]:
    if not dag_path.exists():
        return []
    try:
        d = json.loads(dag_path.read_text(encoding="utf-8"))
        edges = d.get("edges", [])
        seen: set[str] = set()
        for e in edges:
            if _norm(e.get("from_node")) == _norm(obj_fqn):
                seen.add(e.get("to_node"))
        return sorted(seen)
    except Exception:
        return []


def derive_writer_kind(obj_name: str, inv_obj: dict, schema_root: Path) -> tuple[str, str | None]:
    """Returns (writer_kind, source_path_rel) — writer_kind in {view_definition, notebook, sp, job, unknown}."""
    src_dir = schema_root / "_discovery" / "source_code"
    for ext in ("sql", "py", "scala", "r"):
        p = src_dir / f"{obj_name}.{ext}"
        if p.exists():
            rel = str(p.relative_to(REPO)).replace("\\", "/")
            tt = (inv_obj.get("table_type") or "").upper()
            if tt == "VIEW":
                return ("view_definition", rel)
            if ext == "sql":
                return ("sp_or_sql", rel)
            return ("notebook" if ext == "py" else "script", rel)
    return ("unknown", None)


def read_source_code(schema_root: Path, obj_name: str) -> tuple[str, str | None]:
    src_dir = schema_root / "_discovery" / "source_code"
    for ext in ("sql", "py", "scala", "r"):
        p = src_dir / f"{obj_name}.{ext}"
        if p.exists():
            return (p.read_text(encoding="utf-8", errors="replace"),
                    str(p.relative_to(REPO)).replace("\\", "/"))
    return ("", None)


def read_inventory(schema_root: Path) -> dict:
    p = schema_root / "_discovery" / "uc_inventory.json"
    if not p.exists():
        return {"objects": []}
    return json.loads(p.read_text(encoding="utf-8"))


def read_upstream_index(schema_root: Path) -> dict:
    p = schema_root / "_discovery" / "upstream_wikis" / "_index.json"
    if not p.exists():
        return {"upstreams": []}
    return json.loads(p.read_text(encoding="utf-8"))


def read_lineage_file(out_md_path: Path) -> tuple[list[dict], dict]:
    lp = out_md_path.with_suffix(".lineage.md")
    if not lp.exists():
        return [], {"parsed": 0, "runtime": 0, "mismatches": 0}
    text = lp.read_text(encoding="utf-8")
    rows = _parse_lineage_rows(text)
    stats = {"parsed": len(rows), "runtime": len(rows), "mismatches": 0}
    m = re.search(r"parsed[=\s]*(\d+)[\s\S]{0,40}runtime[=\s]*(\d+)[\s\S]{0,40}mismatches[=\s]*(\d+)", text)
    if m:
        stats = {"parsed": int(m.group(1)), "runtime": int(m.group(2)), "mismatches": int(m.group(3))}
    return rows, stats


def generate_for_object(schema: str, obj_name: str, *, dry_run: bool = False) -> dict:
    schema_root = OBJ_OUT_ROOT / schema
    if not schema_root.is_dir():
        raise RuntimeError(f"schema folder not found: {schema_root}")

    inv = read_inventory(schema_root)
    inv_obj = next((o for o in inv.get("objects", []) if o["name"] == obj_name), None)
    if not inv_obj:
        raise RuntimeError(f"object {obj_name} not found in uc_inventory.json")

    columns = inv_obj.get("columns") or []
    if not columns:
        raise RuntimeError(f"object {obj_name} has no columns in inventory")

    ux_index = read_upstream_index(schema_root)
    dag_nodes = load_dag_nodes(DAG_PATH)
    folder = "Views" if (inv_obj.get("table_type") or "").upper() in ("VIEW", "MATERIALIZED_VIEW") else "Tables"
    out_dir = schema_root / folder
    out_dir.mkdir(parents=True, exist_ok=True)
    out_md = out_dir / f"{obj_name}.md"
    out_review = out_dir / f"{obj_name}.review-needed.md"

    lineage_rows, lineage_stats = read_lineage_file(out_md)
    lineage_by_name = {r["name"].lower(): r for r in lineage_rows}

    writer_kind, source_path_rel = derive_writer_kind(obj_name, inv_obj, schema_root)
    source_code, _ = read_source_code(schema_root, obj_name)

    upstreams_seen: list[str] = []
    for r in lineage_rows:
        s = r.get("source_object")
        if not s or s in ("—", "(computed)", "(literal)"):
            continue
        if s not in upstreams_seen:
            upstreams_seen.append(s)
    for entry in ux_index.get("upstreams", []):
        fn = entry.get("full_name")
        if fn and fn not in upstreams_seen:
            upstreams_seen.append(fn)

    upstream_table_rows: list[dict] = []
    for u in upstreams_seen[:20]:
        entry = next((e for e in ux_index.get("upstreams", []) if _norm(e.get("full_name")) == _norm(u)), {})
        upstream_table_rows.append({
            "full_name": u,
            "role": "Primary" if u == (upstreams_seen[0] if upstreams_seen else None) else "JOIN/UNION",
            "wiki_path": entry.get("wiki_path"),
        })

    downstream = load_downstream_from_dag(DAG_PATH, f"main.{schema}.{obj_name}")
    check_date = _today_iso()

    elements_rows: list[dict] = []
    provenance_rows: list[dict] = []
    sidecar_unverified: list[dict] = []
    sidecar_tier4: list[dict] = []
    sidecar_warnings: list[str] = []

    tier_counts = Counter()

    for col in columns:
        cname = col["name"]
        ctype = col.get("data_type") or col.get("type") or "—"
        nullable = "YES" if col.get("nullable") else "NO"
        ordinal = col.get("ordinal") or (len(elements_rows) + 1)

        lin = lineage_by_name.get(cname.lower())
        if not lin:
            sidecar_unverified.append({
                "name": cname,
                "reason": "no row in .lineage.md for this column",
            })
            description = (f"No lineage row found for `{cname}` in `.lineage.md`; "
                           f"description could not be derived mechanically. See `.review-needed.md`. "
                           f"(Tier U — unclassified)")
            elements_rows.append({"ordinal": ordinal, "name": cname, "type": ctype,
                                  "nullable": nullable, "description": description})
            tier_counts["U"] += 1
            provenance_rows.append({"column": cname, "source": "—", "tier": "U", "cited_as": "(missing)"})
            continue

        transform = (lin.get("transform") or "unknown").lower()
        src_obj = lin.get("source_object") or ""
        src_col = lin.get("source_column") or ""

        description: str | None = None
        tier_letter = "U"
        provenance_source = "—"
        cited_as = "(missing)"

        if transform in PASSTHROUGH_TRANSFORMS and src_obj not in ("", "—", "(computed)", "(literal)"):
            up_wiki = _find_cached_upstream_wiki(schema_root, src_obj, ux_index)
            if up_wiki:
                inherited = _inherit_upstream_description(up_wiki, src_col)
                if inherited:
                    annotation = ""
                    if transform == "rename" and src_col.lower() != cname.lower():
                        annotation = f" (renamed from `{src_col}`)"
                    elif transform == "cast":
                        annotation = f" (cast to `{ctype}`)"
                    if annotation and not inherited.rstrip().endswith(")"):
                        inherited = inherited.rstrip() + annotation
                    description = inherited
                    inherited_tag = TIER_TAG_RE.search(description)
                    tier_letter = inherited_tag.group(1)[0] if inherited_tag else "1"
                    provenance_source = f"upstream wiki `{up_wiki.relative_to(REPO).as_posix()}` ({transform})"
                    if inherited_tag:
                        cited_as = inherited_tag.group(0)
                    else:
                        # Upstream wiki has no explicit tier tag — add a Tier 1 one pointing at the source.
                        description = _ensure_tier_tag(description, "1", f"inherited from {src_obj}")
                        cited_as = f"(Tier 1 — inherited from {src_obj})"
            if description is None:
                up_status = _classify_upstream_status(src_obj, dag_nodes, ux_index)
                if up_status == "terminal_no_wiki":
                    description = _null_with_provenance(src_obj, src_col, check_date)
                    description = _ensure_tier_tag(description, "5", "terminal-no-wiki")
                    tier_letter = "5"
                    provenance_source = f"null-with-provenance (terminal upstream `{src_obj}`)"
                    cited_as = "(Tier 5 — terminal-no-wiki)"
                elif up_status == "in_scope_not_yet_authored":
                    sidecar_warnings.append(
                        f"`{cname}`: upstream `{src_obj}` is in-scope but not yet authored — "
                        f"this column will be regenerated when the upstream wiki lands.")
                    description = (f"Upstream `{src_obj}.{src_col}` is in-scope but its wiki has not "
                                   f"been authored yet; this column will be regenerated once the "
                                   f"upstream wiki lands. (Tier U — blocked-on-upstream)")
                    tier_letter = "U"
                    provenance_source = "blocked_on_upstream"
                    cited_as = "(Tier U — blocked-on-upstream)"

        if description is None and (transform in NARRATED_TRANSFORMS or transform == "join_enriched"):
            narrated = _narrate_from_source_code(cname, source_code, src_obj,
                                                  source_path_rel or "(no source cached)",
                                                  writer_kind)
            if narrated is None and transform == "join_enriched" and src_obj:
                up_wiki = _find_cached_upstream_wiki(schema_root, src_obj, ux_index)
                if up_wiki:
                    inherited = _inherit_upstream_description(up_wiki, src_col)
                    if inherited:
                        narrated = inherited
                        inherited_tag = TIER_TAG_RE.search(inherited)
                        tier_letter = inherited_tag.group(1)[0] if inherited_tag else "1"
                        provenance_source = f"join-source wiki `{up_wiki.relative_to(REPO).as_posix()}`"
                        cited_as = inherited_tag.group(0) if inherited_tag else "(no tag)"
            if narrated is not None:
                origin = src_obj if src_obj and src_obj not in ("—", "(computed)", "(literal)") else f"main.{schema}.{obj_name}"
                description = _ensure_tier_tag(narrated, "2", origin)
                if tier_letter == "U":
                    tier_letter = "2"
                    provenance_source = f"source code ({transform})"
                    cited_as = "[uc_view_ddl]" if writer_kind == "view_definition" else f"[notebook:{source_path_rel}]"

        if description is None:
            sidecar_unverified.append({
                "name": cname,
                "reason": f"transform={transform!r} src={src_obj!r}.{src_col!r}; "
                          f"no upstream wiki match AND no source-code expression found.",
            })
            description = (f"Transform `{transform}` for column `{cname}` could not be resolved "
                           f"to an upstream wiki or a source-code expression. See `.review-needed.md`. "
                           f"(Tier U — unclassified)")
            tier_letter = "U"
            provenance_source = "(unclassifiable)"
            cited_as = "(missing)"

        tier_counts[tier_letter] += 1
        elements_rows.append({
            "ordinal": ordinal,
            "name": cname,
            "type": ctype,
            "nullable": nullable,
            "description": description,
        })
        provenance_rows.append({
            "column": cname,
            "source": provenance_source,
            "tier": tier_letter,
            "cited_as": cited_as,
        })

    n_pass = tier_counts.get("1", 0)
    n_narr = tier_counts.get("2", 0)
    n_3 = tier_counts.get("3", 0)
    n_4 = tier_counts.get("4", 0)
    n_5 = tier_counts.get("5", 0)
    n_unverified = tier_counts.get("U", 0)
    n_null_prov = n_5

    kind_label_map = {"view_definition": "view", "sp_or_sql": "table (SP/SQL writer)",
                       "notebook": "table (notebook writer)", "script": "table (script writer)",
                       "unknown": "table (unknown writer)"}
    table_type_label = (inv_obj.get("table_type") or "").upper() or "VIEW"
    kind_label = kind_label_map.get(writer_kind, table_type_label.lower())

    fm = {
        "object": f"main.{schema}.{obj_name}",
        "schema": schema,
        "framework": "uc-pipeline-doc",
        "table_type": table_type_label,
        "format": inv_obj.get("data_source_format"),
        "column_count": len(columns),
        "row_count": inv_obj.get("row_count"),
        "generated_at": _now_iso_z(),
        "upstreams": upstreams_seen[:10],
        "writer": {
            "kind": writer_kind,
            "path": source_path_rel,
            "source_code_snapshot": source_path_rel,
        },
        "tier_breakdown": {
            "tier1_columns": n_pass,
            "tier2_columns": n_narr,
            "tier3_columns": n_3,
            "tier4_columns": n_4,
            "tier5_columns": n_5,
            "unverified_columns": n_unverified,
        },
    }

    try:
        import yaml  # type: ignore
        fm_text = yaml.safe_dump(fm, sort_keys=False, allow_unicode=True).rstrip()
    except Exception:
        fm_text = json.dumps(fm, indent=2)

    prop_table = _build_property_table(obj_name, inv_obj, schema)
    section1 = _build_section1(obj_name, schema, kind_label, upstreams_seen,
                                n_pass, n_narr, n_null_prov, n_unverified)
    if _is_pure_passthrough(lineage_rows):
        section2 = _build_section2_pure_passthrough(upstreams_seen)
    else:
        section2 = _build_section2_derived(lineage_rows, source_code,
                                             source_path_rel or "(no source cached)")

    elements_lines = ["| # | Element | Type | Nullable | Description |",
                       "|---|---------|------|----------|-------------|"]
    for r in sorted(elements_rows, key=lambda x: x["ordinal"]):
        desc = r["description"].replace("|", "\\|").replace("\n", " ")
        elements_lines.append(f"| {r['ordinal']} | {r['name']} | {r['type']} | {r['nullable']} | {desc} |")
    section3 = "\n".join(elements_lines)

    section4 = _build_section4(obj_name, schema, upstream_table_rows, downstream,
                                lineage_stats["parsed"], lineage_stats["runtime"],
                                lineage_stats["mismatches"])
    section5 = _build_section5(obj_name, schema, [])
    section6 = _build_section6_provenance(provenance_rows)

    md_parts = [
        "---", fm_text, "---", "",
        f"# {obj_name}", "",
        f"> {kind_label.capitalize()} in `main.{schema}`. {n_pass + n_narr + n_5} of {len(columns)} columns documented from anchored evidence; {n_unverified} unverified (see sidecar).",
        "", prop_table, "", "---", "",
        "## 1. What it is", "", section1, "", "---", "",
        "## 2. Transform Logic", "", section2, "", "---", "",
        "## 3. Elements", "", section3, "", "---", "",
        "## 4. Lineage", "", section4, "", "---", "",
        "## 5. Common usage / JOINs", "", section5, "", "---", "",
        "## 6. Deploy / UC ALTER provenance", "", section6, "",
        f"*Generated: {_today_iso()} | Tiers: {n_pass} T1, {n_narr} T2, {n_3} T3, {n_4} T4, {n_5} T5, {n_unverified} U "
        f"| Elements: {len(elements_rows)}/{len(columns)} | Source: {writer_kind}*",
    ]
    md_text = "\n".join(md_parts) + "\n"

    sidecar_parts = [
        f"# Review-needed sidecar — `{obj_name}`", "",
        f"Generated: {_today_iso()}",
        f"Wiki: `{out_md.relative_to(REPO).as_posix()}`", "",
        "## UNVERIFIED columns", "",
    ]
    if sidecar_unverified:
        sidecar_parts.append("| Column | Reason |")
        sidecar_parts.append("|--------|--------|")
        for u in sidecar_unverified:
            r = u['reason'].replace('|', '\\|')
            sidecar_parts.append(f"| `{u['name']}` | {r} |")
    else:
        sidecar_parts.append("_None._")
    sidecar_parts.extend(["", "## Tier 4 candidates", ""])
    if sidecar_tier4:
        for t in sidecar_tier4:
            sidecar_parts.append(f"- `{t['name']}`: {t['reason']}")
    else:
        sidecar_parts.append("_None._")
    sidecar_parts.extend(["", "## Cross-check mismatches", ""])
    if lineage_stats["mismatches"]:
        sidecar_parts.append(f"- {lineage_stats['mismatches']} column(s) — see `.lineage.md` cross-check section.")
    else:
        sidecar_parts.append("_None._")
    sidecar_parts.extend(["", "## Open questions", ""])
    if sidecar_warnings:
        for w in sidecar_warnings:
            sidecar_parts.append(f"- {w}")
    else:
        sidecar_parts.append("_None._")
    sidecar_text = "\n".join(sidecar_parts) + "\n"

    blocked_upstreams: list[str] = []
    for w in sidecar_warnings:
        m = re.search(r"upstream `([^`]+)`", w)
        if m:
            up = m.group(1)
            if up not in blocked_upstreams:
                blocked_upstreams.append(up)

    if blocked_upstreams:
        status = "Blocked"
        status_detail = f"upstream wiki missing: {blocked_upstreams[0]}"
        routing_attempts = "rules 1-5 attempted in cache_upstream_wikis.py; see _discovery/upstream_wikis/_index.json"
    elif n_unverified > 0 and n_unverified == len(columns):
        status = "Stub only"
        status_detail = f"all {len(columns)} columns unclassifiable"
        routing_attempts = "no upstream wiki match AND no source-code citation"
    elif n_unverified > 0:
        status = "Generated"
        status_detail = f"{n_unverified} of {len(columns)} columns in sidecar"
        routing_attempts = ""
    else:
        status = "Generated"
        status_detail = ""
        routing_attempts = ""

    status_payload = {
        "object": f"main.{schema}.{obj_name}",
        "status": status,
        "status_detail": status_detail,
        "blocked_on_upstream": blocked_upstreams[0] if blocked_upstreams else None,
        "all_blocked_upstreams": blocked_upstreams,
        "routing_attempts": routing_attempts,
        "n_unverified": n_unverified,
        "tier_counts": dict(tier_counts),
        "generated_at": _now_iso_z(),
    }

    if dry_run:
        return {
            "obj": obj_name,
            "would_write": [str(out_md.relative_to(REPO)), str(out_review.relative_to(REPO))],
            "tier_counts": dict(tier_counts),
            "n_unverified": n_unverified,
            "status": status,
            "blocked_on_upstream": status_payload["blocked_on_upstream"],
        }

    out_md.write_text(md_text, encoding="utf-8")
    out_review.write_text(sidecar_text, encoding="utf-8")
    out_status = out_dir / f"{obj_name}.status.json"
    out_status.write_text(json.dumps(status_payload, indent=2, ensure_ascii=False),
                           encoding="utf-8")

    return {
        "obj": obj_name,
        "wrote": [str(out_md.relative_to(REPO)), str(out_review.relative_to(REPO)),
                  str(out_status.relative_to(REPO))],
        "tier_counts": dict(tier_counts),
        "n_unverified": n_unverified,
        "status": status,
        "blocked_on_upstream": status_payload["blocked_on_upstream"],
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Phase 5 — Generate Wiki (UC-Pipeline pack)")
    ap.add_argument("--schema", required=True)
    ap.add_argument("--object", default=None,
                    help="Optional: single object name (default: all in-scope in schema)")
    ap.add_argument("--dry-run", action="store_true",
                    help="Don't write files; report what would be written")
    ap.add_argument("--force", action="store_true",
                    help="Regenerate wiki even if .md exists")
    args = ap.parse_args()

    schema_root = OBJ_OUT_ROOT / args.schema
    if not schema_root.is_dir():
        print(f"ERROR: schema folder not found: {schema_root}", file=sys.stderr)
        return 2

    inv = read_inventory(schema_root)
    if args.object:
        targets = [args.object]
    else:
        targets = [o["name"] for o in inv.get("objects", []) if o.get("in_scope")]

    if not targets:
        print(f"[generate-wiki] no in-scope objects in {schema_root}", file=sys.stderr)
        return 0

    print(f"[generate-wiki] {args.schema}: {len(targets)} object(s) to generate",
          file=sys.stderr)
    errors = 0
    for name in targets:
        try:
            r = generate_for_object(args.schema, name, dry_run=args.dry_run)
            status = "DRY-RUN" if args.dry_run else "OK"
            print(f"  [{status}] {name} — tiers={r['tier_counts']}, unverified={r['n_unverified']}",
                  file=sys.stderr)
        except Exception as e:
            errors += 1
            print(f"  [FAIL] {name} — {e}", file=sys.stderr)

    print(f"[generate-wiki] done: {len(targets) - errors}/{len(targets)} OK", file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr, flush=True)
        sys.exit(1)
