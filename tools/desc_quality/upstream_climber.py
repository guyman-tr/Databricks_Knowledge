"""
Upstream wiki climber.

Given (object_name, column_name), find the first non-trivial Transformation /
Description cell upstream by walking the Source column hop-by-hop. Cycles and
runaway chains are bounded.

See `.cursor/rules/uc-pipeline-doc/description-quality.mdc` for the protocol.
"""
from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.cleanup_tier1.sql_locator import locate_sql  # noqa: E402
from tools.desc_quality.classify import Verdict, classify  # noqa: E402
from tools.desc_quality.sql_walker import walk_for_column_path  # noqa: E402
from tools.desc_quality.wiki_parse import (  # noqa: E402
    ParsedTable,
    parse_section_3_source_objects,
    parse_wiki,
)


WIKI_ROOT = _REPO_ROOT / "knowledge" / "synapse" / "Wiki"

# Subdirs that contain real object wikis. We skip `_deploy-index`, `_index`,
# `_alter_generation_report`, and `.lineage.md` / `.review-needed.md` sidecars.
_REAL_SUBDIRS = ("/Tables/", "/Views/", "/Functions/")
_SIDECAR_SUFFIXES = (".lineage.md", ".review-needed.md", ".audit.md")


# Source-cell parser. Accepts:
#   Foo.Bar
#   [Foo].[Bar]
#   `Foo`.`Bar`
#   Foo.[Bar]
#   Schema.Foo.Bar  (schema is dropped; the climber uses bare object names)
# Rejects multi-source ("Foo, Bar") and pure object-no-column ("Foo").
_SOURCE_RE = re.compile(
    r"""
    ^\s*
    (?:[`\[]?\w+[`\]]?\s*\.\s*)?       # optional schema prefix (dropped)
    (?P<obj>[`\[]?(?P<obj_inner>\w+)[`\]]?)
    \s*\.\s*
    (?P<col>[`\[]?(?P<col_inner>\w+)[`\]]?)
    \s*$
    """,
    re.VERBOSE,
)

# Aliases are short (1-5 char) identifiers used in SQL FROM clauses. Anything
# longer is treated as a (possibly-unknown) object name, not an alias.
_ALIAS_MAX_LEN = 5


@dataclass
class Hop:
    object_name: str
    column_name: str
    wiki_path: str | None
    semantic_cell: str
    verdict: str
    source_cell: str
    note: str = ""  # any per-hop diagnostic (e.g. "unresolved_object")


@dataclass
class ClimbResult:
    start_object: str
    start_column: str
    hops: list[Hop] = field(default_factory=list)
    terminal_text: str | None = None
    terminal_object: str | None = None
    exhausted: bool = False
    exhausted_reason: str | None = None
    # When the terminal was produced by SQL-walking (not wiki-climbing), this
    # carries the SQL expression text. The rewriter renders it differently.
    sql_terminal_expression: str | None = None
    sql_terminal_kind: str | None = None  # case | coalesce | literal | ...
    sql_object_name: str | None = None    # the object whose SQL produced the expression
    # alias -> Schema.Table for every alias mentioned in sql_terminal_expression
    # (empty for trivial passthroughs and literals)
    sql_referenced_aliases: dict[str, str] = field(default_factory=dict)
    # For COALESCE/ISNULL terminals: structured leaf info. Each tuple is
    # (path, leaf_expr, leaf_kind, source_object, aliases_csv,
    #  guard_where, guard_aliases_csv).
    # The *_csv fields are "alias=Schema.Table[,alias=...]" so the lru_cache
    # key stays hashable.
    sql_branch_leaves: tuple[tuple[str, str, str, str, str, str, str], ...] = field(default_factory=tuple)
    sql_branches_converge: bool = True

    def trace_oneline(self) -> str:
        parts = [f"{h.object_name}.{h.column_name}" for h in self.hops]
        return " -> ".join(parts) if parts else "(no hops)"


# --- Wiki index ---

