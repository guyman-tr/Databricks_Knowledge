"""sql_extractor.py — given an SqlLocation + column name, extract the
producing expression(s) from the SQL file.

Strategy:
- Pre-process T-SQL to strip wrappers sqlglot can't parse (CREATE FUNCTION
  ... RETURNS TABLE AS RETURN (...), GO batch separators, etc.).
- For Views & TVFs: parse the inner SELECT (possibly UNION ALL). Walk the
  expressions list. Match the named projection for the target column.
  Return separate ColumnExpression for each UNION branch.
- For Stored Procedures: locate the final `INSERT INTO target_table (col_list)
  ... SELECT col_list FROM <alias>` block; map target column -> SELECT
  expression by column-list ordinal; then walk back through temp tables and
  CTEs (CREATE TABLE #t AS SELECT ...) to find the most-derived non-trivial
  expression (CASE, COALESCE, function, literal).

If parsing fails for any stage, fail soft: return ExtractedExpression with
confidence='unverifiable' and a clear `notes` reason. Never invent lineage.

The output bundle for the judge contains:
  * primary: the final expression text (the LLM's single best snippet).
  * branches: for UNION cases, all branch expressions.
  * chain: intermediate expressions if we walked back through temp tables.
  * raw_sql_snippets: exact SQL substrings the LLM sees (for citation).
  * source_objects: best-effort upstream object names.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

import sqlglot
from sqlglot import exp


# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------

@dataclass
class ColumnExpression:
    column: str
    expression_sql: str                       # exact T-SQL text
    kind: str = "unknown"                     # passthrough | case | coalesce | literal | function | star | unknown
    source_alias: str = ""                    # alias like `frfc`
    source_object: str = ""                   # qualified upstream like `BI_DB_dbo.Function_Revenue_FullCommissions`
    label: str = ""                           # branch label e.g. 'TotalFullCommission'
    notes: list[str] = field(default_factory=list)


@dataclass
class ExtractedExpression:
    column: str
    object_kind: str                          # view | function | stored_procedure | unknown
    sql_path: Path
    primary: Optional[ColumnExpression] = None
    branches: list[ColumnExpression] = field(default_factory=list)  # for UNION
    chain: list[ColumnExpression] = field(default_factory=list)     # SP temp-table walk-back
    source_objects: list[str] = field(default_factory=list)
    raw_sql_snippets: list[str] = field(default_factory=list)
    confidence: str = "unverifiable"          # parsed | partial | unverifiable
    notes: list[str] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Pre-processing
# ---------------------------------------------------------------------------

_GO_BATCH_RE = re.compile(r"^\s*GO\s*$", re.IGNORECASE | re.MULTILINE)
_BLOCK_COMMENT_RE = re.compile(r"/\*.*?\*/", re.DOTALL)
_LINE_COMMENT_RE = re.compile(r"--[^\n]*")


def _strip_comments(sql: str) -> str:
    sql = _BLOCK_COMMENT_RE.sub("", sql)
    sql = _LINE_COMMENT_RE.sub("", sql)
    return sql


def _split_batches(sql: str) -> list[str]:
    """Split T-SQL into batches at GO separators."""
    parts = _GO_BATCH_RE.split(sql)
    return [p.strip() for p in parts if p.strip()]


# Matches "CREATE FUNCTION ... RETURNS TABLE AS RETURN (" up to the matching ")"
_FN_HDR_RE = re.compile(
    r"CREATE\s+FUNCTION\s+(?:\[[^\]]+\]|\w+)\s*\.\s*(?:\[[^\]]+\]|\w+)\s*"
    r"\([^)]*\)\s*RETURNS\s+TABLE\s*AS\s*RETURN\s*\(",
    re.IGNORECASE | re.DOTALL,
)


def _extract_fn_inner(batch: str) -> Optional[str]:
    """Strip `CREATE FUNCTION ... AS RETURN (` and trailing `)` for an inline TVF."""
    m = _FN_HDR_RE.search(batch)
    if not m:
        return None
    rest = batch[m.end():].rstrip()
    if rest.endswith(";"):
        rest = rest[:-1].rstrip()
    if rest.endswith(")"):
        rest = rest[:-1]
    return rest


_VIEW_HDR_RE = re.compile(
    r"CREATE\s+VIEW\s+(?:\[[^\]]+\]|\w+)\s*\.\s*(?:\[[^\]]+\]|\w+)\s*"
    r"(?:WITH\s+[^\s]+\s+)*AS\s*",
    re.IGNORECASE | re.DOTALL,
)


def _extract_view_inner(batch: str) -> Optional[str]:
    """Strip `CREATE VIEW ... AS` for a view definition."""
    m = _VIEW_HDR_RE.search(batch)
    if not m:
        return None
    return batch[m.end():].rstrip().rstrip(";")


# ---------------------------------------------------------------------------
# View / TVF projection walking
# ---------------------------------------------------------------------------

def _walk_select_projections(select_node: exp.Select) -> list[exp.Expression]:
    """Return the list of top-level projection expressions for a SELECT."""
    return list(select_node.expressions or [])


def _project_name(proj: exp.Expression) -> str:
    if isinstance(proj, exp.Alias):
        return proj.alias_or_name
    if isinstance(proj, exp.Column):
        return proj.name
    return proj.alias_or_name or ""


def _project_inner(proj: exp.Expression) -> exp.Expression:
    if isinstance(proj, exp.Alias):
        return proj.this
    return proj


def _classify(expr: exp.Expression) -> str:
    """Bucket an expression node into a coarse kind for the LLM prompt."""
    if isinstance(expr, exp.Case):
        return "case"
    if isinstance(expr, exp.Coalesce):
        return "coalesce"
    if isinstance(expr, exp.Cast):
        return "cast"
    if isinstance(expr, exp.Column):
        return "passthrough"
    if isinstance(expr, exp.Literal):
        return "literal"
    if isinstance(expr, exp.Null):
        return "literal"
    if isinstance(expr, exp.Anonymous) or isinstance(expr, exp.Func):
        return "function"
    if isinstance(expr, exp.Star):
        return "star"
    return "expression"


def _extract_source_alias(expr: exp.Expression) -> str:
    """Find the alias used inside the expression, if any."""
    for col in expr.find_all(exp.Column):
        if col.table:
            return col.table
    return ""


def _resolve_alias_to_object(select_node: exp.Select, alias: str) -> str:
    """Look at FROM/JOIN clauses to map alias -> qualified object name."""
    if not alias:
        return ""
    candidates: list[exp.Table] = []
    fr = select_node.args.get("from") or select_node.args.get("from_")
    if fr:
        candidates.extend(fr.find_all(exp.Table))
    for j in select_node.args.get("joins") or []:
        candidates.extend(j.find_all(exp.Table))
    for t in candidates:
        t_alias = t.alias_or_name
        if t_alias.lower() == alias.lower():
            return _qualified_name(t)
    return ""


def _branch_label_from_select(select_node: exp.Select) -> str:
    """If the SELECT has a literal 'X' AS Metric projection, use it as branch label."""
    for proj in _walk_select_projections(select_node):
        if isinstance(proj, exp.Alias) and proj.alias_or_name.lower() == "metric":
            inner = proj.this
            if isinstance(inner, exp.Literal):
                return str(inner.this)
    return ""


def _select_text(select_node: exp.Select) -> str:
    """Render the SELECT back to T-SQL for citation."""
    try:
        return select_node.sql(dialect="tsql")
    except Exception:
        return ""


def _find_column_in_select(
    select_node: exp.Select,
    target_col: str,
) -> Optional[ColumnExpression]:
    """Locate `target_col` in the projection list of `select_node`."""
    for proj in _walk_select_projections(select_node):
        if _project_name(proj).lower() == target_col.lower():
            inner = _project_inner(proj)
            try:
                expr_sql = inner.sql(dialect="tsql")
            except Exception:
                expr_sql = str(inner)
            alias = _extract_source_alias(inner)
            obj = _resolve_alias_to_object(select_node, alias)
            return ColumnExpression(
                column=target_col,
                expression_sql=expr_sql,
                kind=_classify(inner),
                source_alias=alias,
                source_object=obj,
                label=_branch_label_from_select(select_node),
            )
    return None


# ---------------------------------------------------------------------------
# Top-level extract for View / TVF
# ---------------------------------------------------------------------------

def _build_cte_map(query: exp.Expression) -> dict[str, exp.Expression]:
    """Walk an outermost Select/Union and collect all WITH-clause CTE bodies."""
    out: dict[str, exp.Expression] = {}
    for w in query.find_all(exp.With):
        for cte in w.expressions:
            name = cte.alias_or_name
            if name:
                out[name.lower()] = cte.this
    return out


def _from_alias_map(select_node: exp.Select) -> dict[str, exp.Expression]:
    """Map alias -> the FROM/JOIN node it refers to. Used to identify
    whether a passthrough alias `pr` refers to a CTE or a real table."""
    out: dict[str, exp.Expression] = {}
    fr = select_node.args.get("from") or select_node.args.get("from_")
    if fr:
        for t in fr.find_all(exp.Table):
            a = t.alias_or_name
            if a:
                out[a.lower()] = t
        for sq in fr.find_all(exp.Subquery):
            a = sq.alias_or_name
            if a:
                out[a.lower()] = sq.this
    for j in select_node.args.get("joins") or []:
        for t in j.find_all(exp.Table):
            a = t.alias_or_name
            if a:
                out[a.lower()] = t
        for sq in j.find_all(exp.Subquery):
            a = sq.alias_or_name
            if a:
                out[a.lower()] = sq.this
    return out


def _flatten_union(node: exp.Expression) -> list[exp.Select]:
    """Flatten a UNION/UNION ALL tree to a list of leaf SELECTs."""
    out: list[exp.Select] = []
    def walk(n: exp.Expression) -> None:
        if isinstance(n, exp.Union):
            walk(n.this)
            walk(n.expression)
        elif isinstance(n, exp.Select):
            out.append(n)
        elif isinstance(n, exp.Subquery):
            walk(n.this)
    walk(node)
    return out


def _find_through_query(
    query: exp.Expression,
    target_col: str,
    cte_map: dict[str, exp.Expression],
    out: ExtractedExpression,
    depth: int = 0,
) -> list[ColumnExpression]:
    """Recursively resolve `target_col` through a Select or Union, descending
    into CTEs whenever a projection is a bare alias.column passthrough whose
    alias resolves to a CTE name, or a SELECT alias.* star expansion whose
    alias resolves to a CTE.

    Returns a list of ColumnExpression (>1 only for UNION ALL branches).
    """
    if depth > 6:
        return []

    if isinstance(query, exp.Union):
        results: list[ColumnExpression] = []
        for sel in _flatten_union(query):
            results.extend(_find_through_query(sel, target_col, cte_map, out, depth + 1))
        return results

    if isinstance(query, exp.Subquery):
        return _find_through_query(query.this, target_col, cte_map, out, depth)

    if not isinstance(query, exp.Select):
        return []

    alias_map = _from_alias_map(query)
    # First pass: direct match in this SELECT's projection list.
    projections = _walk_select_projections(query)
    for proj in projections:
        if _project_name(proj).lower() == target_col.lower():
            inner = _project_inner(proj)
            # Passthrough Column: may be qualified (`alias.col`) or bare (`col`).
            if isinstance(inner, exp.Column):
                alias = inner.table or _single_source_alias(query, alias_map)
                col_name = inner.name
                if alias:
                    from_node = alias_map.get(alias.lower())
                    src_obj = ""
                    if isinstance(from_node, exp.Table):
                        # If the table name itself is a CTE name, recurse.
                        cte_body = cte_map.get(from_node.name.lower())
                        if cte_body is not None:
                            nested = _find_through_query(cte_body, col_name, cte_map, out, depth + 1)
                            if nested:
                                return nested
                        src_obj = _qualified_name(from_node)
                    elif from_node is not None:
                        nested = _find_through_query(from_node, col_name, cte_map, out, depth + 1)
                        if nested:
                            return nested
                    else:
                        # alias not in FROM but might be CTE-named directly
                        cte_body = cte_map.get(alias.lower())
                        if cte_body is not None:
                            nested = _find_through_query(cte_body, col_name, cte_map, out, depth + 1)
                            if nested:
                                return nested
                    ce = ColumnExpression(
                        column=target_col,
                        expression_sql=inner.sql(dialect="tsql"),
                        kind="passthrough",
                        source_alias=alias,
                        source_object=src_obj,
                        label=_branch_label_from_select(query),
                    )
                    _add_snippet(query, out)
                    return [ce]
                # Bare column, no resolvable alias: record but don't recurse.
                ce = ColumnExpression(
                    column=target_col,
                    expression_sql=inner.sql(dialect="tsql"),
                    kind="passthrough",
                    source_alias="",
                    source_object="",
                    label=_branch_label_from_select(query),
                )
                _add_snippet(query, out)
                return [ce]
            # Non-passthrough: this is the actual derivation.
            try:
                expr_sql = inner.sql(dialect="tsql")
            except Exception:
                expr_sql = str(inner)
            ce = ColumnExpression(
                column=target_col,
                expression_sql=expr_sql,
                kind=_classify(inner),
                source_alias=_extract_source_alias(inner),
                source_object=_resolve_alias_to_object(query, _extract_source_alias(inner)),
                label=_branch_label_from_select(query),
            )
            _add_snippet(query, out)
            return [ce]

    # Second pass: SELECT alias.* — the column may be inherited.
    for proj in projections:
        star_alias = _star_alias(proj)
        if not star_alias:
            continue
        from_node = alias_map.get(star_alias.lower())
        if isinstance(from_node, exp.Table):
            cte_body = cte_map.get(from_node.name.lower())
            if cte_body is not None:
                nested = _find_through_query(cte_body, target_col, cte_map, out, depth + 1)
                if nested:
                    return nested
        elif isinstance(from_node, (exp.Select, exp.Union)):
            nested = _find_through_query(from_node, target_col, cte_map, out, depth + 1)
            if nested:
                return nested
        else:
            cte_body = cte_map.get(star_alias.lower())
            if cte_body is not None:
                nested = _find_through_query(cte_body, target_col, cte_map, out, depth + 1)
                if nested:
                    return nested

    # Third pass: unaliased SELECT * — same idea, try every source in FROM.
    for proj in projections:
        if isinstance(proj, exp.Star):
            for alias, src in alias_map.items():
                if isinstance(src, exp.Table):
                    # If the table is actually a CTE, recurse into its body.
                    cte_body = cte_map.get(src.name.lower())
                    if cte_body is not None:
                        nested = _find_through_query(cte_body, target_col, cte_map, out, depth + 1)
                        if nested:
                            return nested
                    continue
                nested = _find_through_query(src, target_col, cte_map, out, depth + 1)
                if nested:
                    return nested

    return []


def _single_source_alias(query: exp.Select, alias_map: dict[str, exp.Expression]) -> str:
    """If the query has exactly one source in FROM (no JOINs), return its alias.
    Used to attribute bare-column passthroughs."""
    if query.args.get("joins"):
        return ""
    if len(alias_map) == 1:
        return next(iter(alias_map.keys()))
    return ""


def _star_alias(proj: exp.Expression) -> str:
    """If proj is an `alias.*` style projection, return alias; else ''."""
    if isinstance(proj, exp.Column) and isinstance(proj.this, exp.Star):
        return proj.table
    # sqlglot also represents `t.*` as Star with table=Identifier(t)
    if isinstance(proj, exp.Star):
        return ""
    return ""


def _qualified_name(t: exp.Table) -> str:
    parts: list[str] = []
    if t.args.get("catalog"):
        parts.append(str(t.args["catalog"]))
    if t.args.get("db"):
        parts.append(str(t.args["db"]))
    # For TVF calls, `t.this` is an Anonymous function; use its name.
    inner = t.this
    if isinstance(inner, exp.Anonymous):
        nm = getattr(inner, "name", None) or str(inner.this)
        parts.append(nm)
    elif hasattr(inner, "name") and inner.name:
        parts.append(inner.name)
    else:
        parts.append(t.name or str(inner))
    return ".".join(p for p in parts if p)


def _add_snippet(query: exp.Select, out: ExtractedExpression) -> None:
    try:
        s = query.sql(dialect="tsql")
    except Exception:
        s = ""
    if s and s not in out.raw_sql_snippets:
        out.raw_sql_snippets.append(s[:4000])


def _extract_from_view_or_function(
    inner_sql: str,
    target_col: str,
    out: ExtractedExpression,
) -> None:
    """Populate `out` from a parsed view/TVF body SQL."""
    try:
        trees = sqlglot.parse(inner_sql, read="tsql")
    except Exception as e:
        out.notes.append(f"sqlglot parse error: {e}")
        return
    trees = [t for t in trees if t is not None]
    if not trees:
        out.notes.append("sqlglot produced no statements")
        return

    root = trees[0]
    if isinstance(root, exp.Subquery):
        root = root.this

    cte_map = _build_cte_map(root)
    branches = _find_through_query(root, target_col, cte_map, out, depth=0)

    if not branches:
        out.notes.append(f"column {target_col!r} not found by CTE walk")
        return

    # Record source objects from branches.
    for b in branches:
        if b.source_object and b.source_object not in out.source_objects:
            out.source_objects.append(b.source_object)

    if len(branches) == 1:
        out.primary = branches[0]
    else:
        out.branches = branches
        # Prefer a non-literal branch as the primary citation.
        out.primary = next((b for b in branches if b.kind != "literal"), branches[0])
    out.confidence = "parsed"


# ---------------------------------------------------------------------------
# Stored Procedure extraction
# ---------------------------------------------------------------------------

_INSERT_BLOCK_RE = re.compile(
    r"INSERT\s+INTO\s+"
    r"(?:\[?(?P<schema>\w+)\]?\.)?\[?(?P<table>\w+)\]?\s*"
    r"\(\s*(?P<cols>[^)]+?)\s*\)\s*"
    r"SELECT\s+(?P<sel>.*?)"
    r"(?=\s*(?:--\s*|GO\s|INSERT\s+INTO|UPDATE\s+|DELETE\s+FROM|CREATE\s+TABLE|IF\s+OBJECT_ID|PRINT\s|END\s*$|$))",
    re.IGNORECASE | re.DOTALL,
)

# CREATE TABLE #temp [WITH (...)] AS SELECT ... (T-SQL CTAS used in Synapse DW).
# The WITH (...) clause has nested parens; use a permissive .*? between the
# name and the AS SELECT, relying on `\bAS\b\s+SELECT` to anchor the body.
_CTAS_RE = re.compile(
    r"CREATE\s+TABLE\s+(?P<name>#?\[?\w+\]?)"
    r"[\s\S]*?"
    r"\bAS\b\s+(?P<sel>SELECT\s[\s\S]*?)"
    r"(?=\s*(?:PRINT\s|IF\s+OBJECT_ID|CREATE\s+TABLE|INSERT\s+INTO|UPDATE\s+|DELETE\s+FROM|MERGE\s+|--\s|$))",
    re.IGNORECASE,
)


def _split_col_list(col_list_sql: str) -> list[str]:
    """Split a comma-separated col list, respecting square brackets."""
    out: list[str] = []
    cur = ""
    depth = 0
    for ch in col_list_sql:
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
        elif ch == "," and depth == 0:
            out.append(cur.strip().strip("[]"))
            cur = ""
            continue
        cur += ch
    if cur.strip():
        out.append(cur.strip().strip("[]"))
    return out


def _extract_from_stored_procedure(
    sql_text: str,
    target_col: str,
    target_table: str,
    out: ExtractedExpression,
) -> None:
    """For an SP that populates `target_table`:

      1. Find INSERT INTO target_table (col_list) SELECT col_list FROM <alias>.
      2. Ordinal-align target_col to a SELECT-side column name.
      3. Treat all CREATE TABLE #temp AS SELECT ... blocks as if they were
         CTEs, build a temp_map, and pass it to `_find_through_query`. That
         walker handles passthroughs (qualified and unqualified), star
         projections, and unions uniformly.
    """
    sql_clean = _strip_comments(sql_text)

    # 1. Find the INSERT into our target table.
    target_lower = target_table.lower()
    insert_match: Optional[re.Match] = None
    for m in _INSERT_BLOCK_RE.finditer(sql_clean):
        if m.group("table").lower() == target_lower:
            insert_match = m
            break
    if not insert_match:
        out.notes.append(f"no INSERT INTO {target_table} found in SP body")
        return

    cols = _split_col_list(insert_match.group("cols"))
    try:
        idx = [c.lower() for c in cols].index(target_col.lower())
    except ValueError:
        out.notes.append(f"{target_col!r} not in INSERT col list of {target_table}")
        return

    # 2. Parse the SELECT after INSERT INTO ... to extract the projection at `idx`.
    select_sql = "SELECT " + insert_match.group("sel")
    select_sql = select_sql.strip().rstrip(";")
    select_node = _try_parse_select(select_sql)
    if select_node is None:
        out.notes.append("could not parse INSERT-side SELECT statement")
        return
    projections = _walk_select_projections(select_node)
    if idx >= len(projections):
        out.notes.append(
            f"INSERT col list has {len(cols)} entries but SELECT has only {len(projections)}"
        )
        return

    # 3. Substitute the projection at index `idx` with an alias for
    #    `target_col`, so that the standard walker can hunt for it. The
    #    column list inside INSERT INTO is the SOURCE OF TRUTH for the
    #    target column name -- the inner SELECT may use a different alias.
    proj = projections[idx]
    inner = _project_inner(proj)
    proj_col = _project_name(proj)
    if proj_col.lower() != target_col.lower():
        # Renamed in the projection; rebuild the alias so walker matches.
        try:
            inner_sql = inner.sql(dialect="tsql")
        except Exception:
            inner_sql = str(inner)
        out.notes.append(
            f"INSERT col '{target_col}' aligned to SELECT '{proj_col}' (expr: {inner_sql})"
        )

    # 4. Build the temp-table map; treat temp tables as CTEs.
    ctas_map = _build_ctas_map(sql_clean)
    # ctas_map keys are lower-cased without the '#' prefix. Add '#name' alias
    # too so qualified references like `f.Amount` where f -> `#final` resolve.
    temp_map: dict[str, exp.Expression] = {}
    for k, v in ctas_map.items():
        temp_map[k] = v
        temp_map["#" + k] = v

    # 5. Use the unified walker against the INSERT-side SELECT. We pass the
    #    proj_col (the SELECT-side name) since that's the name in this query.
    branches = _find_through_query(select_node, proj_col, temp_map, out, depth=0)

    if not branches:
        out.notes.append(f"could not trace {target_col!r} through SP temp tables")
        return

    out.chain = branches  # walker may yield 1+ branches; we store as chain
    for b in branches:
        if b.source_object and b.source_object not in out.source_objects:
            if not b.source_object.startswith("#"):
                out.source_objects.append(b.source_object)

    if len(branches) == 1:
        out.primary = branches[0]
    else:
        out.primary = next((b for b in branches if b.kind != "literal"), branches[0])
    out.confidence = "parsed"
    out.column = target_col  # restore the canonical target column name


def _try_parse_select(sql: str) -> Optional[exp.Select]:
    """Try to parse `sql` (already comment-stripped, starts with SELECT) into
    a sqlglot Select node."""
    try:
        trees = sqlglot.parse(sql, read="tsql")
    except Exception:
        return None
    for t in trees:
        if isinstance(t, exp.Select):
            return t
        if isinstance(t, exp.Subquery) and isinstance(t.this, exp.Select):
            return t.this
    return None


def _build_ctas_map(sql_clean: str) -> dict[str, exp.Select]:
    """Map temp-table-name (lower, stripped of '#') -> its CTAS SELECT node."""
    out: dict[str, exp.Select] = {}
    for m in _CTAS_RE.finditer(sql_clean):
        name = m.group("name").strip().lstrip("#").strip("[]").lower()
        sel_sql = m.group("sel").strip().rstrip(";")
        node = _try_parse_select(sel_sql)
        if node is not None:
            out[name] = node
    return out


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

def extract_column(
    sql_path: Path,
    object_kind: str,
    column: str,
    target_table: str = "",
) -> ExtractedExpression:
    """Extract the producing expression(s) for `column` from `sql_path`.

    For tables: `target_table` is the table being populated; required for SP routing.
    """
    out = ExtractedExpression(
        column=column,
        object_kind=object_kind,
        sql_path=sql_path,
    )
    if not sql_path.exists():
        out.notes.append(f"sql file does not exist: {sql_path}")
        return out
    try:
        sql_text = sql_path.read_text(encoding="utf-8", errors="ignore")
    except Exception as e:
        out.notes.append(f"could not read sql file: {e}")
        return out

    batches = _split_batches(sql_text)
    body = "\n".join(batches)

    if object_kind == "function":
        for b in batches:
            inner = _extract_fn_inner(b)
            if inner:
                _extract_from_view_or_function(inner, column, out)
                return out
        out.notes.append("CREATE FUNCTION header not found")
        return out

    if object_kind == "view":
        for b in batches:
            inner = _extract_view_inner(b)
            if inner:
                _extract_from_view_or_function(inner, column, out)
                return out
        out.notes.append("CREATE VIEW header not found")
        return out

    if object_kind == "stored_procedure" or object_kind == "table":
        if not target_table:
            out.notes.append("target_table required for SP/table extraction")
            return out
        _extract_from_stored_procedure(body, column, target_table, out)
        return out

    out.notes.append(f"unhandled object kind {object_kind!r}")
    return out


# ---------------------------------------------------------------------------
# CLI for hand testing
# ---------------------------------------------------------------------------

def _cli(argv=None) -> int:
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--sql", required=True, help="path to .sql file")
    ap.add_argument("--kind", required=True,
                    choices=["view", "function", "stored_procedure", "table"])
    ap.add_argument("--column", required=True)
    ap.add_argument("--target-table", default="",
                    help="for SP/table kind: the table being populated")
    args = ap.parse_args(argv)
    res = extract_column(
        Path(args.sql), args.kind, args.column, args.target_table,
    )
    print(f"column      : {res.column}")
    print(f"kind        : {res.object_kind}")
    print(f"confidence  : {res.confidence}")
    if res.primary:
        print(f"primary kind: {res.primary.kind}")
        print(f"primary expr: {res.primary.expression_sql}")
        if res.primary.label:
            print(f"branch label: {res.primary.label}")
        if res.primary.source_object:
            print(f"source obj  : {res.primary.source_object}")
    if res.branches:
        print(f"branches    : {len(res.branches)}")
        for i, b in enumerate(res.branches):
            label = f" [{b.label}]" if b.label else ""
            src = f" <- {b.source_object}" if b.source_object else ""
            print(f"  {i+1}.{label} ({b.kind}) {b.expression_sql}{src}")
    if res.chain:
        print(f"chain       : {len(res.chain)} step(s)")
        for i, c in enumerate(res.chain):
            src = f" <- {c.source_object}" if c.source_object else ""
            print(f"  step {i+1}: ({c.kind}) {c.expression_sql}{src}")
    if res.source_objects:
        print(f"sources     : {', '.join(res.source_objects)}")
    if res.notes:
        print("notes:")
        for n in res.notes:
            print(f"  - {n}")
    return 0


if __name__ == "__main__":
    raise SystemExit(_cli())
