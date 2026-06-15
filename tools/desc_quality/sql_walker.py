"""sql_walker.py — given a TVF/view/SP SQL file and a column name, walk the
SELECT projections (including CTEs and subqueries) until we hit a non-trivial
producing expression (CASE, COALESCE, function, arithmetic, literal).

Used by the desc-quality climber as a SQL-grounded fallback when the wiki's
own §3 / §4 / alias data can't resolve a TRIVIAL row.

Returns a SqlWalkResult with:
  - terminal_expression: the producing SQL expression (string)
  - kind: case | coalesce | function | arithmetic | literal | passthrough | not_found
  - chain: list of (depth, alias_or_cte_or_table, expression_sql) hops walked
  - source_object: when the terminal IS a passthrough from a real (non-CTE) table,
    the qualified name of that table — caller can then climb the wiki of that table.
  - notes: any parser warnings
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

import sqlglot
from sqlglot import exp


@dataclass
class BranchResolution:
    """One LEAF arm of a (possibly nested) COALESCE/ISNULL/CAST wrapper.

    For `ISNULL(dp.ClosedOnDate, 0)`:
      - path="dp.ClosedOnDate -> 1", leaf_expr="1", leaf_kind="literal",
        guard_where="dp.CloseDateID = @dateID" (from the dp subquery)
      - path="0", leaf_expr="0", leaf_kind="literal", guard_where="" (fallback)
    """
    path: str = ""            # human-readable chain of expressions traversed
    leaf_expr: str = ""       # the final non-wrapper expression at the end of the path
    leaf_kind: str = ""       # literal | case | function | arithmetic | passthrough | unresolved_alias
    source_object: str = ""   # qualified table when the leaf is a passthrough from a real table
    aliases: dict[str, str] = field(default_factory=dict)
    # WHERE clause of the SELECT that produced this leaf — for literal leaves
    # this often IS the column's true semantic (e.g. `1 AS Closed WHERE CloseDateID = X`).
    guard_where: str = ""
    # alias -> Schema.Table mapping for any aliases mentioned in guard_where
    # (so the renderer can spell out what `dp.` means).
    guard_aliases: dict[str, str] = field(default_factory=dict)


@dataclass
class SqlWalkResult:
    column: str
    terminal_expression: str = ""
    kind: str = "not_found"
    chain: list[tuple[int, str, str]] = field(default_factory=list)
    source_object: str = ""           # set when terminal is passthrough from real table
    confidence: str = "unverifiable"  # parsed | partial | unverifiable
    notes: list[str] = field(default_factory=list)
    # alias -> "Schema.Table" mapping for every alias referenced in the terminal
    # expression, resolved against the SELECT where the terminal lives.
    referenced_aliases: dict[str, str] = field(default_factory=dict)
    # For COALESCE/ISNULL outer terminals: one entry per argument, with the
    # deeper resolution of that argument. Empty list when the terminal is not
    # a wrapper expression (e.g., bare CASE or literal).
    branch_resolutions: list[BranchResolution] = field(default_factory=list)
    # Whether all non-empty branch resolutions are structurally equivalent
    # (same normalised text). True for COALESCE(A,B) where both deepen to the
    # same expression. Meaningless when branch_resolutions is empty.
    branches_converge: bool = True


# --- SQL pre-processing ---

_GO_RE = re.compile(r"^\s*GO\s*$", re.IGNORECASE | re.MULTILINE)
_BLOCK_COMMENT_RE = re.compile(r"/\*.*?\*/", re.DOTALL)
_LINE_COMMENT_RE = re.compile(r"--[^\n]*")

_FN_HDR_RE = re.compile(
    r"CREATE\s+FUNCTION\s+(?:\[[^\]]+\]|\w+)\s*\.\s*(?:\[[^\]]+\]|\w+)\s*"
    r"\([^)]*\)\s*RETURNS\s+TABLE\s*AS\s*RETURN\s*\(",
    re.IGNORECASE | re.DOTALL,
)
_VIEW_HDR_RE = re.compile(
    r"CREATE\s+VIEW\s+(?:\[[^\]]+\]|\w+)\s*\.\s*(?:\[[^\]]+\]|\w+)\s*"
    r"(?:WITH\s+[^\s]+\s+)*AS\s*",
    re.IGNORECASE | re.DOTALL,
)


def _strip_comments(sql: str) -> str:
    return _LINE_COMMENT_RE.sub("", _BLOCK_COMMENT_RE.sub("", sql))


def _extract_fn_inner(sql: str) -> Optional[str]:
    sql = _strip_comments(sql)
    parts = _GO_RE.split(sql)
    body = "\n".join(p.strip() for p in parts if p.strip())
    m = _FN_HDR_RE.search(body)
    if not m:
        return None
    rest = body[m.end():].rstrip()
    if rest.endswith(";"):
        rest = rest[:-1].rstrip()
    # The header ate the opening `(`; strip the matching closing `)`.
    if rest.endswith(")"):
        rest = rest[:-1]
    return rest


def _extract_view_inner(sql: str) -> Optional[str]:
    sql = _strip_comments(sql)
    parts = _GO_RE.split(sql)
    body = "\n".join(p.strip() for p in parts if p.strip())
    m = _VIEW_HDR_RE.search(body)
    if not m:
        return None
    return body[m.end():].rstrip().rstrip(";")


def _parse(sql: str) -> Optional[exp.Expression]:
    try:
        return sqlglot.parse_one(sql, dialect="tsql")
    except Exception:
        return None


# --- Walker ---

# A projection is "trivial passthrough" if it's a bare Column reference. Anything
# else — CASE, COALESCE, Func, arithmetic, literal — is a non-trivial producer.
def _classify(node: exp.Expression) -> str:
    if isinstance(node, exp.Case):
        return "case"
    if isinstance(node, exp.Coalesce):
        return "coalesce"
    if isinstance(node, exp.Cast):
        return "cast"
    if isinstance(node, exp.Anonymous) or isinstance(node, exp.Func):
        return "function"
    if isinstance(node, exp.Literal):
        return "literal"
    if isinstance(node, exp.Null):
        return "literal"
    if isinstance(node, exp.Column):
        return "passthrough"
    return "expression"


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


def _is_star_projection(proj: exp.Expression) -> tuple[bool, str]:
    """Return (is_star, alias_qualifier). `alias_qualifier` is `f` for `f.*`,
    empty for `*`."""
    if isinstance(proj, exp.Star):
        return True, ""
    if isinstance(proj, exp.Column) and isinstance(proj.this, exp.Star):
        return True, proj.table or ""
    return False, ""


def _flatten_union(node: exp.Expression) -> list[exp.Select]:
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


def _collect_cte_map(root: exp.Expression) -> dict[str, exp.Expression]:
    """Aggregate ALL CTE definitions reachable from `root`, regardless of depth.

    Note: a CTE name shadowed at a deeper nesting will overwrite the outer one
    in this map, but in practice the wikis we operate on don't reuse CTE names.
    """
    out: dict[str, exp.Expression] = {}
    for w in root.find_all(exp.With):
        for cte in w.expressions:
            name = cte.alias_or_name
            if name:
                out[name.lower()] = cte.this
    return out


def _alias_map(sel: exp.Select) -> dict[str, exp.Expression]:
    """Map `alias -> source node` for every FROM/JOIN entry in this SELECT.

    The source node is either an exp.Table (real table OR CTE name) or the
    underlying exp.Select (when the source was a derived subquery).
    """
    out: dict[str, exp.Expression] = {}
    fr = sel.args.get("from") or sel.args.get("from_")
    sources: list[exp.Expression] = []
    if fr:
        # FROM clause may contain Tables and Subqueries as siblings.
        for child in fr.args.values():
            if isinstance(child, list):
                sources.extend(child)
            elif child is not None:
                sources.append(child)
    for j in sel.args.get("joins") or []:
        sources.append(j.this if hasattr(j, "this") else j)
    for s in sources:
        if isinstance(s, exp.Table):
            a = s.alias_or_name or s.name
            if a:
                out[a.lower()] = s
        elif isinstance(s, exp.Subquery):
            a = s.alias_or_name
            inner = s.this
            if a and inner is not None:
                out[a.lower()] = inner
        elif isinstance(s, exp.Alias):
            inner = s.this
            a = s.alias_or_name
            if a and inner is not None:
                if isinstance(inner, exp.Subquery):
                    inner = inner.this
                out[a.lower()] = inner
    return out


def _qualified_table_name(t: exp.Table) -> str:
    parts: list[str] = []
    if t.args.get("db"):
        parts.append(str(t.args["db"]))
    if hasattr(t.this, "name") and t.this.name:
        parts.append(t.this.name)
    else:
        parts.append(t.name)
    return ".".join(p for p in parts if p)


def _extract_referenced_aliases(
    expr: exp.Expression, alias_map: dict[str, exp.Expression]
) -> dict[str, str]:
    """For every `alias.col` reference in `expr`, look up the alias in the
    current SELECT's alias_map. If the alias resolves to a real (non-CTE,
    non-derived-subquery) table, record `alias -> Schema.Table`. CTE-aliases
    and derived-subquery aliases are NOT included (they only add noise — the
    reader can't navigate to them).
    """
    out: dict[str, str] = {}
    for col in expr.find_all(exp.Column):
        alias = (col.table or "").strip()
        if not alias:
            continue
        key = alias.lower()
        if key in out:
            continue
        src = alias_map.get(key)
        if isinstance(src, exp.Table):
            qn = _qualified_table_name(src)
            # Skip aliases pointing at CTEs — those names are local to the file.
            if qn:
                out[alias] = qn
    return out


def _walk(
    node: exp.Expression,
    column: str,
    cte_map: dict[str, exp.Expression],
    chain: list[tuple[int, str, str]],
    depth: int,
    max_depth: int = 10,
    aliases_out: dict[str, str] | None = None,
    terminal_select_holder: list[exp.Select] | None = None,
) -> tuple[str, str, str]:
    """Recursive walker. Returns (terminal_expression_sql, kind, source_object).

    `aliases_out`, when provided, is populated with the alias->Schema.Table
    map for every alias referenced in the terminal expression. The map is
    resolved against the SELECT where the terminal was found.

    `terminal_select_holder`, when provided as an (empty) list, will have the
    exact `exp.Select` where the terminal expression was found appended to it.
    This lets the caller hand the right SELECT to the deepening step instead
    of having to re-discover it heuristically.

    `source_object` is the qualified name of a real table when the terminal IS
    a bare passthrough from a real table (caller can climb to its wiki).
    Otherwise empty.
    """
    if depth > max_depth:
        return "", "not_found", ""

    if isinstance(node, exp.Subquery):
        return _walk(node.this, column, cte_map, chain, depth, max_depth, aliases_out, terminal_select_holder)

    if isinstance(node, exp.Union):
        for sel in _flatten_union(node):
            tx, kind, src = _walk(sel, column, cte_map, chain, depth + 1, max_depth, aliases_out, terminal_select_holder)
            if kind not in ("not_found", "passthrough") and tx:
                return tx, kind, src
        for sel in _flatten_union(node):
            tx, kind, src = _walk(sel, column, cte_map, chain, depth + 1, max_depth, aliases_out, terminal_select_holder)
            if tx:
                return tx, kind, src
        return "", "not_found", ""

    if not isinstance(node, exp.Select):
        return "", "not_found", ""

    sel = node
    am = _alias_map(sel)
    projections = list(sel.expressions or [])

    # Pass 1: direct projection match
    for proj in projections:
        if _project_name(proj).lower() == column.lower():
            inner = _project_inner(proj)
            kind = _classify(inner)
            try:
                expr_sql = inner.sql(dialect="tsql")
            except Exception:
                expr_sql = str(inner)
            chain.append((depth, f"<projection of {column}>", expr_sql))

            if kind != "passthrough":
                if aliases_out is not None:
                    aliases_out.update(_extract_referenced_aliases(inner, am))
                if terminal_select_holder is not None:
                    # Record the SELECT that owned the terminal projection.
                    terminal_select_holder.append(sel)
                return expr_sql, kind, ""

            # Passthrough: try to climb through the alias
            if isinstance(inner, exp.Column):
                alias = (inner.table or "").lower()
                target_col = inner.name
                if not alias:
                    if len(am) == 1 and not sel.args.get("joins"):
                        alias = next(iter(am.keys()))
                if alias and alias in am:
                    src = am[alias]
                    if isinstance(src, exp.Table):
                        cte_body = cte_map.get(src.name.lower())
                        if cte_body is not None:
                            return _walk(cte_body, target_col, cte_map, chain, depth + 1, max_depth, aliases_out, terminal_select_holder)
                        return expr_sql, "passthrough", _qualified_table_name(src)
                    return _walk(src, target_col, cte_map, chain, depth + 1, max_depth, aliases_out, terminal_select_holder)
                if alias and alias in cte_map:
                    return _walk(cte_map[alias], target_col, cte_map, chain, depth + 1, max_depth, aliases_out, terminal_select_holder)
                return expr_sql, "passthrough", ""
            return expr_sql, kind, ""

    # Pass 2: `alias.*` or bare `*` — column might be inherited
    for proj in projections:
        is_star, star_alias = _is_star_projection(proj)
        if not is_star:
            continue
        if star_alias:
            src = am.get(star_alias.lower())
            if isinstance(src, exp.Table):
                cte_body = cte_map.get(src.name.lower())
                if cte_body is not None:
                    return _walk(cte_body, column, cte_map, chain, depth + 1, max_depth, aliases_out, terminal_select_holder)
                return "", "passthrough", _qualified_table_name(src)
            if src is not None:
                return _walk(src, column, cte_map, chain, depth + 1, max_depth, aliases_out, terminal_select_holder)
            cte_body = cte_map.get(star_alias.lower())
            if cte_body is not None:
                return _walk(cte_body, column, cte_map, chain, depth + 1, max_depth, aliases_out, terminal_select_holder)
        else:
            for alias, src in am.items():
                if isinstance(src, exp.Table):
                    cte_body = cte_map.get(src.name.lower())
                    if cte_body is not None:
                        r = _walk(cte_body, column, cte_map, chain, depth + 1, max_depth, aliases_out, terminal_select_holder)
                        if r[0]:
                            return r
                else:
                    r = _walk(src, column, cte_map, chain, depth + 1, max_depth, aliases_out, terminal_select_holder)
                    if r[0]:
                        return r

    return "", "not_found", ""


def _is_wrapper_terminal(kind: str) -> bool:
    """Outer terminals worth deepening into (their immediate arguments carry
    semantic weight). CASE is intentionally NOT here — a CASE expression is
    already self-explanatory and deepening into its `cpt.PositionID` would
    explode for little gain."""
    return kind in ("coalesce", "cast")


def _normalise_expr_text(s: str) -> str:
    """Whitespace-collapse for cheap equality checks across branches."""
    return " ".join((s or "").split()).strip()


def _coalesce_args(node: exp.Expression) -> list[exp.Expression]:
    """Return the immediate arguments of a COALESCE / ISNULL / CAST node.
    sqlglot models COALESCE(a,b,c) as Coalesce(this=a, expressions=[b,c]).
    """
    if isinstance(node, exp.Cast):
        return [node.this] if node.this is not None else []
    args: list[exp.Expression] = []
    if node.this is not None:
        args.append(node.this)
    extra = getattr(node, "expressions", None) or []
    for e in extra:
        if e is not node.this:
            args.append(e)
    return args


def _expand_arg(
    arg: exp.Expression,
    sel: exp.Select,
    cte_map: dict[str, exp.Expression],
    chain: list[tuple[int, str, str]],
    depth: int,
    max_depth: int,
    path_so_far: str,
    out: list[BranchResolution],
    expand_depth: int = 0,
    expand_cap: int = 6,
) -> None:
    """Recursively expand `arg` (which is one argument of an outer COALESCE/
    ISNULL/CAST) until we hit a leaf expression, then emit one
    BranchResolution. Wrapper-of-wrappers are flattened: every literal/CASE/
    arithmetic/function/passthrough we encounter at any depth becomes its
    own row in `out`. Cycle/runaway protection via expand_cap."""
    if expand_depth > expand_cap:
        return

    try:
        arg_text = arg.sql(dialect="tsql")
    except Exception:
        arg_text = str(arg)
    new_path = arg_text if not path_so_far else f"{path_so_far} -> {arg_text}"

    # Literal: leaf. The producing SELECT's WHERE clause is critical here —
    # a literal `1 AS Closed` only means "Closed" when the WHERE selected the
    # right rows.
    if isinstance(arg, exp.Literal):
        guard, guard_aliases = _capture_guard(sel)
        out.append(
            BranchResolution(
                path=new_path,
                leaf_expr=arg_text,
                leaf_kind="literal",
                guard_where=guard,
                guard_aliases=guard_aliases,
            )
        )
        return

    # Column reference: resolve via alias map, then recurse on the projection
    # found inside the source.
    if isinstance(arg, exp.Column):
        am = _alias_map(sel)
        alias = (arg.table or "").lower()
        target_col = arg.name
        src = am.get(alias) if alias else None
        if src is None:
            out.append(
                BranchResolution(
                    path=new_path, leaf_expr=arg_text, leaf_kind="unresolved_alias"
                )
            )
            return
        if isinstance(src, exp.Table):
            cte_body = cte_map.get(src.name.lower())
            if cte_body is None:
                # Real (non-CTE) table — terminal passthrough. Capture the
                # current SELECT's WHERE as guard (relevant when the leaf is
                # a literal-like passthrough from a filtered SELECT).
                guard, guard_aliases = _capture_guard(sel)
                out.append(
                    BranchResolution(
                        path=new_path,
                        leaf_expr=arg_text,
                        leaf_kind="passthrough",
                        source_object=_qualified_table_name(src),
                        guard_where=guard,
                        guard_aliases=guard_aliases,
                    )
                )
                return
            sub = cte_body
        else:
            sub = src

        # Recurse into the producing SELECT for target_col.
        if isinstance(sub, exp.Select):
            sub_proj = _find_projection_node(sub, target_col)
            if sub_proj is None:
                # column might be inherited via `*` — fall back to _walk.
                deeper_aliases: dict[str, str] = {}
                tx, kind, src_obj = _walk(
                    sub, target_col, cte_map, chain, depth + 1, max_depth, deeper_aliases
                )
                if tx:
                    guard, guard_aliases = _capture_guard(sub)
                    out.append(
                        BranchResolution(
                            path=f"{new_path} -> {tx}",
                            leaf_expr=tx,
                            leaf_kind=kind,
                            source_object=src_obj,
                            aliases=deeper_aliases,
                            guard_where=guard,
                            guard_aliases=guard_aliases,
                        )
                    )
                else:
                    out.append(
                        BranchResolution(
                            path=new_path, leaf_expr="", leaf_kind="not_found"
                        )
                    )
                return
            _expand_arg(
                sub_proj, sub, cte_map, chain, depth + 1, max_depth,
                new_path, out, expand_depth + 1, expand_cap,
            )
            return
        if isinstance(sub, exp.Union):
            for branch_sel in _flatten_union(sub):
                sub_proj = _find_projection_node(branch_sel, target_col)
                if sub_proj is None:
                    continue
                _expand_arg(
                    sub_proj, branch_sel, cte_map, chain, depth + 1, max_depth,
                    new_path, out, expand_depth + 1, expand_cap,
                )
            return

        out.append(BranchResolution(path=new_path, leaf_expr=arg_text, leaf_kind="unresolved"))
        return

    # Nested wrapper (COALESCE inside COALESCE, etc.) — recurse on each
    # sub-arg in the SAME outer SELECT.
    kind = _classify(arg)
    if kind in ("coalesce", "cast"):
        for sub_arg in _coalesce_args(arg):
            _expand_arg(
                sub_arg, sel, cte_map, chain, depth, max_depth,
                new_path, out, expand_depth + 1, expand_cap,
            )
        return

    # Anything else (CASE / function / arithmetic / etc.): leaf.
    # Capture aliases referenced inside this leaf so the renderer can label
    # things like `cpt.PositionID -> BI_DB_dbo.BI_DB_CopyFund_Positions`.
    leaf_aliases = _extract_referenced_aliases(arg, _alias_map(sel))
    out.append(
        BranchResolution(
            path=new_path,
            leaf_expr=arg_text,
            leaf_kind=kind,
            aliases=leaf_aliases,
        )
    )


def _find_projection_node(sel: exp.Select, column: str) -> Optional[exp.Expression]:
    """Return the inner expression of the projection named `column` in `sel`."""
    for proj in sel.expressions or []:
        if _project_name(proj).lower() == column.lower():
            return _project_inner(proj)
    return None


def _capture_guard(sel: exp.Select) -> tuple[str, dict[str, str]]:
    """Return (where_text, alias_map_for_aliases_in_where).

    The WHERE clause is serialised verbatim (T-SQL). We also resolve every
    alias referenced inside it through the SELECT's FROM/JOIN map, so the
    renderer can say `dp = DWH_dbo.Dim_Position` instead of leaving `dp.`
    as a mystery prefix.
    """
    where = sel.args.get("where")
    if where is None:
        return "", {}
    inner = where.this if hasattr(where, "this") else where
    if inner is None:
        return "", {}
    try:
        text = inner.sql(dialect="tsql")
    except Exception:
        text = str(inner)
    aliases = _extract_referenced_aliases(inner, _alias_map(sel))
    return text, aliases


def _resolve_coalesce_leaves(
    outer_node: exp.Expression,
    outer_select: exp.Select,
    cte_map: dict[str, exp.Expression],
    chain: list[tuple[int, str, str]],
    depth_start: int,
    max_depth: int,
) -> list[BranchResolution]:
    """Recursively expand `outer_node` (a COALESCE/ISNULL/CAST) into its
    leaves. Each leaf is a BranchResolution naming the path traversed and
    the producing expression."""
    leaves: list[BranchResolution] = []
    for arg in _coalesce_args(outer_node):
        _expand_arg(
            arg, outer_select, cte_map, chain, depth_start, max_depth,
            "", leaves, expand_depth=0, expand_cap=6,
        )
    return leaves


def walk_for_column(
    sql_text: str,
    column: str,
    object_kind: str = "function",
) -> SqlWalkResult:
    """Top-level entry. `object_kind` ∈ {function, view}."""
    res = SqlWalkResult(column=column)

    if object_kind == "function":
        inner = _extract_fn_inner(sql_text)
        if inner is None:
            res.notes.append("could_not_strip_fn_header")
            return res
    elif object_kind == "view":
        inner = _extract_view_inner(sql_text)
        if inner is None:
            res.notes.append("could_not_strip_view_header")
            return res
    else:
        res.notes.append(f"unsupported_object_kind:{object_kind}")
        return res

    root = _parse(inner)
    if root is None:
        res.notes.append("parse_failed")
        return res

    cte_map = _collect_cte_map(root)
    outer = root
    if isinstance(outer, exp.With):
        outer = outer.this
    chain: list[tuple[int, str, str]] = []
    outer_aliases: dict[str, str] = {}
    terminal_select_holder: list[exp.Select] = []
    tx, kind, src = _walk(
        outer, column, cte_map, chain, 0,
        aliases_out=outer_aliases,
        terminal_select_holder=terminal_select_holder,
    )
    res.terminal_expression = tx
    res.kind = kind
    res.chain = chain
    res.source_object = src
    res.referenced_aliases = outer_aliases

    # If terminal is a COALESCE/ISNULL/Cast wrapper, recursively expand ALL
    # arguments to their leaves so we report both sides honestly instead of
    # collapsing onto the first non-trivial finding. CASE expressions are
    # NOT deepened — they already name their own condition.
    if _is_wrapper_terminal(kind) and tx and terminal_select_holder:
        inner_select = terminal_select_holder[0]
        proj_inner = _find_projection_node(inner_select, column)
        if proj_inner is not None:
            leaves = _resolve_coalesce_leaves(
                proj_inner, inner_select, cte_map, chain, len(chain), 12,
            )
            res.branch_resolutions = leaves
            # Convergence: all non-empty leaves with the same normalised text.
            seen: set[str] = set()
            for b in leaves:
                if b.leaf_expr:
                    seen.add(_normalise_expr_text(b.leaf_expr))
            res.branches_converge = len(seen) <= 1
            res.notes.append(
                f"outer_wrapper:{kind}; leaves={len(leaves)}; distinct_leaves={len(seen)}"
            )

    if res.terminal_expression:
        res.confidence = "parsed" if res.kind != "not_found" else "partial"
    return res


def walk_for_column_path(
    sql_path: Path,
    column: str,
    object_kind: str = "function",
) -> SqlWalkResult:
    if not sql_path.exists():
        r = SqlWalkResult(column=column)
        r.notes.append(f"sql_path_missing:{sql_path}")
        return r
    text = sql_path.read_text(encoding="utf-8", errors="ignore")
    return walk_for_column(text, column, object_kind)


# --- CLI ---

def _main() -> None:
    import argparse

    p = argparse.ArgumentParser()
    p.add_argument("--sql", required=True, help="Path to SSDT .sql file")
    p.add_argument("--column", required=True)
    p.add_argument("--kind", default="function", choices=["function", "view"])
    args = p.parse_args()
    res = walk_for_column_path(Path(args.sql), args.column, args.kind)
    print(f"Column:        {res.column}")
    print(f"Confidence:    {res.confidence}")
    print(f"Kind:          {res.kind}")
    print(f"Source object: {res.source_object}")
    print(f"Terminal expr: {res.terminal_expression}")
    if res.referenced_aliases:
        print("Referenced aliases:")
        for a, qn in res.referenced_aliases.items():
            print(f"  {a} -> {qn}")
    if res.branch_resolutions:
        marker = "converge" if res.branches_converge else "DIVERGENT"
        print(f"Branch leaves ({marker}):")
        for i, b in enumerate(res.branch_resolutions):
            print(
                f"  [{i}] leaf={b.leaf_expr!r}  kind={b.leaf_kind}  "
                f"source={b.source_object or '-'}"
            )
            print(f"        path: {b.path}")
            if b.guard_where:
                print(f"        guard WHERE: {b.guard_where}")
            if b.guard_aliases:
                for a, qn in b.guard_aliases.items():
                    print(f"        guard alias: {a} -> {qn}")
            if b.aliases:
                for a, qn in b.aliases.items():
                    print(f"        alias: {a} -> {qn}")
    print(f"Chain ({len(res.chain)} hops):")
    for depth, where, expr in res.chain:
        print(f"  [{depth}] {where}: {expr[:160]}")
    if res.notes:
        print(f"Notes: {res.notes}")


if __name__ == "__main__":
    _main()