def _is_real_wiki(p: Path) -> bool:
    s = str(p).replace("\\", "/")
    if any(s.endswith(suf) for suf in _SIDECAR_SUFFIXES):
        return False
    if p.name.startswith("_"):
        return False
    return any(seg in s for seg in _REAL_SUBDIRS)


@lru_cache(maxsize=1)
def _build_index() -> dict[str, Path]:
    """Map bare object name (case-insensitive) -> wiki Path."""
    idx: dict[str, list[Path]] = {}
    for p in WIKI_ROOT.rglob("*.md"):
        if not _is_real_wiki(p):
            continue
        key = p.stem.lower()
        idx.setdefault(key, []).append(p)
    # Deduplicate: if multiple candidates, prefer the lexicographically-first
    # full path so the choice is deterministic. Log nothing — duplicates here
    # are real (Tables/ vs Views/) and the wikis are typically equivalent.
    return {k: sorted(v)[0] for k, v in idx.items()}


def resolve_wiki(object_name: str) -> Path | None:
    return _build_index().get(object_name.lower())


def parse_source_cell(cell: str) -> tuple[str, str] | None:
    """Return (object, column) or None if unparseable / multi-source."""
    if not cell or "," in cell:
        return None
    cell = cell.strip()
    # Strip a trailing "(alias …)" annotation if present so we don't fail to
    # match. Rare in Source cells but defensive.
    cell = re.sub(r"\s*\(.*?\)\s*$", "", cell)
    m = _SOURCE_RE.match(cell)
    if not m:
        return None
    return m.group("obj_inner"), m.group("col_inner")


# --- Per-wiki row index ---

@lru_cache(maxsize=4096)
def _parse_wiki_cached(wiki_path: str) -> ParsedTable:
    return parse_wiki(Path(wiki_path))


def _find_row(tbl: ParsedTable, column_name: str):
    lc = column_name.lower()
    for r in tbl.rows:
        if r.column.lower() == lc:
            return r
    return None


# --- §3 Source Objects fallback ---

@lru_cache(maxsize=4096)
def _section3_candidates(wiki_path: str) -> tuple[str, ...]:
    """Cached list of §3 Source Object names for a wiki."""
    return tuple(parse_section_3_source_objects(Path(wiki_path)))


@lru_cache(maxsize=4096)
def _alias_map(wiki_path: str) -> tuple[tuple[str, str], ...]:
    """For a wiki whose Source cells use SQL aliases (e.g. `isn.IsFuture`),
    resolve each alias to one of the §3 Source Objects via column-set overlap.

    Algorithm:
      1. Parse the wiki's §4 rows. Group rows by the alias prefix of their
         Source cell, when the cell looks like `<short_alias>.<column>` AND
         <short_alias> does not resolve in the wiki index.
      2. For each alias, intersect the set of columns referenced via that alias
         with the column set of each §3 candidate. The candidate with the
         largest intersection wins; ties leave the alias unresolved.

    Returns a tuple of (alias, object_name) pairs. Tuple is hashable so the
    function can be `lru_cache`d.
    """
    tbl = _parse_wiki_cached(wiki_path)
    if not tbl.rows or not tbl.has_source_column:
        return ()
    candidates = _section3_candidates(wiki_path)
    if not candidates:
        return ()

    alias_columns: dict[str, set[str]] = {}
    for r in tbl.rows:
        cell = (r.source or "").strip()
        if not cell or "," in cell:
            continue
        if "." not in cell:
            continue
        alias_part, _, col_part = cell.partition(".")
        alias_part = alias_part.strip().strip("`").strip("[").strip("]")
        col_part = col_part.strip().strip("`").strip("[").strip("]")
        if len(alias_part) > _ALIAS_MAX_LEN:
            continue
        # If the alias name DOES resolve to a wiki, it's already a real object,
        # not an alias. Skip it.
        if resolve_wiki(alias_part) is not None:
            continue
        alias_columns.setdefault(alias_part, set()).add(col_part.lower())

    if not alias_columns:
        return ()

    # For each candidate, materialize its column set.
    candidate_cols: dict[str, set[str]] = {}
    for cand in candidates:
        cwp = resolve_wiki(cand)
        if cwp is None:
            continue
        ctbl = _parse_wiki_cached(str(cwp))
        candidate_cols[cand] = {r.column.lower() for r in ctbl.rows if r.column}

    out: list[tuple[str, str]] = []
    for alias, cols in alias_columns.items():
        best = None
        best_score = 0
        ambiguous = False
        for cand, ccols in candidate_cols.items():
            score = len(cols & ccols)
            if score == 0:
                continue
            if score > best_score:
                best = cand
                best_score = score
                ambiguous = False
            elif score == best_score:
                ambiguous = True
        if best and not ambiguous and best_score >= 1:
            out.append((alias, best))
    return tuple(out)


