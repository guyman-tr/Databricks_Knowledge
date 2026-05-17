#!/usr/bin/env python3
"""
Phase 4 — Column Lineage (UC-Pipeline pack).

Parses the cached source code (view DDL or notebook body) for an object and
produces `{Object}.lineage.md` — column-level upstream mapping with transform
classification. Cross-checks against the cached system.access.column_lineage
JSON (Phase 2 second-opinion).

Strategy:
  - VIEW (source = .sql snapshot): parse with sqlglot using `databricks` dialect.
    Walk the SELECT projections, resolve each to its source column or expression.

  - TABLE (source = .py/.sql snapshot): find the final write to {full_name} and
    parse its SELECT (for SQL writes) or its DataFrame chain (for PySpark
    writes). The DataFrame chain analysis is shallow — it recovers passthroughs,
    renames, casts, and literals; everything else degrades to `unknown` and
    Phase 5 routes it to the sidecar.

The output Markdown is the canonical contract dwh-semantic-doc/GATE-lineage-contract
expects: a `## Column Lineage` table with one row per target column.

Usage:
  python tools/uc_pipelines/build_lineage.py --schema etoro_kpi_prep \
      --object v_fact_customeraction_enriched
  python tools/uc_pipelines/build_lineage.py --schema etoro_kpi_prep   # all in-scope
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
OBJ_OUT_ROOT = REPO / "knowledge" / "UC_generated"


# ---------- transform classification ----------

PASSTHROUGH = "passthrough"
RENAME = "rename"
CAST = "cast"
CASE = "case"
COALESCE = "coalesce"
ARITHMETIC = "arithmetic"
STRING_OP = "string_op"
AGGREGATE = "aggregate"
WINDOW = "window"
JOIN_ENRICHED = "join_enriched"
LITERAL = "literal"
UDF = "udf"
UNKNOWN = "unknown"


def _import_sqlglot():
    try:
        import sqlglot  # noqa
        from sqlglot import exp  # noqa
        return sqlglot, exp
    except ImportError:
        print("[build-lineage] sqlglot missing. pip install sqlglot", file=sys.stderr)
        raise


# ---------- VIEW DDL parser ----------

def parse_view_definition(view_def: str, primary_full_name: str) -> dict:
    """Return {"columns": [...], "sources": {alias: full_name_or_subquery}, "joins": [...]}.

    Each column dict: { "target": str, "source_object": str|None, "source_column": str|None,
                        "transform": str, "expression_snippet": str }.
    """
    sqlglot, exp = _import_sqlglot()
    try:
        tree = sqlglot.parse_one(view_def, read="databricks")
    except Exception as e:
        return {"columns": [], "sources": {}, "joins": [], "parse_error": str(e)[:300]}

    # 1) Resolve FROM/JOIN aliases → fully-qualified table names
    alias_to_full: dict[str, str] = {}
    join_list: list[dict] = []
    primary_alias: str | None = None
    for tbl in tree.find_all(exp.Table):
        # Skip tables that are inside subqueries we don't care about — but for
        # the simple view DDLs we encounter (single SELECT with JOINs), the top-
        # level Table nodes are exactly the FROM/JOIN targets.
        catalog = tbl.catalog or "main"
        schema = tbl.db or ""
        name = tbl.name
        if not schema:
            # CTE alias or local — skip
            continue
        full = f"{catalog}.{schema}.{name}".lower()
        alias = (tbl.alias_or_name or name).lower()
        alias_to_full.setdefault(alias, full)
        # If this is the FROM target (no Join parent), it's primary
        if primary_alias is None and not _is_in_join(tbl):
            primary_alias = alias

    for j in tree.find_all(exp.Join):
        kind = j.args.get("kind") or ""
        side = j.args.get("side") or ""
        join_list.append({"kind": str(side or "INNER") + " " + str(kind or "JOIN"),
                          "rendered": j.sql(dialect="databricks")[:240]})

    # 2) Walk top-level projections — expanding stars via CTE expansion when needed
    columns: list[dict] = _expand_select(tree, alias_to_full, primary_alias, exp)
    if columns is None:
        return {"columns": [], "sources": alias_to_full, "joins": join_list,
                "parse_error": "no top-level SELECT"}

    return {"columns": columns, "sources": alias_to_full, "joins": join_list,
            "primary_alias": primary_alias,
            "primary_full_name": (alias_to_full.get(primary_alias) if primary_alias else primary_full_name)}


def _expand_select(tree, alias_to_full, primary_alias, exp) -> list[dict] | None:
    """Walk the top-level select(s), expanding `*` from CTEs or subqueries when
    the top projection is just `*`. Handles `SELECT * FROM cte UNION ALL SELECT * FROM cte`
    by recursing into the FIRST UNION branch.
    """
    # CTE table → cte tree map (only when explicitly referenced via FROM cte_alias)
    cte_defs: dict[str, "exp.Select"] = {}
    for cte in tree.find_all(exp.CTE):
        nm = (cte.alias or "").lower()
        inner = cte.this
        if isinstance(inner, exp.Select):
            cte_defs[nm] = inner
        elif isinstance(inner, exp.Union):
            # CTE that is itself a UNION — take left branch's projections as authoritative
            cte_defs[nm] = inner.this  # left

    target = tree if isinstance(tree, exp.Select) else tree.find(exp.Select)
    if isinstance(tree, exp.Union):
        target = tree.this  # left branch of outer UNION
        if isinstance(target, exp.Union):
            target = target.this

    if target is None:
        return None

    projections = target.expressions
    # If projections are exclusively `*` (with no table qualifier), and the FROM is a CTE,
    # expand by reading the CTE's projections instead.
    if (len(projections) == 1
            and isinstance(projections[0], exp.Star)
            and isinstance(projections[0].parent, exp.Select)):
        # sqlglot 30 stores FROM as 'from_' (older versions used 'from')
        from_node = target.args.get("from_") or target.args.get("from") or target.find(exp.From)
        if from_node:
            # exp.From holds the table in `this`, additional in `expressions`
            ftbl = None
            if isinstance(from_node, exp.From):
                ftbl = from_node.this
            if ftbl is None and hasattr(from_node, "expressions") and from_node.expressions:
                ftbl = from_node.expressions[0]
            if isinstance(ftbl, exp.Table):
                cte_name = (ftbl.alias_or_name or ftbl.name or "").lower()
                cte = cte_defs.get(cte_name)
                if cte is not None:
                    # Re-build alias_to_full from the CTE scope
                    inner_aliases: dict[str, str] = {}
                    inner_primary: str | None = None
                    for tbl in cte.find_all(exp.Table):
                        cat = tbl.catalog or "main"
                        sch = tbl.db or ""
                        nm = tbl.name
                        if not sch:
                            continue
                        full = f"{cat}.{sch}.{nm}".lower()
                        alias = (tbl.alias_or_name or nm).lower()
                        inner_aliases.setdefault(alias, full)
                        if inner_primary is None and not _is_in_join(tbl):
                            inner_primary = alias
                    # Merge inner aliases into outer (the outer FROM-CTE already
                    # contributed no real table sources for these stars).
                    alias_to_full.update(inner_aliases)
                    cols: list[dict] = []
                    for proj in cte.expressions:
                        target_name = proj.alias_or_name
                        expr = proj.unalias()
                        col = _classify_projection(expr, target_name, alias_to_full, inner_primary, exp)
                        col["expression_snippet"] = proj.sql(dialect="databricks")[:240]
                        cols.append(col)
                    return cols
            elif isinstance(ftbl, (exp.Subquery,)):
                # FROM (SELECT ...) — recurse
                inner_select = ftbl.this
                if isinstance(inner_select, exp.Select):
                    cols: list[dict] = []
                    inner_aliases: dict[str, str] = {}
                    inner_primary: str | None = None
                    for tbl in inner_select.find_all(exp.Table):
                        cat = tbl.catalog or "main"
                        sch = tbl.db or ""
                        nm = tbl.name
                        if not sch:
                            continue
                        full = f"{cat}.{sch}.{nm}".lower()
                        alias = (tbl.alias_or_name or nm).lower()
                        inner_aliases.setdefault(alias, full)
                        if inner_primary is None and not _is_in_join(tbl):
                            inner_primary = alias
                    alias_to_full.update(inner_aliases)
                    for proj in inner_select.expressions:
                        target_name = proj.alias_or_name
                        expr = proj.unalias()
                        col = _classify_projection(expr, target_name, alias_to_full, inner_primary, exp)
                        col["expression_snippet"] = proj.sql(dialect="databricks")[:240]
                        cols.append(col)
                    return cols

    # Default: walk the projections as-is
    cols: list[dict] = []
    for proj in projections:
        target_name = proj.alias_or_name
        expr = proj.unalias()
        col = _classify_projection(expr, target_name, alias_to_full, primary_alias, exp)
        col["expression_snippet"] = proj.sql(dialect="databricks")[:240]
        cols.append(col)
    return cols


def _is_in_join(node) -> bool:
    """True iff `node` is the table-arg of a JOIN expression in its parents."""
    p = node.parent
    while p is not None:
        from sqlglot import exp
        if isinstance(p, exp.Join):
            return True
        p = p.parent
    return False


def _classify_projection(expr, target_name: str, alias_to_full: dict[str, str],
                         primary_alias: str | None, exp) -> dict:
    """Classify a single projection into a transform + source mapping."""
    # Pure column reference
    if isinstance(expr, exp.Column):
        src_table_alias = (expr.table or primary_alias or "").lower()
        src_full = alias_to_full.get(src_table_alias)
        src_col = expr.name
        is_join = (primary_alias is not None and src_table_alias and src_table_alias != primary_alias)
        if is_join:
            transform = JOIN_ENRICHED
        elif src_col == target_name:
            transform = PASSTHROUGH
        else:
            transform = RENAME
        return {"target": target_name, "source_object": src_full,
                "source_column": src_col, "transform": transform}

    # CAST
    if isinstance(expr, exp.Cast):
        inner = expr.this
        if isinstance(inner, exp.Column):
            src_table_alias = (inner.table or primary_alias or "").lower()
            src_full = alias_to_full.get(src_table_alias)
            return {"target": target_name, "source_object": src_full,
                    "source_column": inner.name, "transform": CAST,
                    "cast_to": expr.to.sql(dialect="databricks") if expr.to else None}

    # CASE
    if isinstance(expr, exp.Case):
        srcs = _collect_source_cols(expr, alias_to_full, primary_alias, exp)
        return {"target": target_name, "source_object": _join_srcs(srcs),
                "source_column": None, "transform": CASE,
                "input_columns": [s["source_column"] for s in srcs]}

    # COALESCE / NVL
    if isinstance(expr, exp.Coalesce) or (isinstance(expr, exp.Anonymous) and expr.name.upper() in {"COALESCE", "NVL", "IFNULL"}):
        srcs = _collect_source_cols(expr, alias_to_full, primary_alias, exp)
        return {"target": target_name, "source_object": _join_srcs(srcs),
                "source_column": None, "transform": COALESCE}

    # Window functions
    if isinstance(expr, exp.Window):
        srcs = _collect_source_cols(expr, alias_to_full, primary_alias, exp)
        return {"target": target_name, "source_object": _join_srcs(srcs),
                "source_column": None, "transform": WINDOW}

    # Aggregates
    if isinstance(expr, exp.AggFunc):
        srcs = _collect_source_cols(expr, alias_to_full, primary_alias, exp)
        return {"target": target_name, "source_object": _join_srcs(srcs),
                "source_column": None, "transform": AGGREGATE}

    # Literals
    if isinstance(expr, (exp.Literal, exp.Null, exp.CurrentDate, exp.CurrentTimestamp)):
        return {"target": target_name, "source_object": None,
                "source_column": None, "transform": LITERAL,
                "literal_value": expr.sql(dialect="databricks")}

    # Arithmetic / Binary
    if isinstance(expr, exp.Binary):
        srcs = _collect_source_cols(expr, alias_to_full, primary_alias, exp)
        return {"target": target_name, "source_object": _join_srcs(srcs),
                "source_column": None, "transform": ARITHMETIC}

    # String ops (concat, regexp_replace, substring, …)
    if isinstance(expr, exp.Concat) or (isinstance(expr, exp.Func) and _looks_string_op(expr)):
        srcs = _collect_source_cols(expr, alias_to_full, primary_alias, exp)
        return {"target": target_name, "source_object": _join_srcs(srcs),
                "source_column": None, "transform": STRING_OP}

    # UDF / Anonymous function call
    if isinstance(expr, exp.Anonymous):
        srcs = _collect_source_cols(expr, alias_to_full, primary_alias, exp)
        return {"target": target_name, "source_object": _join_srcs(srcs),
                "source_column": None, "transform": UDF,
                "udf_name": expr.this if isinstance(expr.this, str) else expr.name}

    # Default
    srcs = _collect_source_cols(expr, alias_to_full, primary_alias, exp)
    return {"target": target_name,
            "source_object": _join_srcs(srcs) if srcs else None,
            "source_column": None,
            "transform": UNKNOWN}


def _collect_source_cols(node, alias_to_full, primary_alias, exp) -> list[dict]:
    out: list[dict] = []
    seen = set()
    for c in node.find_all(exp.Column):
        alias = (c.table or primary_alias or "").lower()
        full = alias_to_full.get(alias)
        key = (full, c.name)
        if key in seen:
            continue
        seen.add(key)
        out.append({"source_object": full, "source_column": c.name})
    return out


def _join_srcs(srcs: list[dict]) -> str | None:
    if not srcs:
        return None
    fulls = []
    for s in srcs:
        f = s.get("source_object")
        if f and f not in fulls:
            fulls.append(f)
    return " / ".join(fulls) if fulls else None


_STRING_FUNCS = {"CONCAT", "CONCAT_WS", "SUBSTRING", "SUBSTR", "REGEXP_REPLACE",
                 "REGEXP_EXTRACT", "TRIM", "UPPER", "LOWER", "LPAD", "RPAD",
                 "REPLACE", "SPLIT"}


def _looks_string_op(func) -> bool:
    name = func.name.upper() if hasattr(func, "name") and func.name else ""
    return name in _STRING_FUNCS


# ---------- Python notebook parser (shallow) ----------

_PY_FINAL_WRITE_PATTERNS = [
    # spark.sql("INSERT INTO main.x.y SELECT ...") / MERGE INTO
    (r"spark\.sql\s*\(\s*(?:f?['\"]{3}|f?['\"])(?P<sql>[^'\"]*?\b(?:INSERT\s+INTO|INSERT\s+OVERWRITE|MERGE\s+INTO)\s+(?P<tgt>[A-Za-z0-9_\.]+)[^'\"]*?)(?:['\"]{3}|['\"])\s*\)",
     "spark_sql"),
    # df.write.saveAsTable("a.b.c") / .insertInto / .writeTo("...")
    (r"\.write(?:To)?\s*\(\s*['\"](?P<tgt>[A-Za-z0-9_\.]+)['\"]\s*\)", "df_write"),
    (r"\.saveAsTable\s*\(\s*['\"](?P<tgt>[A-Za-z0-9_\.]+)['\"]\s*\)", "df_save"),
    (r"\.insertInto\s*\(\s*['\"](?P<tgt>[A-Za-z0-9_\.]+)['\"]\s*\)", "df_insert"),
]


def find_final_write(notebook_body: str, target_full_name: str) -> dict:
    """Locate the final write that targets `target_full_name`.

    Returns {"pattern": str, "sql": str|None, "line": int}. None if no write found.
    """
    fn_lower = target_full_name.lower()
    fn_short_lower = fn_lower.split(".")[-1]
    matches: list[tuple[int, str, dict]] = []
    lines = notebook_body.splitlines()
    line_starts = [0]
    for ln in lines:
        line_starts.append(line_starts[-1] + len(ln) + 1)

    for pattern, kind in _PY_FINAL_WRITE_PATTERNS:
        for m in re.finditer(pattern, notebook_body, flags=re.IGNORECASE | re.DOTALL):
            tgt = (m.group("tgt") or "").lower()
            # Accept matches on the exact full name OR the bare table name
            if tgt != fn_lower and tgt != fn_short_lower and not tgt.endswith("." + fn_short_lower):
                continue
            pos = m.start()
            line = next(i for i, off in enumerate(line_starts) if off > pos) if pos < line_starts[-1] else len(lines)
            sql_text = m.groupdict().get("sql")
            matches.append((line, kind, {"pattern": kind, "sql": sql_text,
                                          "match_text": m.group(0)[:240], "line": line}))

    if not matches:
        return {}
    # Prefer the LAST match (final write in execution order)
    matches.sort(key=lambda x: x[0])
    return matches[-1][2]


def parse_notebook_for_lineage(notebook_body: str, target_full_name: str,
                                inv_columns: list[dict]) -> dict:
    """Parse the final write in a notebook body.

    For SQL writes (INSERT INTO ... SELECT) we feed the SELECT to sqlglot.
    For DataFrame writes we fall back to `unknown` for every column — Phase 5
    will rely on the system.access.column_lineage cross-check instead.
    """
    sqlglot, exp = _import_sqlglot()
    write = find_final_write(notebook_body, target_full_name)
    if not write:
        return {"columns": [{"target": c["name"], "source_object": None,
                              "source_column": None, "transform": UNKNOWN,
                              "expression_snippet": "(no final write found in notebook)"} for c in inv_columns],
                "sources": {}, "joins": [],
                "parse_error": "no final write to target found in notebook"}

    sql_text = write.get("sql") or ""
    if not sql_text:
        # DataFrame write — we don't AST-walk PySpark chains in v1
        return {"columns": [{"target": c["name"], "source_object": None,
                              "source_column": None, "transform": UNKNOWN,
                              "expression_snippet": f"DataFrame write (kind={write['pattern']}) at notebook L{write['line']}"} for c in inv_columns],
                "sources": {}, "joins": [],
                "parse_error": "DataFrame write — AST walk not implemented in v1; rely on system.access.column_lineage"}

    # Extract the SELECT body after INSERT INTO ... [columns] or MERGE INTO ... USING (...)
    select_text = _extract_select_from_write(sql_text)
    if not select_text:
        return {"columns": [{"target": c["name"], "source_object": None,
                              "source_column": None, "transform": UNKNOWN,
                              "expression_snippet": "could not extract SELECT body"} for c in inv_columns],
                "sources": {}, "joins": [],
                "parse_error": "couldn't extract SELECT body from INSERT/MERGE statement"}

    parsed = parse_view_definition(select_text, target_full_name)
    return parsed


def _extract_select_from_write(sql_text: str) -> str | None:
    # INSERT INTO target [(...)] SELECT ...
    m = re.search(r"INSERT\s+(?:INTO|OVERWRITE)\s+[A-Za-z0-9_\.`]+(?:\s*\([^)]+\))?\s*(SELECT\b.+)\Z",
                  sql_text, flags=re.IGNORECASE | re.DOTALL)
    if m:
        return m.group(1)
    # MERGE INTO target ... USING (SELECT ...) ...
    m = re.search(r"USING\s*\(\s*(SELECT\b.+?)\)\s*ON\b", sql_text, flags=re.IGNORECASE | re.DOTALL)
    if m:
        return m.group(1)
    return None


# ---------- column_lineage cross-check ----------

def cross_check(parsed_columns: list[dict], cl_cache: list[dict]) -> dict:
    """Compare parser output against system.access.column_lineage."""
    by_target: dict[str, set[tuple]] = {}
    for row in cl_cache:
        tgt = (row.get("target_column_name") or "").lower()
        src_t = (row.get("source_table_full_name") or "").lower()
        src_c = (row.get("source_column_name") or "").lower()
        if not tgt or not src_t or not src_c:
            continue
        by_target.setdefault(tgt, set()).add((src_t, src_c))

    rows = []
    summary = {"total": len(parsed_columns), "ok": 0, "warn": 0, "error": 0, "info": 0}
    for col in parsed_columns:
        tgt = col["target"].lower()
        parsed_set: set[tuple] = set()
        srcs = col.get("source_object")
        scol = col.get("source_column")
        if srcs and scol:
            # Multi-source srcs may be joined with " / "
            for s in (srcs.split(" / ") if isinstance(srcs, str) else [srcs]):
                parsed_set.add((s.lower(), (scol or "").lower()))
        runtime_set = by_target.get(tgt, set())

        if not runtime_set and not parsed_set:
            severity = "OK"
        elif parsed_set == runtime_set:
            severity = "OK"
        elif not parsed_set and runtime_set:
            severity = "ERROR"
        elif not runtime_set and parsed_set:
            severity = "INFO"
        elif parsed_set.issubset(runtime_set):
            severity = "WARN"  # parser missed a source
        elif runtime_set.issubset(parsed_set):
            severity = "WARN"  # parser saw more (often literals UC can't track)
        else:
            severity = "WARN"  # partial overlap

        rows.append({
            "target": col["target"],
            "parsed": sorted(parsed_set),
            "runtime": sorted(runtime_set),
            "severity": severity,
        })
        sev_key = severity.lower()
        if sev_key in summary:
            summary[sev_key] += 1
    return {"summary": summary, "rows": rows}


# ---------- upstream-wiki bridge ----------

def upstream_wiki_for(source_object: str, ux_index: dict) -> dict:
    if not source_object:
        return {"wiki_exists": False}
    for entry in (ux_index or {}).get("upstreams", []):
        if (entry.get("full_name") or "").lower() == source_object.lower():
            return entry
    return {"wiki_exists": False}


def upstream_tier_for(source_object: str, source_column: str | None,
                      ux_index: dict, cache_root: Path) -> str | None:
    """Extract the `(Tier N — origin)` tag from the upstream wiki for a column.

    Returns the literal `(Tier ...)` string, or None if no match.
    """
    if not source_object or not source_column:
        return None
    entry = upstream_wiki_for(source_object, ux_index)
    if not entry.get("wiki_exists"):
        return None
    cached = entry.get("cached_at")
    if not cached:
        return None
    p = REPO / cached
    if not p.exists():
        return None
    try:
        txt = p.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return None
    # Look for a markdown table row whose Element matches source_column
    col_re = re.compile(r"\|\s*\d+\s*\|\s*`?" + re.escape(source_column) + r"`?\s*\|", re.IGNORECASE)
    tag_re = re.compile(r"(\(Tier\s+[1-5][a-z]?\s+[—–-]\s+[^\)]+\))")
    for line in txt.splitlines():
        if col_re.search(line):
            m = tag_re.search(line)
            if m:
                return m.group(1)
    return None


# ---------- output renderer ----------

def render_lineage_md(schema: str, full_name: str, table_type: str,
                       parse_result: dict, cross: dict, ux_index: dict,
                       cache_root: Path, source_code_rel: str,
                       column_lineage_rel: str, inv_columns: list[dict]) -> str:
    ts = dt.date.today().isoformat()
    primary = parse_result.get("primary_full_name")
    sources = parse_result.get("sources") or {}
    joins = parse_result.get("joins") or []
    parse_error = parse_result.get("parse_error")

    lines: list[str] = []
    lines.append(f"# Column Lineage: {full_name}")
    lines.append("")
    lines.append("| Property | Value |")
    lines.append("|----------|-------|")
    lines.append(f"| **UC Object** | `{full_name}` |")
    lines.append(f"| **Object Type** | `{table_type}` |")
    lines.append(f"| **Source** | `{source_code_rel}` |")
    lines.append(f"| **Column-lineage cache** | `{column_lineage_rel}` (rows: "
                 f"{cross['summary']['total']}, mismatches: {cross['summary']['error'] + cross['summary']['warn']}) |")
    if parse_error:
        lines.append(f"| **Parse warning** | `{parse_error}` |")
    lines.append(f"| **Primary upstream** | `{primary or 'n/a'}` |")
    lines.append(f"| **Generated** | {ts} |")
    lines.append("")

    # Upstream Objects table
    lines.append("## Upstream Objects")
    lines.append("")
    lines.append("| Upstream UC Object | Role | Upstream Wiki |")
    lines.append("|--------------------|------|---------------|")
    primary_low = (primary or "").lower()
    for alias, full in sorted(sources.items()):
        if not full:
            continue
        role = "Primary (FROM)" if full == primary_low else "JOIN / referenced"
        ue = upstream_wiki_for(full, ux_index)
        wiki = ue.get("wiki_path") or "(no wiki found)"
        wiki_status = "✓" if ue.get("wiki_exists") else "✗"
        lines.append(f"| `{full}` | {role} | {wiki_status} `{wiki}` |")
    lines.append("")

    # Lineage chain (rough)
    if primary:
        lines.append("## Lineage Chain")
        lines.append("")
        lines.append("```")
        lines.append(f"{primary}   ←── primary upstream")
        for alias, full in sources.items():
            if full and full != primary_low:
                lines.append(f"  + {full}   (JOIN)")
        lines.append("        │")
        lines.append("        ▼")
        lines.append(f"{full_name}   ←── this object")
        lines.append("```")
        lines.append("")

    # Column Lineage table
    lines.append("## Column Lineage")
    lines.append("")
    lines.append("| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |")
    lines.append("|---|-----------|------------------|---------------|-----------|---------------|-------|")
    # Build a {target: parsed_col} lookup to fill in for inv_columns
    parsed_by_target = {c["target"].lower(): c for c in parse_result.get("columns", [])}
    for i, c in enumerate(inv_columns, 1):
        target = c["name"]
        pcol = parsed_by_target.get(target.lower(), {
            "target": target, "source_object": None, "source_column": None,
            "transform": UNKNOWN, "expression_snippet": "(not parsed — column missing from SELECT?)"
        })
        src_obj = pcol.get("source_object") or "—"
        src_col = pcol.get("source_column") or "—"
        transform = pcol.get("transform") or UNKNOWN
        tier = upstream_tier_for(pcol.get("source_object"), pcol.get("source_column"),
                                  ux_index, cache_root) or "—"
        notes = pcol.get("expression_snippet") or ""
        notes = notes.replace("|", "\\|").replace("\n", " ")[:140]
        if pcol.get("cast_to"):
            notes = f"cast to {pcol['cast_to']} — " + notes
        if pcol.get("literal_value"):
            notes = f"literal `{pcol['literal_value']}` — " + notes
        lines.append(f"| {i} | `{target}` | `{src_obj}` | `{src_col}` | `{transform}` | {tier} | {notes} |")
    lines.append("")

    # Cross-check section
    lines.append("## Cross-check vs system.access.column_lineage")
    lines.append("")
    s = cross["summary"]
    parity = "✓" if s["error"] == 0 and s["warn"] == 0 else "⚠"
    lines.append(f"- Total target columns: **{s['total']}**")
    lines.append(f"- OK: **{s['ok']}**, WARN: **{s['warn']}**, ERROR: **{s['error']}**, INFO: **{s['info']}**  {parity}")
    lines.append("")
    bad = [r for r in cross["rows"] if r["severity"] in ("WARN", "ERROR")]
    if bad:
        lines.append("| Target | Parsed | Runtime | Severity |")
        lines.append("|--------|--------|---------|----------|")
        for r in bad[:40]:
            p_str = ", ".join(f"`{a}.{b}`" for a, b in r["parsed"]) or "—"
            ru_str = ", ".join(f"`{a}.{b}`" for a, b in r["runtime"]) or "—"
            lines.append(f"| `{r['target']}` | {p_str} | {ru_str} | {r['severity']} |")
        lines.append("")

    # Lost / added columns
    target_set = {c["name"].lower() for c in inv_columns}
    primary_source_columns: set[str] = set()
    for pcol in parse_result.get("columns", []):
        if pcol.get("transform") in (PASSTHROUGH, RENAME, CAST) and pcol.get("source_column"):
            primary_source_columns.add(pcol["source_column"].lower())

    lines.append("## Lost / added columns")
    lines.append("")
    n_added = sum(1 for c in parse_result.get("columns", [])
                  if c.get("transform") in (JOIN_ENRICHED, CASE, LITERAL, ARITHMETIC, AGGREGATE, WINDOW, UDF))
    lines.append(f"- Computed/added columns vs primary: **{n_added}**")
    n_unknown = sum(1 for c in parse_result.get("columns", []) if c.get("transform") == UNKNOWN)
    if n_unknown:
        lines.append(f"- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **{n_unknown}**")
    lines.append("")

    if joins:
        lines.append("## Joins (detected)")
        lines.append("")
        for j in joins[:10]:
            lines.append(f"- `{j['kind']}` — {j['rendered']}")
        lines.append("")

    return "\n".join(lines)


# ---------- main ----------

def _load_inventory(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _load_yaml_frontmatter(path: Path) -> dict:
    import yaml  # type: ignore
    m = re.match(r"^---\n(.+?)\n---\n", path.read_text(encoding="utf-8"), re.DOTALL)
    return yaml.safe_load(m.group(1)) if m else {}


def main() -> int:
    ap = argparse.ArgumentParser(description="UC-Pipeline column lineage (Phase 4)")
    ap.add_argument("--schema", required=True)
    ap.add_argument("--object", help="Single object name (else all in-scope)")
    ap.add_argument("--objects", nargs="+", help="Subset of object names")
    args = ap.parse_args()

    schema_root = OBJ_OUT_ROOT / args.schema
    inv_path = schema_root / "_discovery" / "uc_inventory.json"
    card_path = schema_root / "_schema_card.md"
    if not inv_path.exists() or not card_path.exists():
        print(f"[build-lineage] missing inventory/card for {args.schema}", file=sys.stderr)
        return 2

    inv = _load_inventory(inv_path)
    card = _load_yaml_frontmatter(card_path)
    in_scope_names = {o["name"] for o in (card.get("objects") or []) if o.get("in_scope")}

    target_names: list[str]
    if args.object:
        target_names = [args.object]
    elif args.objects:
        target_names = list(args.objects)
    else:
        target_names = [o["name"] for o in inv.get("objects", []) if o["name"] in in_scope_names]

    ux_index_path = schema_root / "_discovery" / "upstream_wikis" / "_index.json"
    ux_index = json.loads(ux_index_path.read_text(encoding="utf-8")) if ux_index_path.exists() else {}

    cache_root = schema_root / "_discovery" / "upstream_wikis"

    for name in target_names:
        obj = next((o for o in inv.get("objects", []) if o["name"] == name), None)
        if not obj:
            print(f"[build-lineage] {name} not found in inventory; skipping", file=sys.stderr)
            continue
        ttype = (obj["table_type"] or "").upper()
        full = obj["full_name"]
        print(f"[build-lineage] {full} ({ttype})", file=sys.stderr)

        # Locate source code snapshot
        src_dir = schema_root / "_discovery" / "source_code"
        src_file: Path | None = None
        for ext in ("sql", "py", "scala", "r"):
            cand = src_dir / f"{name}.{ext}"
            if cand.exists():
                src_file = cand
                break
        if not src_file:
            print(f"  source code snapshot missing — run fetch_writer_source.py first", file=sys.stderr)
            continue

        src_text = src_file.read_text(encoding="utf-8", errors="replace")

        # Parse
        if src_file.suffix.lower() == ".sql":
            # Strip leading header comments
            body = re.sub(r"^(--[^\n]*\n)+", "", src_text)
            parsed = parse_view_definition(body, full)
        else:
            parsed = parse_notebook_for_lineage(src_text, full, obj.get("columns") or [])

        # Cross-check
        cl_path = schema_root / "_discovery" / "column_lineage" / f"{name}.json"
        cl_rows = []
        if cl_path.exists():
            cl_rows = (json.loads(cl_path.read_text(encoding="utf-8")) or {}).get("rows", [])
        cross = cross_check(parsed.get("columns", []), cl_rows)

        # Render
        md = render_lineage_md(
            schema=args.schema, full_name=full, table_type=ttype,
            parse_result=parsed, cross=cross, ux_index=ux_index,
            cache_root=cache_root,
            source_code_rel=str(src_file.relative_to(REPO)),
            column_lineage_rel=str(cl_path.relative_to(REPO)) if cl_path.exists() else "(missing)",
            inv_columns=obj.get("columns") or [],
        )

        # Write
        folder = "Views" if "VIEW" in ttype else "Tables"
        dest = schema_root / folder / f"{name}.lineage.md"
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(md, encoding="utf-8")
        print(f"  wrote {dest.relative_to(REPO)}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr, flush=True)
        sys.exit(1)