# Schema-precedence for tie-breaking. Lower priority value = more
# upstream/authoritative. Wikis whose path contains the first matching
# substring get that priority. The default (no match) is 99.
_SCHEMA_PRIORITY = (
    ("/DWH_dbo/", 1),
    ("/Dealing_dbo/", 2),
    ("/eMoney_dbo/", 3),
    ("/eMoney_Tribe/", 3),
    ("/EXW_dbo/", 4),
    ("/EXW_Wallet/", 4),
    ("/BI_DB_dbo/", 5),
)


def _schema_priority(wp: Path) -> int:
    s = str(wp).replace("\\", "/")
    for marker, pri in _SCHEMA_PRIORITY:
        if marker in s:
            return pri
    return 99


@lru_cache(maxsize=4096)
def _primary_section3_source(wiki_path: str) -> str | None:
    """Pick the §3 Source Object that best represents THIS wiki's primary
    upstream. Used as a tie-breaker when a column appears in multiple §3
    candidates.

    Ranking key (descending priority):
      1. Larger column-set overlap with this wiki's §4.
      2. Lower _schema_priority (DWH_dbo > BI_DB_dbo).
      3. Larger total row count in the candidate (more comprehensive).
    Returns None when there is no §3 list or any of the steps still tie at top.
    """
    candidates = _section3_candidates(wiki_path)
    if not candidates:
        return None
    tbl = _parse_wiki_cached(wiki_path)
    if not tbl.rows:
        return None
    my_cols = {r.column.lower() for r in tbl.rows if r.column}

    scored: list[tuple[int, int, int, str]] = []  # (overlap, -schema_pri, row_count, name)
    for cand in candidates:
        cwp = resolve_wiki(cand)
        if cwp is None:
            continue
        ctbl = _parse_wiki_cached(str(cwp))
        cset = {r.column.lower() for r in ctbl.rows if r.column}
        overlap = len(my_cols & cset)
        if overlap == 0:
            continue
        scored.append((overlap, -_schema_priority(cwp), len(ctbl.rows), cand))
    if not scored:
        return None
    scored.sort(reverse=True)
    # Uniqueness check on full sort key prefix (overlap, schema, rows): if the
    # top two tie on ALL three, we still consider the top winner — the only
    # disambiguator that would remain is column-by-column overlap, which we
    # don't have at the primary level. Picking the first deterministic order is
    # acceptable; the dry-run diff is reviewable.
    return scored[0][3]


# --- SQL-grounded fallback ---

# Kinds where the SQL walker output is rich enough to use AS-IS as the
# Transformation cell text.
_SQL_USABLE_KINDS = {"case", "coalesce", "cast", "literal", "function", "expression"}


@lru_cache(maxsize=2048)
def _sql_walk_cached(
    wiki_path: str, column: str
) -> tuple[
    str,                                                   # expr or upstream_column
    str,                                                   # kind
    str,                                                   # source_object
    tuple[tuple[str, str], ...],                           # aliases (sorted)
    tuple[tuple[str, str, str, str, str, str, str], ...], # branch leaves (now w/ guard)
    bool,                                                  # branches_converge
]:
    """Returns (expr_or_upstream_column, kind, source_object, aliases, leaves, converge).

    `aliases` is a sorted tuple of (alias, qualified_table) pairs for aliases
    referenced in the terminal expression itself.

    `leaves` is a sorted tuple of (path, leaf_expr, leaf_kind, source_object,
    aliases_csv) — one per leaf when the terminal is a COALESCE/ISNULL/CAST
    wrapper. Empty tuple for non-wrappers (CASE, literal, passthrough).

    `converge` is True when all non-empty leaves share the same normalised
    expression — i.e. it's safe to describe the column with a single leaf.
    Trivially True when there are no leaves.

    Semantics by `kind`:
      - case|coalesce|cast|literal|function|expression:
            `expr_or_upstream_column` is a SQL expression to render directly.
      - passthrough:
            `expr_or_upstream_column` is the upstream column name (often same
            as input column), and `source_object` names the real upstream
            object. Caller climbs there.
      - "" (empty kind):
            SQL walk failed; tuple is ("", "", "", (), (), True).
    """
    loc = locate_sql(Path(wiki_path))
    if not loc.sql_paths:
        return "", "", "", (), (), True
    if loc.object_kind not in ("function", "view"):
        return "", "", "", (), (), True
    for sp in loc.sql_paths:
        res = walk_for_column_path(sp, column, loc.object_kind)
        aliases = tuple(sorted((res.referenced_aliases or {}).items()))
        leaves_t = tuple(
            (
                b.path,
                b.leaf_expr,
                b.leaf_kind,
                b.source_object,
                ",".join(f"{k}={v}" for k, v in sorted((b.aliases or {}).items())),
                b.guard_where,
                ",".join(f"{k}={v}" for k, v in sorted((b.guard_aliases or {}).items())),
            )
            for b in (res.branch_resolutions or [])
        )
        if res.terminal_expression and res.kind in _SQL_USABLE_KINDS:
            return (
                res.terminal_expression,
                res.kind,
                res.source_object or loc.object_name,
                aliases,
                leaves_t,
                bool(res.branches_converge),
            )
        if res.kind == "passthrough" and res.source_object:
            up_col = res.terminal_expression
            if "." in up_col:
                up_col = up_col.split(".", 1)[1].strip().strip("`").strip("[").strip("]")
            return up_col or column, "passthrough", res.source_object, (), (), True
    return "", "", "", (), (), True


def _strip_schema_prefix(qualified: str) -> str:
    """`DWH_dbo.Dim_Instrument` -> `Dim_Instrument`. Pass through bare names."""
    parts = qualified.split(".")
    return parts[-1] if parts else qualified


def _resolve_via_section3(
    starting_wiki: Path, column: str, source_cell: str
) -> tuple[str, str, str] | None:
    """Try to resolve (object, column, reason) for a row whose Source cell did
    not directly resolve. Returns (target_obj, target_col, why) or None.

    Branches in priority order:
      A. ALIASED cell `isn.IsFuture` → use the wiki's alias_map (column-set
         overlap per alias) to translate `isn` to a §3 candidate.
      B. EMPTY cell, column has UNIQUE §3 match → use it.
      C. EMPTY cell, column has MULTIPLE §3 matches → use the wiki's PRIMARY
         §3 source (the §3 candidate that has the largest overlap with this
         wiki's column set overall) if that primary has the column.
    """
    cell = (source_cell or "").strip()
    candidates = _section3_candidates(str(starting_wiki))

    # Branch A: aliased
    if cell and "." in cell and "," not in cell:
        alias_part, _, col_part = cell.partition(".")
        alias_part = alias_part.strip().strip("`").strip("[").strip("]")
        col_part = col_part.strip().strip("`").strip("[").strip("]")
        if len(alias_part) <= _ALIAS_MAX_LEN and resolve_wiki(alias_part) is None:
            am = dict(_alias_map(str(starting_wiki)))
            if alias_part in am:
                return am[alias_part], col_part, f"alias:{alias_part}->{am[alias_part]}"

    if not cell:
        if not candidates:
            return None
        found: list[str] = []
        for cand in candidates:
            cwp = resolve_wiki(cand)
            if cwp is None:
                continue
            ctbl = _parse_wiki_cached(str(cwp))
            r = _find_row(ctbl, column)
            if r is not None:
                found.append(cand)
        # Branch B: unique match
        if len(found) == 1:
            return found[0], column, f"section3_unique:{found[0]}"
        # Branch C: multiple matches -> prefer primary §3 source if it has the column
        if len(found) >= 2:
            primary = _primary_section3_source(str(starting_wiki))
            if primary and primary in found:
                return primary, column, f"section3_primary:{primary}"
            # Branch D: primary doesn't have the column; pick by schema priority
            # among the FOUND candidates. Lowest schema priority wins (DWH_dbo
            # beats BI_DB_dbo). Ties further broken by total row count.
            ranked: list[tuple[int, int, str]] = []
            for cand in found:
                cwp = resolve_wiki(cand)
                if cwp is None:
                    continue
                ctbl = _parse_wiki_cached(str(cwp))
                ranked.append((_schema_priority(cwp), -len(ctbl.rows), cand))
            if not ranked:
                return None
            ranked.sort()
            top = ranked[0]
            # If two candidates tie on (schema, -rows) the first by sort wins
            # deterministically. Acceptable: same source-tier and same size.
            tied_at_top = sum(1 for r in ranked if r[:2] == top[:2])
            if tied_at_top == 1 or top[0] < 99:
                return top[2], column, f"section3_schema_priority:{top[2]}"

    return None


# --- The climb ---

def climb_upstream(
    object_name: str,
    column_name: str,
    hop_cap: int = 5,
) -> ClimbResult:
    result = ClimbResult(start_object=object_name, start_column=column_name)
    visited: set[tuple[str, str]] = set()

    cur_obj, cur_col = object_name, column_name
    for _ in range(hop_cap + 1):
        key = (cur_obj.lower(), cur_col.lower())
        if key in visited:
            result.exhausted = True
            result.exhausted_reason = "cycle"
            return result
        visited.add(key)

        wiki_path = resolve_wiki(cur_obj)
        if wiki_path is None:
            result.hops.append(
                Hop(
                    object_name=cur_obj,
                    column_name=cur_col,
                    wiki_path=None,
                    semantic_cell="",
                    verdict="UNRESOLVED",
                    source_cell="",
                    note="unresolved_object",
                )
            )
            result.exhausted = True
            result.exhausted_reason = "unresolved_object"
            return result

        tbl = _parse_wiki_cached(str(wiki_path))
        if tbl.skipped_reason and not tbl.rows:
            # Wiki has no usable column table. Try SQL walker on this object
            # before giving up.
            sql_expr, sql_kind, sql_obj, sql_aliases, sql_leaves, sql_converge = _sql_walk_cached(str(wiki_path), cur_col)
            hop_record = Hop(
                object_name=cur_obj,
                column_name=cur_col,
                wiki_path=str(wiki_path.relative_to(_REPO_ROOT)).replace("\\", "/"),
                semantic_cell="",
                verdict="WIKI_NO_TABLE",
                source_cell="",
                note=tbl.skipped_reason,
            )
            result.hops.append(hop_record)
            if sql_kind == "passthrough" and sql_obj:
                upstream_obj = _strip_schema_prefix(sql_obj)
                hop_record.note = f"{tbl.skipped_reason}; sql_walk:passthrough->{sql_obj}"
                cur_obj, cur_col = upstream_obj, sql_expr or cur_col
                continue
            if sql_expr and sql_kind:
                hop_record.note = f"{tbl.skipped_reason}; sql_walk:{sql_kind}"
                result.sql_terminal_expression = sql_expr
                result.sql_terminal_kind = sql_kind
                result.sql_object_name = sql_obj or cur_obj
                result.sql_referenced_aliases = dict(sql_aliases)
                result.sql_branch_leaves = sql_leaves
                result.sql_branches_converge = sql_converge
                result.terminal_text = sql_expr
                result.terminal_object = cur_obj
                return result
            result.exhausted = True
            result.exhausted_reason = tbl.skipped_reason
            return result

        row = _find_row(tbl, cur_col)
        if row is None:
            sql_expr, sql_kind, sql_obj, sql_aliases, sql_leaves, sql_converge = _sql_walk_cached(str(wiki_path), cur_col)
            hop_record = Hop(
                object_name=cur_obj,
                column_name=cur_col,
                wiki_path=str(wiki_path.relative_to(_REPO_ROOT)).replace("\\", "/"),
                semantic_cell="",
                verdict="COLUMN_NOT_FOUND",
                source_cell="",
                note="column_not_in_upstream",
            )
            result.hops.append(hop_record)
            if sql_kind == "passthrough" and sql_obj:
                upstream_obj = _strip_schema_prefix(sql_obj)
                hop_record.note = f"column_not_in_upstream; sql_walk:passthrough->{sql_obj}"
                cur_obj, cur_col = upstream_obj, sql_expr or cur_col
                continue
            if sql_expr and sql_kind:
                hop_record.note = f"column_not_in_upstream; sql_walk:{sql_kind}"
                result.sql_terminal_expression = sql_expr
                result.sql_terminal_kind = sql_kind
                result.sql_object_name = sql_obj or cur_obj
                result.sql_referenced_aliases = dict(sql_aliases)
                result.sql_branch_leaves = sql_leaves
                result.sql_branches_converge = sql_converge
                result.terminal_text = sql_expr
                result.terminal_object = cur_obj
                return result
            result.exhausted = True
            result.exhausted_reason = "column_not_found"
            return result

        verdict, _signal = classify(row.semantic_cell)
        hop = Hop(
            object_name=cur_obj,
            column_name=cur_col,
            wiki_path=str(wiki_path.relative_to(_REPO_ROOT)).replace("\\", "/"),
            semantic_cell=row.semantic_cell,
            verdict=verdict.value,
            source_cell=row.source,
        )
        result.hops.append(hop)

        if verdict != Verdict.TRIVIAL:
            result.terminal_text = row.semantic_cell
            result.terminal_object = cur_obj
            return result

        # Trivial. First try the direct Source cell, then §3 fallback.
        next_obj_col: tuple[str, str] | None = None
        next_note = ""
        if tbl.has_source_column:
            parsed = parse_source_cell(row.source)
            if parsed is not None:
                # Verify the parsed object resolves before committing to it;
                # if not, the §3 fallback (alias map) may still rescue it.
                cand_obj, cand_col = parsed
                if resolve_wiki(cand_obj) is not None:
                    next_obj_col = (cand_obj, cand_col)
                    next_note = "source_cell"
            # Fallback: §3 alias map or empty-cell §3 sweep
            if next_obj_col is None:
                resolved = _resolve_via_section3(wiki_path, cur_col, row.source)
                if resolved is not None:
                    next_obj_col = (resolved[0], resolved[1])
                    next_note = resolved[2]

        if next_obj_col is None:
            # All wiki-based avenues failed. Last resort: SQL walker on the
            # current hop's wiki object (only views/functions in this phase).
            sql_expr, sql_kind, sql_obj, sql_aliases, sql_leaves, sql_converge = _sql_walk_cached(str(wiki_path), cur_col)
            if sql_kind == "passthrough" and sql_obj:
                upstream_obj = _strip_schema_prefix(sql_obj)
                clean_obj = sql_obj.strip().strip('"').strip("[").strip("]")
                if "." in clean_obj:
                    parts = [
                        p.strip().strip('"').strip("[").strip("]")
                        for p in clean_obj.split(".")
                    ]
                    clean_obj = ".".join(p for p in parts if p)
                upstream_col = sql_expr or cur_col
                if resolve_wiki(upstream_obj) is not None:
                    hop.note = f"sql_walk:passthrough->{clean_obj}"
                    next_obj_col = (upstream_obj, upstream_col)
                    next_note = f"sql_walk:passthrough->{clean_obj}"
                else:
                    hop.note = f"sql_walk:passthrough->{clean_obj} (no_wiki)"
                    result.sql_terminal_expression = (
                        f"Passthrough from {clean_obj}.{upstream_col} (no upstream wiki)"
                    )
                    result.sql_terminal_kind = "passthrough"
                    result.sql_object_name = clean_obj
                    result.terminal_text = result.sql_terminal_expression
                    result.terminal_object = cur_obj
                    return result
            elif sql_expr and sql_kind:
                hop.note = f"sql_walk:{sql_kind}"
                result.sql_terminal_expression = sql_expr
                result.sql_terminal_kind = sql_kind
                result.sql_object_name = sql_obj or cur_obj
                result.sql_referenced_aliases = dict(sql_aliases)
                result.sql_branch_leaves = sql_leaves
                result.sql_branches_converge = sql_converge
                result.terminal_text = sql_expr
                result.terminal_object = cur_obj
                return result

        if next_obj_col is None:
            # Could not advance the chain.
            if not tbl.has_source_column:
                result.exhausted_reason = "no_source_column"
            elif not (row.source or "").strip():
                result.exhausted_reason = "empty_source_no_section3_match"
            elif "," in (row.source or ""):
                result.exhausted_reason = "multi_source"
            elif parse_source_cell(row.source) is None:
                result.exhausted_reason = "unparseable_source"
            else:
                result.exhausted_reason = "unresolved_object"
            result.exhausted = True
            return result

        # Annotate the hop note with how we resolved (for traceability)
        if next_note and next_note != "source_cell":
            hop.note = next_note
        cur_obj, cur_col = next_obj_col

    result.exhausted = True
    result.exhausted_reason = "hop_cap"
    return result


def _render_sql_terminal(result: ClimbResult) -> str:
    """Render an SQL-derived terminal honestly.

    Rules:
      - passthrough: terminal already names the source — render verbatim.
      - non-wrapper kinds (case/literal/function/...): render as-is + alias map.
      - wrapper kinds (coalesce/cast) with no branch leaves: degrade to
        non-wrapper rendering (no extra info to surface).
      - wrapper kinds with converging leaves: surface the single leaf, since
        every path through the wrapper agrees. Include the alias map of the
        leaf so the reader knows what the column references mean.
      - wrapper kinds with DIVERGENT leaves: keep the outer wrapper as the
        primary expression AND list each distinct leaf alongside its path.
        This is the case where one description text cannot tell the full
        story — we make divergence visible.
    """
    expr = result.sql_terminal_expression or ""
    kind = result.sql_terminal_kind or ""
    obj = result.sql_object_name or ""

    if kind == "passthrough":
        return expr

    leaves = result.sql_branch_leaves or ()
    converge = result.sql_branches_converge

    if kind in ("coalesce", "cast") and leaves:
        if converge:
            # All paths through the wrapper agree on the leaf — use it.
            (
                leaf_path, leaf_expr, leaf_kind, leaf_src, leaf_aliases_csv,
                guard_where, guard_aliases_csv,
            ) = leaves[0]
            base = f"{leaf_expr} (sql-derived [{leaf_kind}] from {obj})"
            alias_pairs = _merge_alias_csvs(leaf_aliases_csv, guard_aliases_csv)
            if alias_pairs:
                base = (
                    f"{base.rstrip()}; where "
                    f"{', '.join(f'{a} = {q}' for a, q in alias_pairs)}"
                )
            return base

        # Divergent: surface the wrapper + each distinct leaf with its guard.
        unique: list[tuple[str, str, str, str]] = []  # (leaf_expr, leaf_kind, guard_where, aliases_csv)
        seen_text: set[str] = set()
        for (
            _path, leaf_expr, leaf_kind, _leaf_src, leaf_aliases_csv,
            guard_where, guard_aliases_csv,
        ) in leaves:
            key = " ".join(leaf_expr.split()) + "|" + " ".join((guard_where or "").split())
            if key in seen_text:
                continue
            seen_text.add(key)
            merged_csv = leaf_aliases_csv + (("," + guard_aliases_csv) if guard_aliases_csv else "")
            unique.append((leaf_expr, leaf_kind, guard_where, merged_csv))

        # Render each leaf. For literals the guard IS the semantics; for
        # CASE/function leaves the expression already encodes the logic so
        # we still surface the guard (it scopes the rows) but more compactly.
        leaf_renders: list[str] = []
        all_alias_pairs: list[tuple[str, str]] = []
        for leaf_expr, leaf_kind, guard_where, merged_csv in unique:
            pairs = _parse_alias_csv(merged_csv)
            for ap in pairs:
                if ap not in all_alias_pairs:
                    all_alias_pairs.append(ap)
            if leaf_kind == "literal" and guard_where:
                leaf_renders.append(f"{leaf_expr} when ({guard_where})")
            elif leaf_kind == "literal":
                leaf_renders.append(f"{leaf_expr} (fallback)")
            elif guard_where:
                leaf_renders.append(f"{leaf_expr} (scoped by {guard_where})")
            else:
                leaf_renders.append(leaf_expr)

        base = (
            f"{expr} (sql-derived [{kind}, DIVERGENT] from {obj}); "
            f"branches: {' OR '.join(leaf_renders)}"
        )
        if all_alias_pairs:
            base = (
                f"{base.rstrip()}; where "
                f"{', '.join(f'{a} = {q}' for a, q in all_alias_pairs)}"
            )
        return base

    # Non-wrapper kind (case / literal / function / arithmetic / etc.)
    base = f"{expr} (sql-derived [{kind}] from {obj})"
    aliases = result.sql_referenced_aliases or {}
    if aliases:
        base = (
            f"{base.rstrip()}; where "
            f"{', '.join(f'{a} = {q}' for a, q in sorted(aliases.items()))}"
        )
    return base


def _parse_alias_csv(csv_text: str) -> list[tuple[str, str]]:
    """Parse 'alias=Schema.Table,alias=Other.Table' back into pairs."""
    out: list[tuple[str, str]] = []
    for chunk in (csv_text or "").split(","):
        chunk = chunk.strip()
        if not chunk or "=" not in chunk:
            continue
        a, q = chunk.split("=", 1)
        out.append((a.strip(), q.strip()))
    return out


def _merge_alias_csvs(*csv_texts: str) -> list[tuple[str, str]]:
    """Parse + dedupe (alias, table) pairs from multiple CSV inputs.
    Preserves first-seen order so the rendering is stable."""
    out: list[tuple[str, str]] = []
    for txt in csv_texts:
        for ap in _parse_alias_csv(txt):
            if ap not in out:
                out.append(ap)
    return out


def format_terminal_cell(result: ClimbResult, preserve_parens: str = "") -> str:
    """Render the new Transformation cell text per the spec.

    `preserve_parens` is any bookkeeping parenthetical the original cell carried
    (e.g. "legacy — always 0 since 2019") that should ride along.
    """
    if result.terminal_text is not None:
        if result.sql_terminal_expression is not None:
            base = _render_sql_terminal(result)
        else:
            base = f"{result.terminal_text} (via {result.terminal_object})"
        if preserve_parens:
            base = f"{base.rstrip()}; {preserve_parens.strip()}"
        return base
    # Exhausted — visible failure
    trace = " -> ".join(f"{h.object_name}.{h.column_name}" for h in result.hops)
    reason = result.exhausted_reason or "exhausted"
    return f"Passthrough — no upstream semantic (chain: {trace}, {reason})"


# --- CLI ---

def _cli() -> int:
    ap = argparse.ArgumentParser(description="Climb the upstream wiki chain for a column")
    ap.add_argument("--object", required=True)
    ap.add_argument("--column", required=True)
    ap.add_argument("--hop-cap", type=int, default=5)
    args = ap.parse_args()

    res = climb_upstream(args.object, args.column, hop_cap=args.hop_cap)
    print(f"Start: {res.start_object}.{res.start_column}")
    print(f"Terminal: {res.terminal_object}.{res.start_column}" if res.terminal_text else f"EXHAUSTED ({res.exhausted_reason})")
    print(f"Hops ({len(res.hops)}):")
    for i, h in enumerate(res.hops):
        print(f"  [{i}] {h.object_name}.{h.column_name} @ {h.wiki_path or '?'}")
        print(f"        verdict={h.verdict}  source={h.source_cell!r}")
        print(f"        cell={h.semantic_cell!r}")
        if h.note:
            print(f"        note={h.note}")
    print()
    print("Rendered cell:")
    print(f"  {format_terminal_cell(res)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(_cli())
