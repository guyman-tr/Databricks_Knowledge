#!/usr/bin/env python3
"""
Phase 5 — Generate Wiki (UC-Pipeline pack, productized, 8-section golden).

Reads:
  - `_dag.json`                                       (Phase -1; wiki_status per upstream)
  - `_discovery/uc_inventory.json`                    (Phase 1; column metadata)
  - `_discovery/source_code/{obj}.{sql,py}`           (Phase 2; for narration)
  - `_discovery/column_lineage/{obj}.json`            (Phase 2; second-opinion)
  - `_discovery/upstream_wikis/_index.json` + bodies  (Phase 3; verbatim inherit source)
  - `{obj}.lineage.md`                                (Phase 4; mechanical lineage table)
  - `_discovery/concepts/{obj}.json`                  (Phase 4.5; named business concepts)
  - `_discovery/formulas/{obj}.json`                  (Phase 4.6; per-column formula lookup)

Writes:
  - `{obj}.md`                  (the wiki — 8-section GOLDEN skeleton)
  - `{obj}.review-needed.md`    (sidecar — UNVERIFIED + parser warnings)

The §6 Grounded Synthesis Contract in `05-generate-doc.mdc` is enforced:

  §1 / §2 / §3 prose IS synthesized, but every clause must trace to a concept
  in concepts.json, a formula in formulas.json, an upstream wiki cell, or a
  UC system-table fact. There is no AI-only inference and no UC live-comment
  harvesting.

  §4 Elements descriptions are deterministic — each row falls into exactly
  ONE of three buckets:

    (A) Byte-equal to upstream wiki — passthrough/rename/cast against upstream
        whose Phase 3 routing landed at Rules 1-5.
    (B) Formula-assembled — {concept-meaning if column in a concept, else
        short gloss}. {formula from formulas.json}. (Tier 2 — {inputs})
    (C) Null-with-provenance template — passthrough/rename/cast against an
        upstream whose Phase 3 routing landed at Rule 6 AND that upstream is a
        terminal root in the lineage DAG (no further parent in column_lineage).

  Anything that fails to classify becomes an UNVERIFIED row in the sidecar — NEVER
  an AI-inferred description. This is enforced again by `validate_pipeline_wiki.py`
  at Phase 6 gate.

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
TIER_TAG_RE = re.compile(r"\(Tier\s+([1-5UN][a-z]?)\s+[—–-]\s+([^\)]+)\)")


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
    """Heuristic: locate the line(s) in the source code that define `target_column`
    as a projected SELECT-list item. Returns (start_line, end_line, snippet) or None.

    Detects three patterns, in priority order:
      1. Explicit `AS <colname>` (case-insensitive, optional backticks).
      2. Bare implicit alias — `<qualifier>.<colname>` or just `<colname>` —
         appearing as the last token before `,` or end-of-line on a line that
         is part of a SELECT projection (i.e. not a WHERE / JOIN / GROUP BY line).
      3. Multi-line CASE/COALESCE expressions ending in `AS <colname>`.

    The snippet returned is ONLY the column's own SELECT-list item — bounded
    backward by either the previous item's trailing `,` or by the `SELECT`
    keyword, and forward by the column's own trailing `,`/`AS` line. We never
    grab earlier columns.
    """
    if not source_code:
        return None
    lines = source_code.splitlines()
    n = len(lines)
    target = target_column
    target_low = target.lower()

    # Disqualifiers — lines that look like clauses, not projection items.
    # NOTE: LEFT / RIGHT / FULL / INNER / OUTER / CROSS are AMBIGUOUS — they can
    # be JOIN modifiers (clause) OR string functions (projection: `LEFT(x, 4)`).
    # We require them to be followed by whitespace + JOIN (or directly the word
    # JOIN-ish), otherwise we treat the line as a projection.
    clause_re = re.compile(
        r"^\s*("
        r"FROM\b|WHERE\b|JOIN\b|ON\b|GROUP\s+BY\b|ORDER\s+BY\b|HAVING\b|"
        r"UNION\b|INTERSECT\b|EXCEPT\b|WITH\b|--|/\*|\*/|\)\s*$|"
        r"(?:LEFT|RIGHT|INNER|OUTER|CROSS|FULL)\s+(?:OUTER\s+)?JOIN\b"
        r")",
        re.IGNORECASE,
    )

    def is_projection_line(idx: int) -> bool:
        ln = lines[idx]
        return not clause_re.match(ln)

    # Pass 1: explicit "AS <colname>" — both quoted-backtick and bare.
    as_pat = re.compile(rf"\bAS\s+`?{re.escape(target)}`?\s*(?:,|$)", re.IGNORECASE)
    candidates: list[int] = []
    for i, ln in enumerate(lines):
        if as_pat.search(ln) and is_projection_line(i):
            candidates.append(i)

    # Pass 2: bare implicit alias — `<qualifier>.<colname>` or bare `<colname>`
    # at end-of-projection-line (followed by `,` or line-end). Strict: rejects
    # the column when it's used inside a WHERE/JOIN/GROUP-BY (filtered by
    # is_projection_line) and rejects function calls like `SUM(<colname>)` by
    # requiring the next non-whitespace char to be `,` or EOL.
    if not candidates:
        bare_pat = re.compile(
            rf"(?:\.|^|\s|\()`?{re.escape(target)}`?\s*(?:,|$)",
            re.IGNORECASE,
        )
        for i, ln in enumerate(lines):
            if not is_projection_line(i):
                continue
            # Drop trailing inline comments before matching.
            ln_stripped = re.sub(r"--.*$", "", ln).rstrip()
            if not ln_stripped.endswith((",", target, f"`{target}`")) and \
               not re.search(rf"\b{re.escape(target)}\b\s*$", ln_stripped, re.IGNORECASE):
                continue
            if bare_pat.search(ln_stripped):
                candidates.append(i)

    # Pass 3: multi-line expression ending with `... AS <colname>` on a later line.
    # Already covered by Pass 1, but explicit fallback for CASE-WHEN-END blocks
    # where `AS <colname>` is on the END line.
    if not candidates:
        for i, ln in enumerate(lines):
            if re.search(rf"\bEND\s+AS\s+`?{re.escape(target)}`?", ln, re.IGNORECASE) and is_projection_line(i):
                candidates.append(i)

    if not candidates:
        return None
    end_idx = candidates[0]

    # Walk backward to find the start of THIS projection item — bounded by
    # either the previous line ending in `,` (previous item's terminator) or
    # the SELECT keyword. Cap the walk at 30 lines to avoid runaway.
    start_idx = end_idx
    for j in range(end_idx - 1, max(-1, end_idx - 30), -1):
        prev = lines[j].rstrip()
        if prev.endswith(","):
            # The previous item ended here; THIS item starts on j+1.
            start_idx = j + 1
            break
        if re.match(r"^\s*SELECT(\s|$)", prev, re.IGNORECASE):
            start_idx = j + 1
            break
        # If we hit a CTE header, FROM, or open paren, stop and treat the
        # next line as the start.
        if re.match(r"^\s*(WITH|FROM|\(|\))", prev, re.IGNORECASE):
            start_idx = j + 1
            break
        start_idx = j

    if start_idx > end_idx:
        start_idx = end_idx

    snippet = "\n".join(lines[start_idx:end_idx + 1]).strip()
    # Strip trailing comma from the last line for cleaner output.
    if snippet.endswith(","):
        snippet = snippet[:-1]
    if len(snippet) > 200:
        snippet = snippet[:200] + "…"
    return (start_idx + 1, end_idx + 1, snippet)


# ---------------------------------------------------------------------------
# Alias-to-upstream resolution
# ---------------------------------------------------------------------------
# When we narrate a column's expression like
#   `CASE WHEN mfts.TxTypeID IN (5) THEN 33 ELSE 0 END AS FundingTypeID`
# the alias `mfts` is locally meaningful but useless to a wiki reader unless
# we resolve it to the physical UC table it points at. These helpers parse
# the cached view DDL / notebook SQL into CTE-scoped FROM/JOIN alias maps,
# then walk those maps (recursing through CTE references) to produce the
# list of terminal physical UC FQNs that the cited expression actually reads.

_CTE_HEADER_RE = re.compile(
    # First CTE prefix: `WITH <name> AS (` requires a word boundary before WITH.
    # Subsequent CTEs prefix: `, <name> AS (` — `,` is always its own boundary;
    # `\b,` would FAIL when `,` immediately follows `)` (two non-word chars,
    # no boundary between them), so we use plain `,` without `\b`.
    r"(?:\bWITH\s+|,\s*)([A-Za-z_][A-Za-z0-9_]*)\s+AS\s*\(",
    re.IGNORECASE,
)

_FROM_JOIN_RE = re.compile(
    r"\b(?:FROM|JOIN)\s+"
    r"(?P<src>[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*)"
    r"(?:\s+(?:AS\s+)?(?P<alias>[A-Za-z_][A-Za-z0-9_]*))?",
    re.IGNORECASE,
)

_ALIAS_STOPWORDS = frozenset({
    "ON", "WHERE", "GROUP", "ORDER", "HAVING", "LEFT", "RIGHT", "INNER",
    "OUTER", "JOIN", "CROSS", "FULL", "AS", "AND", "OR", "UNION", "INTERSECT",
    "EXCEPT", "WITH", "SELECT", "DISTINCT", "LIMIT", "OFFSET", "QUALIFY",
})

# SQL keywords / built-in functions / type names that look like identifiers
# but are NOT column references. Used by `_snippet_has_column_refs` to
# distinguish `COALESCE(TransactionID, -1)` (has a column ref → resolve) from
# `CURRENT_TIMESTAMP()` or `0` (no column refs → pure literal, no upstream).
_SQL_NONCOLUMN_TOKENS = frozenset({
    "AS", "CASE", "WHEN", "THEN", "ELSE", "END", "IS", "NULL", "NOT", "IN",
    "AND", "OR", "BETWEEN", "LIKE", "TRUE", "FALSE",
    "COALESCE", "IFNULL", "NVL", "ISNULL", "NULLIF",
    "CAST", "CONVERT", "TRY_CAST",
    "CURRENT_TIMESTAMP", "CURRENT_DATE", "CURRENT_USER", "NOW", "GETDATE", "SYSDATE",
    "LEFT", "RIGHT", "SUBSTRING", "SUBSTR", "CONCAT", "TRIM", "LTRIM", "RTRIM",
    "LOWER", "UPPER", "LEN", "LENGTH", "REPLACE", "CHARINDEX", "STUFF",
    "YEAR", "MONTH", "DAY", "DATEDIFF", "DATEADD", "DATEPART", "DATE_ADD",
    "DATE_SUB", "FROM_UNIXTIME", "UNIX_TIMESTAMP",
    "ROUND", "FLOOR", "CEILING", "CEIL", "ABS", "POWER", "SQRT", "MOD",
    "SUM", "COUNT", "AVG", "MIN", "MAX", "OVER", "PARTITION", "BY",
    "ROW_NUMBER", "RANK", "DENSE_RANK", "LAG", "LEAD", "FIRST_VALUE", "LAST_VALUE",
    "DATE", "TIMESTAMP", "INT", "BIGINT", "SMALLINT", "TINYINT",
    "DECIMAL", "NUMERIC", "VARCHAR", "STRING", "FLOAT", "DOUBLE", "BOOLEAN",
    "DISTINCT", "INTERVAL", "SECOND", "MINUTE", "HOUR", "WEEK",
    "DESC", "ASC",
})


def _snippet_has_column_refs(snippet: str) -> bool:
    """Return True if `snippet` contains identifier-shaped tokens that look
    like bare column references (not SQL keywords/functions/literals).

    A pure literal expression like `0 AS IsRecurring`, `'Deposit' AS X`, or
    `CURRENT_TIMESTAMP() AS Y` has no column refs and shouldn't trigger
    upstream attribution. An expression like `COALESCE(TransactionID, -1) AS X`
    DOES reference a column (`TransactionID`) — the bare-ref fallback should
    activate.

    Heuristic: strip the trailing `AS <alias>` binding, then look for
    identifier tokens NOT followed by `(` (which would mark them as function
    calls) and NOT in the SQL keyword set.
    """
    # Strip trailing `AS <alias>` so we don't count the bound name itself.
    expr = re.sub(r"\s+AS\s+[A-Za-z_]\w*\s*$", "", snippet, flags=re.IGNORECASE).strip()
    for m in re.finditer(r"\b([A-Za-z_][A-Za-z0-9_]*)\b(?!\s*\()", expr):
        tok = m.group(1).upper()
        if tok not in _SQL_NONCOLUMN_TOKENS:
            return True
    return False


def _strip_sql_comments_and_strings(source_code: str) -> str:
    """Return a copy of `source_code` with line comments (`--…\\n`), block
    comments (`/* … */`), and single-quoted string literal CONTENTS replaced
    by spaces. Newlines are preserved so line numbers stay aligned with the
    original. Quote chars themselves are kept so SQL tokenizers see balanced
    quotes; the contents are blanked. Parenthesis depth-counting and FROM/JOIN
    regex matching downstream both depend on this — comments and string
    literals are the two places where stray `(`/`)` and the word `from` show
    up without being real SQL.
    """
    out = list(source_code)
    i = 0
    n = len(source_code)
    while i < n:
        c = source_code[i]
        if c == '-' and i + 1 < n and source_code[i + 1] == '-':
            while i < n and source_code[i] != '\n':
                out[i] = ' '
                i += 1
        elif c == '/' and i + 1 < n and source_code[i + 1] == '*':
            out[i] = ' '; out[i + 1] = ' '
            i += 2
            while i + 1 < n and not (source_code[i] == '*' and source_code[i + 1] == '/'):
                if source_code[i] != '\n':
                    out[i] = ' '
                i += 1
            if i + 1 < n:
                out[i] = ' '; out[i + 1] = ' '
                i += 2
        elif c == "'":
            i += 1  # keep the opening quote
            while i < n and source_code[i] != "'":
                if source_code[i] != '\n':
                    out[i] = ' '
                # handle doubled single-quote escapes ('' → literal ')
                if source_code[i] == '\\' and i + 1 < n:
                    out[i + 1] = ' '
                    i += 2
                    continue
                i += 1
            if i < n:
                i += 1  # consume the closing quote
        else:
            i += 1
    return ''.join(out)


def _alias_map_for_body(body: str) -> dict[str, str]:
    """Extract every `FROM/JOIN <src> [AS] <alias>` binding in a SQL body.

    `<src>` may be a fully-qualified physical name (`main.bi_db.foo`) or a
    bare CTE name (`ftd_iban`). When the FROM/JOIN omits an alias, we use the
    last segment of `<src>` as the implicit alias so unaliased references can
    still be resolved.
    """
    result: dict[str, str] = {}
    for m in _FROM_JOIN_RE.finditer(body):
        src = m.group("src")
        alias = m.group("alias")
        # When the regex captured a stopword as the "alias" (e.g. UNION /
        # WHERE / ON / GROUP from `FROM x.y UNION ALL`), discard the capture
        # and fall back to the implicit alias = last segment of `src`. This
        # is what real SQL parsing does — an alias must not be a reserved
        # word, so a stopword there means there was no alias at all.
        if alias and alias.upper() in _ALIAS_STOPWORDS:
            alias = None
        if not alias:
            alias = src.rsplit(".", 1)[-1]
        if alias.upper() in _ALIAS_STOPWORDS:
            continue
        if alias not in result:
            result[alias] = src
    return result


def _parse_scopes(source_code: str) -> tuple[dict[str, dict[str, str]], list[tuple[str, int, int]]]:
    """Parse `source_code` into CTE-scoped alias maps + a `main` scope.

    Returns:
        scopes: dict[scope_name, alias_map]   ('main' is the outer SELECT)
        cte_ranges: list of (cte_name, body_char_start, body_char_end) for
                    determining which scope a given source line is inside.
    """
    if not source_code:
        return {}, []
    # Strip comments + string literal contents BEFORE parsing so depth
    # counting and FROM/JOIN matching aren't fooled by stray parens or the
    # word "from" inside comments / string literals. Original source is
    # preserved by the caller for snippet citation.
    sanitized = _strip_sql_comments_and_strings(source_code)
    cte_ranges: list[tuple[str, int, int]] = []
    for m in _CTE_HEADER_RE.finditer(sanitized):
        body_start = m.end()  # right after the open paren
        depth = 1
        i = body_start
        while i < len(sanitized) and depth > 0:
            c = sanitized[i]
            if c == '(':
                depth += 1
            elif c == ')':
                depth -= 1
                if depth == 0:
                    cte_ranges.append((m.group(1), body_start, i))
                    break
            i += 1
    scopes: dict[str, dict[str, str]] = {}
    for name, start, end in cte_ranges:
        scopes[name] = _alias_map_for_body(sanitized[start:end])
    masked = list(sanitized)
    for _, start, end in cte_ranges:
        for i in range(start, end + 1):
            masked[i] = ' '
    scopes['main'] = _alias_map_for_body(''.join(masked))
    return scopes, cte_ranges


def _scope_for_line(line_num: int, source_code: str, cte_ranges: list[tuple[str, int, int]]) -> str:
    """1-indexed `line_num` → enclosing scope name ('main' or a CTE name)."""
    if not source_code or not cte_ranges:
        return 'main'
    lines = source_code.splitlines(keepends=True)
    if line_num <= 0 or line_num > len(lines):
        return 'main'
    offset = sum(len(l) for l in lines[:line_num - 1])
    line_end_offset = offset + len(lines[line_num - 1])
    for name, start, end in cte_ranges:
        if start <= offset and line_end_offset <= end + 1:
            return name
    return 'main'


def _resolve_terminal_upstreams(snippet: str, scope: str,
                                  scopes: dict[str, dict[str, str]]) -> list[str]:
    """Given an SQL snippet and its enclosing scope, return the deduplicated
    list of TERMINAL physical UC FQNs (i.e. non-CTE sources) reached by the
    aliases used in the snippet.

    Aliases pointing at a CTE are recursively expanded into the CTE's own
    physical sources; CTE→CTE chains are walked with cycle protection. If a
    chain dead-ends without ever hitting a physical FQN, the CTE name is
    returned as a fallback so the reader has something to anchor on.
    """
    if not scopes:
        return []
    snippet_aliases = set()
    for m in re.finditer(r"\b([A-Za-z_][A-Za-z0-9_]*)\.", snippet):
        snippet_aliases.add(m.group(1))
    # Bare-column-ref fallback: if the snippet uses no alias prefix at all
    # (typical of CTE-passthrough rows like `RealCID,` or
    # `COALESCE(TransactionID, -1)`) AND it actually references a column
    # (not just literals/functions), AND the enclosing scope reads from
    # exactly ONE source AND that source is a PHYSICAL table (not a CTE),
    # attribute the bare refs to that single source.
    #
    # Why these gates:
    #   - Multi-source scopes → ambiguous, don't guess.
    #   - Pure literals (`0`, `'x'`, `CURRENT_TIMESTAMP()`) → no column refs,
    #     genuinely have no upstream, label them `literal` later.
    #   - Lone source is a CTE → walking the CTE chain would over-attribute
    #     to every physical table reachable, even ones that don't contribute
    #     this column. Honest answer is "computed in source" — the reader
    #     can scroll up to see the CTE definition.
    def is_physical(src: str) -> bool:
        # A name with at least one dot AND not registered as a CTE is treated
        # as physical (UC FQN-style).
        return ('.' in src) and (src not in scopes)

    if not snippet_aliases:
        scope_map = scopes.get(scope, {})
        if (len(scope_map) == 1
                and _snippet_has_column_refs(snippet)):
            lone_alias, lone_src = next(iter(scope_map.items()))
            if is_physical(lone_src):
                snippet_aliases.add(lone_alias)

    def expand(alias: str, current_scope: str, seen: set[str]) -> list[str]:
        amap = scopes.get(current_scope, {})
        src = amap.get(alias)
        if not src:
            return []
        if is_physical(src):
            return [src]
        # `src` is a CTE name — recurse into its alias map and return ALL
        # physical sources reachable from it.
        if src in seen:
            return [src]  # cycle protection — surface the CTE name
        seen = seen | {src}
        cte_map = scopes.get(src, {})
        out: list[str] = []
        for sub_alias, sub_src in cte_map.items():
            if is_physical(sub_src):
                out.append(sub_src)
            else:
                out.extend(expand(sub_alias, src, seen))
        return out or [src]

    resolved: list[str] = []
    for alias in snippet_aliases:
        for fqn in expand(alias, scope, set()):
            if fqn not in resolved:
                resolved.append(fqn)
    return resolved


def _operators_in(snippet: str) -> list[str]:
    found: list[str] = []
    su = snippet.upper()
    for op in SQL_OPERATORS_OF_INTEREST:
        if op in su and op not in found:
            found.append(op)
    return found[:6]


def _narrate_from_source_code(target_column: str, source_code: str,
                                source_object: str, source_path_rel: str,
                                writer_kind: str,
                                scopes: dict[str, dict[str, str]] | None = None,
                                cte_ranges: list[tuple[str, int, int]] | None = None,
                                ) -> str | None:
    """Bucket (B): Narration anchored to a source-code line range, with the
    column's aliased upstream references resolved to physical UC FQNs.

    Returns a description of the form:
        `<quoted SQL expression>` (Tier 2 — from `<fqn1>`[, `<fqn2>`, ...])
    or, for pure literal/computed expressions with no aliased column refs:
        `<quoted SQL expression>` (Tier 2)

    The expression itself is the documentation. Verbose preambles
    ("Computed in source (CASE, WHEN): ..."), long file paths, and redundant
    `[uc_view_ddl]` citation tags are NOISE. The `from <fqn>` suffix is the
    one piece of resolution work the source can't show on its own — local
    aliases like `mfts` get mapped back to the actual table they reference
    (recursing through CTEs to land on physical UC objects).
    """
    if not source_code:
        return None
    loc = _find_column_expression_lines(source_code, target_column)
    if not loc:
        return None
    start_line, end_line, snippet = loc
    snippet_inline = snippet.replace("\n", " ").strip()
    snippet_inline = re.sub(r"\s+", " ", snippet_inline)
    if len(snippet_inline) > 200:
        snippet_inline = snippet_inline[:200] + "…"

    # Resolve aliased column refs → physical upstream UC FQNs.
    if scopes is None or cte_ranges is None:
        scopes, cte_ranges = _parse_scopes(source_code)
    scope = _scope_for_line(end_line, source_code, cte_ranges)
    upstreams = _resolve_terminal_upstreams(snippet, scope, scopes)

    if upstreams:
        upstreams_fmt = ", ".join(f"`{u}`" for u in upstreams)
        return f"`{snippet_inline}` (Tier 2 — from {upstreams_fmt})"
    # No aliased upstreams resolvable from the snippet itself. This happens for:
    #   - Pure literals: `'Deposit' AS MIMOAction` — origin is the source itself.
    #   - Bare unqualified column refs: `COALESCE(TransactionID, -1) AS X` — the
    #     `TransactionID` here is a column already projected upward through a CTE,
    #     not an alias.tablecol reference we can resolve. Honest tag = computed.
    stripped = snippet_inline.lstrip()
    is_literal = stripped.startswith(("'", '"')) or (stripped and stripped[0].isdigit())
    origin = "literal" if is_literal else "computed in source"
    return f"`{snippet_inline}` (Tier 2 — {origin})"


def _null_with_provenance(upstream_fqn: str, source_column: str, check_date: str) -> str:
    return f"Source: {upstream_fqn}.{source_column}. No upstream wiki cached as of {check_date}."


def _ensure_tier_tag(desc: str, fallback_tier: str, fallback_origin: str) -> str:
    if TIER_TAG_RE.search(desc):
        return desc
    return f"{desc.rstrip().rstrip('.')} (Tier {fallback_tier} — {fallback_origin})."


def _build_formula_backed_description(
    column_name: str,
    formula_entry: dict | None,
    concepts_for_col: list[dict],
) -> str | None:
    """Bucket (B) for §4 Elements: assemble Tier-2 description from formulas.json
    + matching concepts. Returns None if formula_entry is missing/null so the
    caller can fall back to the older snippet narrator.

    Output shape:
        {concept business name OR short gloss}. Formula: `{formula}`. (Tier 2 — {inputs})

    The concept business name is preferred when a concept references this
    column (e.g. "IBAN-originated internal transfer discriminator"). Otherwise
    a short gloss is emitted from the transform_kind ("Pure literal", "CASE
    flag computed in source", etc.).
    """
    if not formula_entry or not formula_entry.get("formula"):
        return None
    formula = formula_entry["formula"]
    inputs = formula_entry.get("inputs") or []
    kind = formula_entry.get("transform_kind") or "unknown"

    # Concept-driven business name takes priority. Only certain concept kinds
    # describe a SINGLE COLUMN's meaning. Structural concepts like
    # union_leg_sign_flip and dim_lookup describe SHAPE, not column meaning —
    # they belong in §2 (their own subsection) and §3 (query advisory), NOT
    # in the column's §4 description.
    PER_COLUMN_CONCEPT_KINDS = {"case_flag", "pair_group"}
    concept = None
    for c in concepts_for_col:
        if c.get("kind") not in PER_COLUMN_CONCEPT_KINDS:
            continue
        if column_name in (c.get("columns_involved") or []):
            concept = c
            break
    if concept:
        # Use rich named description; the formula goes in as evidence.
        name = _concept_business_name(concept, {})
        prose = name.rstrip(".") + "."
    else:
        # Fallback gloss by transform_kind.
        gloss_map = {
            "passthrough": "Direct passthrough from upstream.",
            "rename": "Renamed passthrough from upstream.",
            "cast": "Cast of upstream column.",
            "case_flag": "Computed flag (CASE expression in source).",
            "coalesce": "COALESCE / null-replacement of upstream values.",
            "arithmetic": "Arithmetic combination of upstream columns.",
            "aggregate": "Aggregate over upstream rows.",
            "window": "Window function over upstream rows.",
            "literal": "Literal constant set in this object.",
            "function": "Function call computed in source.",
            "unknown": "Computed in source (transform kind not classified).",
        }
        prose = gloss_map.get(kind, "Computed in source.")

    # Format inputs: 'literal' / 'computed in source' / list of FQNs.
    if not inputs or inputs == ["literal"]:
        origin = "literal"
    elif inputs == ["computed in source"]:
        origin = "computed in source"
    else:
        origin = "from " + ", ".join(f"`{i}`" for i in inputs[:3])
        if len(inputs) > 3:
            origin += f" (+{len(inputs) - 3} more)"

    formula_clause = f" Formula: `{formula}`." if formula else ""
    return f"{prose}{formula_clause} (Tier 2 — {origin})"


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


def _build_property_table_v8(obj_name: str, inv_obj: dict, schema: str,
                              concept_count: int, downstream: list[str]) -> str:
    """8-section golden property table — adds Concepts + Downstream rows."""
    rows = [
        ("UC Object", f"`main.{schema}.{obj_name}`"),
        ("Type", inv_obj.get("table_type") or "—"),
        ("Format", inv_obj.get("data_source_format") or "n/a"),
        ("Owner", inv_obj.get("owner") or "—"),
        ("Row count", str(inv_obj.get("row_count") or "n/a")),
        ("Column count", str(inv_obj.get("column_count") or len(inv_obj.get("columns") or []))),
        ("Concepts", f"{concept_count} (see §2)"),
        ("Downstream consumers", f"{len(downstream)} (see §6.2)" if downstream else "_(none tracked)_"),
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
                    mismatches: int, *, section_prefix: str = "5") -> str:
    """Build the lineage section. Numbered with `section_prefix` so it can
    serve as §4 (legacy 6-section golden) or §5 (8-section golden).
    """
    out: list[str] = []
    out.append(f"### {section_prefix}.1 Upstream UC Objects\n")
    out.append("| Upstream | Role | Wiki |")
    out.append("|----------|------|------|")
    for u in upstreams:
        role = u.get("role") or "Upstream"
        wiki = u.get("wiki_path") or "(no wiki — see `.review-needed.md`)"
        out.append(f"| `{u['full_name']}` | {role} | `{wiki}` |")
    out.append(f"\n### {section_prefix}.2 Pipeline ASCII Diagram\n")
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
    out.append(f"### {section_prefix}.3 Cross-check vs system.access.column_lineage\n")
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


def read_concepts(schema_root: Path, obj_name: str) -> dict:
    """Phase 4.5 artifact. Returns {object_fqn, concepts: [...], concept_count}."""
    p = schema_root / "_discovery" / "concepts" / f"{obj_name}.json"
    if not p.exists():
        return {"object_fqn": None, "concepts": [], "concept_count": 0}
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"[generate-wiki] WARN: concepts load failed for {obj_name}: {e}",
              file=sys.stderr)
        return {"object_fqn": None, "concepts": [], "concept_count": 0}


def read_formulas(schema_root: Path, obj_name: str) -> dict:
    """Phase 4.6 artifact. Returns {object_fqn, formulas: [...], formula_count}."""
    p = schema_root / "_discovery" / "formulas" / f"{obj_name}.json"
    if not p.exists():
        return {"object_fqn": None, "formulas": [], "formula_count": 0}
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"[generate-wiki] WARN: formulas load failed for {obj_name}: {e}",
              file=sys.stderr)
        return {"object_fqn": None, "formulas": [], "formula_count": 0}


def read_reviewer_corrections(sidecar_path: Path) -> dict[str, str]:
    """Parse the `## Reviewer Corrections` table from a `.review-needed.md` sidecar.

    Each row becomes a Tier 5 override that supersedes every other tier
    (matches the DWH semantic-doc framework, see
    `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` Rule 15).

    Expected sidecar table shape (header row may vary; we key on the first
    column being the column name in backticks):

        ## Reviewer Corrections
        | Column | Correction | ... |
        |--------|------------|-----|
        | `MyCol` | The real definition. | ... |

    Returns: {column_name_lower: correction_text}. Empty dict if the sidecar
    is missing, has no Reviewer Corrections section, or the table is empty.
    """
    if not sidecar_path.exists():
        return {}
    try:
        text = sidecar_path.read_text(encoding="utf-8")
    except Exception:
        return {}
    # Pull the Reviewer Corrections section text up to the next ## header.
    m = re.search(r"##\s+Reviewer\s+Corrections\s*\n(.*?)(?=\n##\s|\Z)",
                  text, re.DOTALL | re.IGNORECASE)
    if not m:
        return {}
    block = m.group(1)
    out: dict[str, str] = {}
    for line in block.splitlines():
        line = line.strip()
        if not line.startswith("|"):
            continue
        # Skip header / separator rows.
        if re.match(r"^\|\s*[-:|\s]+\|", line):
            continue
        if line.lower().startswith("| column") or "correction" in line.lower()[:30] and "current" not in line.lower()[:30]:
            # Heuristic: if the first cell text is the literal word "Column"
            # (header) skip. Otherwise treat as data.
            if "`" not in line.split("|", 2)[1]:
                continue
        cells = [c.strip() for c in line.split("|")[1:-1]]
        if len(cells) < 2:
            continue
        col_cell = cells[0]
        cm = re.search(r"`([^`]+)`", col_cell)
        if not cm:
            continue
        col_name = cm.group(1).strip()
        correction = cells[1].strip()
        if not correction or correction == "—":
            continue
        out[col_name.lower()] = correction
    return out


# ---------------------------------------------------------------------------
# 8-section composition (§1/§2/§3 grounded-synthesis from concepts + formulas)
# ---------------------------------------------------------------------------

def _format_predicate(p: dict, decodes: dict[str, str]) -> str:
    """Format one predicate as a Rule bullet, decoding upstream enums where present."""
    col = p["col"]
    op = p["op"]
    val = p["val"]
    base = f"`{col} {op} {val}`"
    decode_key = f"{col}={val.strip('()')}"
    if decode_key in decodes:
        return f"{base} ({decodes[decode_key]} per upstream wiki)"
    # IN list: try per-value decode
    if val.strip().startswith("(") and decodes:
        nums = re.findall(r"-?\d+", val)
        per = [f"{n}={decodes[f'{col}={n}']}" for n in nums if f"{col}={n}" in decodes]
        if per:
            return f"{base} ({', '.join(per)} per upstream wiki)"
    return base


def _concept_business_name(concept: dict, columns_involved_lookup: dict[str, dict]) -> str:
    """Produce a richer human-readable concept name from the structured fields."""
    kind = concept.get("kind", "")
    cols = concept.get("columns_involved", [])
    if kind == "case_flag" and cols:
        # Pull predicates: e.g. "IsInternalTransfer = 1 when TxTypeID=5 (TransferReceived)"
        preds = concept.get("predicates", [])
        decodes = concept.get("upstream_enum_decodes", {})
        col = cols[0]
        if preds:
            sig = ", ".join(_format_predicate(p, decodes) for p in preds[:3])
            then_v = concept.get("then_value")
            else_v = concept.get("else_value")
            then_clause = f" → set to {then_v}" if then_v else ""
            else_clause = f" else {else_v}" if else_v else ""
            return f"`{col}` discriminator: {sig}{then_clause}{else_clause}"
        return f"`{col}` computed flag"
    if kind == "union_leg_sign_flip":
        return f"Sign-flip leg `{concept.get('scope', '')}` (multiplies {', '.join('`'+c+'`' for c in cols[:3])} by -1)"
    if kind == "dim_lookup":
        dim = (concept.get("dim_fqn") or "").rsplit(".", 1)[-1]
        return f"Dim lookup via alias `{concept.get('alias', '')}` → `{dim}`"
    if kind == "filter_block":
        preds = concept.get("predicates", [])
        if preds:
            scope = concept.get("scope", "?")
            sig = "; ".join(f"`{p['col']} {p['op']} {p['val']}`" for p in preds[:3])
            return f"Filter on scope `{scope}`: {sig}"
        return f"Filter block on `{concept.get('scope', '?')}`"
    if kind == "pair_group":
        return concept.get("name") or "Column-name pair group"
    return concept.get("name") or f"{kind} concept"


def _build_section1_v8(obj_name: str, schema: str, kind_label: str,  # noqa: ARG001
                        upstreams: list[str], concepts: list[dict],
                        inv_obj: dict, primary_upstream_wiki: str | None,
                        n_pass: int, n_narr: int, n_null: int) -> str:
    """§1 Business Meaning — 3 paragraphs anchored to concepts.json + lineage.

    Paragraph 1 — WHAT (concept summary). If concepts exist, name them.
    Paragraph 2 — WHERE (lineage chain + upstream wiki pointer).
    Paragraph 3 — HOW (writer kind + tier-distribution summary).
    """
    # Para 1: WHAT
    concept_kinds = [c.get("kind") for c in concepts]
    has_case = "case_flag" in concept_kinds
    has_signflip = "union_leg_sign_flip" in concept_kinds
    has_dim = "dim_lookup" in concept_kinds
    has_filter = "filter_block" in concept_kinds
    concept_phrases: list[str] = []
    if has_signflip:
        concept_phrases.append("a UNION ALL with sign-flipped amount legs (deposit/withdraw composition)")
    if has_case:
        n_case = sum(1 for k in concept_kinds if k == "case_flag")
        concept_phrases.append(f"{n_case} CASE-based classifier flag(s) computed from upstream IDs")
    if has_dim:
        n_dim = sum(1 for k in concept_kinds if k == "dim_lookup")
        concept_phrases.append(f"{n_dim} JOIN-enriched dimension lookup(s)")
    if has_filter:
        n_filter = sum(1 for k in concept_kinds if k == "filter_block")
        concept_phrases.append(f"{n_filter} top-level filter block(s) (settled / status / dedup discriminators)")

    if concept_phrases:
        para1 = (
            f"`{obj_name}` is a {kind_label} in `main.{schema}` that composes "
            + ", ".join(concept_phrases[:3])
            + (f", plus {len(concept_phrases) - 3} additional concept(s) (see §2)"
                if len(concept_phrases) > 3 else "")
            + "."
        )
    else:
        para1 = (
            f"`{obj_name}` is a {kind_label} in `main.{schema}`. "
            "No discriminator concepts were detected in the source — see §2 for "
            "the transform pattern breakdown."
        )

    # Para 2: WHERE (lineage)
    if upstreams:
        primary = upstreams[0]
        wiki_clause = (f" Canonical upstream documentation: `{primary_upstream_wiki}`."
                        if primary_upstream_wiki else
                        " The primary upstream has no cached wiki yet "
                        "(see `.review-needed.md`).")
        if len(upstreams) > 1:
            extras = (f" Additional upstreams: {len(upstreams) - 1} object(s), "
                      "listed in §5 Lineage.")
        else:
            extras = ""
        para2 = (
            f"Production-to-UC lineage flows: production source → bronze/staging "
            f"→ gold mirror `{primary}` → this object.{wiki_clause}{extras}"
        )
    else:
        para2 = (
            "No upstream UC objects tracked in lineage — this object's source "
            "code may not have been parsed yet, or it reads from external paths. "
            "See `.lineage.md`."
        )

    # Para 3: HOW (writer + tier distribution)
    total = n_pass + n_narr + n_null
    para3 = (
        f"Of its {inv_obj.get('column_count') or len(inv_obj.get('columns') or [])} "
        f"columns: {n_pass} inherit byte-for-byte from upstream wikis (Tier 1), "
        f"{n_narr} are formula-assembled from cached source code (Tier 2 — see §4 "
        f"for the formula and §2 for the named concept), {n_null} are "
        f"null-with-provenance (Tier N — terminal-no-wiki upstream)."
    )

    return f"{para1}\n\n{para2}\n\n{para3}"


def _build_section2_v8(concepts: list[dict], lineage_rows: list[dict],
                        source_path_rel: str) -> str:
    """§2 Business Logic — one ### 2.N per concept. Pure-passthrough collapse
    to a single sentence when no concepts."""
    if not concepts:
        return ("Pure passthrough — no discriminator concepts detected in source. "
                "Refer to upstream wiki for column semantics; this object adds no "
                "transformation logic beyond column selection.")

    # Group similar concepts so we don't emit 8 identical subsections for 4
    # CASE-flag columns. Group by (kind, sorted columns_involved tuple).
    cols_by_concept = {c["id"]: c for c in concepts}
    out: list[str] = []

    # Build columns_involved lookup from lineage for human-readable names.
    columns_lookup = {r["name"].lower(): r for r in lineage_rows}

    for i, concept in enumerate(concepts, 1):
        name = _concept_business_name(concept, columns_lookup)
        kind = concept.get("kind", "")
        cols = concept.get("columns_involved", [])
        preds = concept.get("predicates", [])
        decodes = concept.get("upstream_enum_decodes", {})
        scope = concept.get("scope") or ""
        evidence = concept.get("evidence_lines") or ""
        inputs = concept.get("physical_inputs") or []

        # What sentence: tailor to concept kind
        if kind == "case_flag":
            then_v = concept.get("then_value")
            else_v = concept.get("else_value")
            what = (f"Computed flag on `{cols[0] if cols else '?'}` set to "
                    f"`{then_v}` when the predicates below hold, else `{else_v}`.")
        elif kind == "union_leg_sign_flip":
            what = (f"This subselect contributes the negative-sign leg of a "
                    f"UNION ALL composition — amount columns are multiplied by "
                    f"-1 so the downstream rollup nets to (deposit - withdraw).")
        elif kind == "dim_lookup":
            dim = (concept.get("dim_fqn") or "").rsplit(".", 1)[-1]
            what = (f"`JOIN` to dimension `{dim}` enriches every base row "
                    f"with attributes drawn from that dim. The base side "
                    f"is the FROM-clause object; this side contributes "
                    f"lookups only.")
        elif kind == "filter_block":
            what = (f"`WHERE` clause at the top of scope `{scope}` — every "
                    f"row in this scope must satisfy these predicates. "
                    f"Predicates apply unconditionally to all downstream "
                    f"projections from this scope.")
        elif kind == "pair_group":
            what = (f"Column-name pattern group ({concept.get('pattern', '')}): "
                    f"these columns work together as a unit. Treat them "
                    f"together when filtering or aggregating.")
        else:
            what = concept.get("name") or "Concept."

        # Columns Involved
        cols_str = ", ".join(f"`{c}`" for c in cols) if cols else "(none)"
        # Rules
        rule_lines: list[str] = []
        for p in preds:
            rule_lines.append(f"- {_format_predicate(p, decodes)}")
        if kind == "union_leg_sign_flip":
            for expr in concept.get("expressions", [])[:5]:
                rule_lines.append(f"- `-1 * {expr}` (sign-flip on amount)")
        if kind == "dim_lookup" and concept.get("join_condition"):
            jc = concept.get("join_condition", "")[:200].replace("\n", " ")
            rule_lines.append(f"- ON `{jc}`")
        if not rule_lines:
            rule_lines.append("- (no explicit predicates / pattern-only concept)")
        rules_str = "\n".join(rule_lines)

        # Inputs
        inputs_str = ""
        if inputs:
            inputs_str = "\n**Source(s)**: " + ", ".join(f"`{i}`" for i in inputs[:4])

        out.append(f"### 2.{i} {name}")
        out.append(f"**What**: {what}")
        out.append(f"**Columns Involved**: {cols_str}")
        out.append(f"**Rules**:\n{rules_str}")
        if evidence:
            out.append(f"**Evidence**: `{source_path_rel}` {evidence}{inputs_str}")
        out.append("")
    return "\n".join(out).rstrip()


def _build_section3_v8(inv_obj: dict, concepts: list[dict], upstreams: list[str],
                        downstream: list[str]) -> str:
    """§3 Query Advisory — UC storage layout + common query patterns + JOINs +
    gotchas, anchored to uc_inventory.json + concepts.json."""
    out: list[str] = []
    # 3.1 UC storage layout
    out.append("### 3.1 UC Storage Layout")
    table_type = (inv_obj.get("table_type") or "—").upper()
    fmt = inv_obj.get("data_source_format") or "n/a"
    partitioned_by = inv_obj.get("partitioned_by") or []
    clustered_by = inv_obj.get("clustering_columns") or []
    rows: list[tuple[str, str]] = [("Type", table_type), ("Format", fmt)]
    if partitioned_by:
        rows.append(("Partitioned by", ", ".join(f"`{c}`" for c in partitioned_by)))
    else:
        rows.append(("Partitioned by", "(not partitioned)"))
    if clustered_by:
        rows.append(("Clustered by", ", ".join(f"`{c}`" for c in clustered_by)))
    if table_type == "VIEW":
        rows.append(("Materialization", "view_definition (re-runs on every query)"))
    out.append("")
    out.append("| Property | Value |")
    out.append("|----------|-------|")
    for k, v in rows:
        out.append(f"| **{k}** | {v} |")

    # 3.2 Common query patterns
    out.append("")
    out.append("### 3.2 Common Query Patterns")
    patterns: list[tuple[str, str]] = []
    case_concepts = [c for c in concepts if c.get("kind") == "case_flag"]
    dim_concepts = [c for c in concepts if c.get("kind") == "dim_lookup"]
    filter_concepts = [c for c in concepts if c.get("kind") == "filter_block"]
    signflip = [c for c in concepts if c.get("kind") == "union_leg_sign_flip"]
    if case_concepts:
        cols = sorted({c["columns_involved"][0] for c in case_concepts if c.get("columns_involved")})
        patterns.append((
            "Filter on discriminator flags",
            f"Use `{cols[0]} = 1`-style filters on the precomputed flag columns "
            f"({', '.join('`'+c+'`' for c in cols[:4])}) instead of recomputing "
            "the underlying CASE predicates downstream."
        ))
    if dim_concepts:
        patterns.append((
            "Use enriched columns directly",
            "Dimension attributes are already joined in — no need to re-join the "
            f"underlying dim tables ({', '.join('`'+ (c.get('dim_fqn') or '').rsplit('.',1)[-1] +'`' for c in dim_concepts[:4])})."
        ))
    if signflip:
        patterns.append((
            "Sum amounts directly for net flow",
            "Amount columns are already sign-flipped per leg — summing them "
            "yields net flow (deposits - withdraws). No need to subset by "
            "MIMOAction unless you want gross flow."
        ))
    if filter_concepts:
        patterns.append((
            "Filters are pre-applied",
            "Top-level filter blocks (e.g. settled-only / dedup) are baked "
            "into the view. Querying this object directly means working on "
            "the filtered set — see §3.4 Gotchas."
        ))
    if not patterns:
        patterns.append((
            "Standard SELECT",
            "No precomputed flags or sign-flips — query columns directly."
        ))
    out.append("")
    out.append("| Analyst Question | Recommended Approach |")
    out.append("|------------------|----------------------|")
    for q, a in patterns:
        out.append(f"| {q} | {a} |")

    # 3.3 Common JOINs
    out.append("")
    out.append("### 3.3 Common JOINs")
    out.append("")
    if dim_concepts:
        out.append("| JOIN to | Condition | Purpose |")
        out.append("|---------|-----------|---------|")
        for c in dim_concepts:
            dim = c.get("dim_fqn") or "?"
            cond = (c.get("join_condition") or "").replace("\n", " ")[:120]
            alias = c.get("alias") or "?"
            out.append(f"| `{dim}` | `{cond}` | Lookup via alias `{alias}` |")
    else:
        out.append("| JOIN to | Condition | Purpose |")
        out.append("|---------|-----------|---------|")
        out.append("| (none discovered) | — | — |")

    # 3.4 Gotchas
    out.append("")
    out.append("### 3.4 Gotchas")
    out.append("")
    gotchas: list[str] = []
    for c in filter_concepts:
        scope = c.get("scope") or "?"
        preds = c.get("predicates") or []
        pred_str = "; ".join(f"`{p['col']} {p['op']} {p['val']}`" for p in preds[:3])
        gotchas.append(
            f"Scope `{scope}` applies {pred_str} unconditionally — rows failing "
            "these predicates are NOT in this view's output."
        )
    if signflip:
        scopes = [c.get("scope") for c in signflip]
        gotchas.append(
            f"Sign flip in scope(s) {', '.join('`'+s+'`' for s in scopes)} means "
            "summing amount columns nets to (deposit - withdraw). Multiply by "
            "-1 again if you want gross withdraw amounts."
        )
    if not gotchas:
        gotchas.append(
            "No top-level filter blocks or sign flips detected. See `.review-needed.md` "
            "for parser warnings and UNVERIFIED columns."
        )
    for g in gotchas:
        out.append(f"- {g}")
    return "\n".join(out)


def _build_section6_relationships(upstream_rows: list[dict],
                                    downstream: list[str]) -> str:
    """§6 Relationships — concise references-to summary + referenced-by list.
    The full upstream table lives in §5 Lineage; here we just summarize the
    Primary upstream and how many JOIN/UNION upstreams exist, then list the
    downstream consumers (which §5 doesn't cover)."""
    out: list[str] = []
    out.append("### 6.1 References To (summary — see §5 for full table)")
    out.append("")
    primary = next((u for u in upstream_rows if u.get("role") == "Primary"), None)
    if primary:
        wiki = primary.get("wiki_path") or "(no wiki)"
        out.append(f"- **Primary upstream**: `{primary['full_name']}` (wiki: `{wiki}`)")
    n_join = sum(1 for u in upstream_rows if u.get("role") != "Primary")
    if n_join:
        out.append(f"- **JOIN/UNION upstreams**: {n_join} additional object(s)")
        wiki_covered = sum(1 for u in upstream_rows
                           if u.get("role") != "Primary" and u.get("wiki_path"))
        out.append(f"- **Wiki coverage**: {wiki_covered}/{n_join} JOIN/UNION upstreams "
                   "have a cached upstream wiki "
                   "(see `_discovery/upstream_wikis/_index.json`)")
    out.append("")
    out.append("### 6.2 Referenced By (downstream consumers)")
    out.append("")
    if downstream:
        for d in downstream[:20]:
            out.append(f"- `{d}`")
        if len(downstream) > 20:
            out.append(f"- _(+{len(downstream) - 20} more)_")
    else:
        out.append("- _(no downstream consumers tracked in `_dag.json`)_")
    return "\n".join(out)


def _build_section7_sample_queries() -> str:
    """§7 Sample Queries — placeholder; analysts should look at query_history."""
    return (
        "> Sample queries are not auto-generated. Refer to "
        "`knowledge/skills/_de_existing/` and `system.query.history` for analyst "
        "usage patterns against this object."
    )


def _build_section8_atlassian() -> str:
    """§8 Atlassian Knowledge Sources — placeholder unless Confluence/Jira injected."""
    return (
        "> No Atlassian sources discovered for this object in the current pipeline. "
        "When Confluence pages or Jira tickets are linked to this UC object, "
        "they will appear here (run `tools/uc_pipelines/cache_atlassian_for_object.py` "
        "if/when that tool exists)."
    )


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


def _generate_bronze_tier1_for_object(*, schema: str, obj_name: str,
                                       inv_obj: dict, writer_meta: dict,
                                       dry_run: bool) -> dict:
    """Author a UC wiki for a bronze table by fully inheriting from a Tier 1
    production wiki.

    Bronze tables have no UC writer of their own — they're populated by the
    generic ingest pipeline. But their column names are 1:1 with the production
    SQL Server table, so we can mechanically inherit each column's description
    from the Tier 1 wiki of `{source_db}.{source_schema}.{source_table}`.

    Every emitted description falls into Bucket A (verbatim inheritance) or
    Bucket C (null-with-provenance when a column exists in bronze but not in
    the Tier 1 source wiki). No AI inference. No source-code narration."""
    schema_root = OBJ_OUT_ROOT / schema
    columns = inv_obj.get("columns") or []
    folder = "Tables"
    out_dir = schema_root / folder
    out_dir.mkdir(parents=True, exist_ok=True)
    out_md = out_dir / f"{obj_name}.md"
    out_review = out_dir / f"{obj_name}.review-needed.md"

    tier1_rel = writer_meta.get("upstream_wiki_path") or ""
    tier1_path = REPO / tier1_rel if tier1_rel else None
    src_db = writer_meta.get("source_database") or "?"
    src_sch = writer_meta.get("source_schema") or "?"
    src_tbl = writer_meta.get("source_table") or "?"
    src_repo = writer_meta.get("source_repo") or "?"
    lake = writer_meta.get("datalake_path") or "(no lake path on record)"
    copy_strat = writer_meta.get("copy_strategy") or "(no copy_strategy on record)"
    source_label = f"{src_db}.{src_sch}.{src_tbl}"

    elements_rows: list[dict] = []
    provenance_rows: list[dict] = []
    sidecar_unverified: list[dict] = []
    sidecar_warnings: list[str] = []
    tier_counts: Counter = Counter()
    check_date = _today_iso()

    tier1_has_wiki = bool(tier1_path and tier1_path.is_file())
    if not tier1_has_wiki:
        sidecar_warnings.append(
            f"upstream_wiki_path declared in schema card not found on disk: {tier1_rel}"
        )

    for col in columns:
        cname = col["name"]
        ctype = col.get("data_type") or col.get("type") or "—"
        nullable = "YES" if col.get("nullable") else "NO"
        ordinal = col.get("ordinal") or (len(elements_rows) + 1)

        inherited = None
        if tier1_has_wiki:
            inherited = _inherit_upstream_description(tier1_path, cname)

        if inherited:
            inherited_tag = TIER_TAG_RE.search(inherited)
            if inherited_tag:
                description = inherited
                tier_letter = inherited_tag.group(1)[0] if inherited_tag.group(1)[0].isdigit() else "1"
                cited_as = inherited_tag.group(0)
            else:
                description = _ensure_tier_tag(
                    inherited, "1", f"inherited from {source_label}"
                )
                tier_letter = "1"
                cited_as = f"(Tier 1 — inherited from {source_label})"
            provenance_source = f"upstream wiki `{tier1_rel}` (bronze passthrough)"
        else:
            description = _null_with_provenance(source_label, cname, check_date)
            description = _ensure_tier_tag(
                description, "N",
                "bronze-passthrough; column not documented in Tier 1 source wiki"
                if tier1_has_wiki else "bronze-passthrough; Tier 1 source wiki not on disk",
            )
            tier_letter = "N"
            provenance_source = (
                f"would inherit from `{tier1_rel}` but column `{cname}` "
                f"not present in source wiki"
                if tier1_has_wiki else
                f"would inherit from `{tier1_rel}` but file not on disk"
            )
            cited_as = "(Tier N — bronze-passthrough-no-source-row)"
            sidecar_unverified.append({
                "name": cname,
                "reason": (
                    f"present in bronze ingest but no row in {source_label} wiki — "
                    f"may indicate added column post-ingest, or schema drift"
                    if tier1_has_wiki else
                    f"Tier 1 wiki path declared but not on disk: {tier1_rel}"
                ),
            })

        elements_rows.append({
            "ordinal": ordinal, "name": cname, "type": ctype,
            "nullable": nullable, "description": description,
        })
        tier_counts[tier_letter] += 1
        provenance_rows.append({
            "column": cname, "source": provenance_source,
            "tier": tier_letter, "cited_as": cited_as,
        })

    n_pass = tier_counts.get("1", 0)
    n_narr = 0
    n_null = tier_counts.get("N", 0)
    n_5 = tier_counts.get("5", 0)  # sidecar/domain-expert overrides (DWH framework)
    n_unverified = tier_counts.get("U", 0)

    obj_fqn = f"main.{schema}.{obj_name}"
    upstreams_seen = [source_label]
    fm = {
        "object_fqn": obj_fqn,
        "object_type": (inv_obj.get("table_type") or "TABLE").upper(),
        "producer_kind": "bronze_tier1_inheritance",
        "generator": "tools/uc_pipelines/generate_wiki.py",
        "object": obj_fqn,
        "schema": schema,
        "framework": "uc-pipeline-doc",
        "table_type": (inv_obj.get("table_type") or "TABLE").upper(),
        "format": inv_obj.get("data_source_format"),
        "column_count": len(columns),
        "row_count": inv_obj.get("row_count"),
        "generated_at": _now_iso_z(),
        "upstreams": upstreams_seen,
        "writer": {
            "kind": "bronze_tier1_inheritance",
            "path": tier1_rel,
            "source_database": src_db,
            "source_schema": src_sch,
            "source_table": src_tbl,
            "source_repo": src_repo,
            "datalake_path": lake,
            "copy_strategy": copy_strat,
            "source_code_snapshot": None,
        },
        "tier_breakdown": {
            "tier1_columns": n_pass,
            "tier2_columns": 0,
            "tier3_columns": 0,
            "tier4_columns": 0,
            "tier5_columns": n_5,
            "tier_null_columns": n_null,
            "unverified_columns": n_unverified,
        },
    }

    try:
        import yaml  # type: ignore
        fm_text = yaml.safe_dump(fm, sort_keys=False, allow_unicode=True).rstrip()
    except Exception:
        fm_text = json.dumps(fm, indent=2)

    prop_table = _build_property_table(obj_name, inv_obj, schema)

    section1 = (
        f"Bronze ingest table populated from production source "
        f"`{source_label}` (`{src_repo}` repo). "
        f"This UC object is a 1:1 passthrough of the source table; no transform is "
        f"applied during ingest. All column descriptions are inherited byte-for-byte "
        f"from the Tier 1 source wiki at `{tier1_rel}`.\n\n"
        f"- Lake path: `{lake}`\n"
        f"- Copy strategy: `{copy_strat}`\n"
        f"- Source database: `{src_db}` (`{src_repo}`)\n"
        f"- Source schema/table: `{src_sch}.{src_tbl}`\n"
        f"- {n_pass} of {len(columns)} columns inherited; {n_null} columns null-with-provenance."
    )

    section2 = (
        "Pure ingest passthrough — no UC-side transform. The producer is the generic "
        "bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in "
        "this repo. Refer to the Tier 1 source wiki for the canonical column semantics."
    )

    elements_lines = [
        "| # | Element | Type | Nullable | Description |",
        "|---|---------|------|----------|-------------|",
    ]
    for r in sorted(elements_rows, key=lambda x: x["ordinal"]):
        desc = r["description"].replace("|", "\\|").replace("\n", " ")
        elements_lines.append(
            f"| {r['ordinal']} | {r['name']} | {r['type']} | {r['nullable']} | {desc} |"
        )
    section3 = "\n".join(elements_lines)

    downstream = load_downstream_from_dag(DAG_PATH, obj_fqn)
    upstream_table_rows = [{
        "full_name": source_label,
        "role": "Primary",
        "wiki_path": tier1_rel,
    }]
    section4 = _build_section4(obj_name, schema, upstream_table_rows, downstream,
                                  0, 0, 0, section_prefix="4")
    section5 = _build_section5(obj_name, schema, [])
    section6 = _build_section6_provenance(provenance_rows)

    tier_legend = (
        "- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).\n"
        "- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.\n"
        "- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure."
    )

    md_parts = [
        "---", fm_text, "---", "",
        f"# {obj_name}", "",
        f"> Bronze ingest in `main.{schema}` (1:1 passthrough of `{source_label}`). "
        f"{n_pass} of {len(columns)} columns inherited from Tier 1 source wiki; "
        f"{n_null} columns null-with-provenance (Tier N).",
        "", prop_table, "", "---", "",
        "## 1. What it is", "", section1, "", "---", "",
        "## 2. Transform Logic", "", section2, "", "---", "",
        "## 3. Elements", "", section3, "", "---", "",
        "## 4. Lineage", "", section4, "", "---", "",
        "## 5. Sample Queries & Common JOINs", "", section5, "", "---", "",
        "## 6. Deploy / UC ALTER provenance", "", section6, "", "---", "",
        "## 7. Tier Legend", "", tier_legend, "",
        f"*Generated: {_today_iso()} | Tiers: {n_pass} T1, 0 T2, 0 T3, 0 T4, {n_5} T5, {n_null} TN, {n_unverified} U "
        f"| Elements: {len(elements_rows)}/{len(columns)} | Source: bronze_tier1_inheritance*",
    ]
    md_text = "\n".join(md_parts) + "\n"

    sidecar_parts = [
        f"# Review-needed sidecar — `{obj_name}`", "",
        f"Generated: {_today_iso()}",
        f"Wiki: `{out_md.relative_to(REPO).as_posix()}`",
        f"Inheritance source: `{tier1_rel}`", "",
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
    if sidecar_warnings:
        sidecar_parts.extend(["", "## Parser warnings", ""])
        for w in sidecar_warnings:
            sidecar_parts.append(f"- {w}")
    sidecar_text = "\n".join(sidecar_parts) + "\n"

    wrote: list[str] = []
    if not dry_run:
        out_md.write_text(md_text, encoding="utf-8")
        wrote.append(str(out_md.relative_to(REPO)))
        if sidecar_unverified or sidecar_warnings:
            out_review.write_text(sidecar_text, encoding="utf-8")
            wrote.append(str(out_review.relative_to(REPO)))
        elif out_review.exists():
            out_review.unlink()

    return {
        "obj": obj_name,
        "wrote": wrote,
        "tier_counts": dict(tier_counts),
        "n_unverified": n_unverified,
        "status": "Generated",
        "blocked_on_upstream": None,
    }


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

    # Short-circuit for bronze tables that we're documenting purely by
    # inheritance from a Tier 1 production wiki. They have no source code
    # (the writer is the bronze ingest pipeline, owned upstream) so the
    # normal lineage/source-code narration path doesn't apply.
    writer_meta = inv_obj.get("writer") or {}
    if writer_meta.get("kind") == "BRONZE_TIER1_INHERITANCE":
        return _generate_bronze_tier1_for_object(
            schema=schema, obj_name=obj_name, inv_obj=inv_obj,
            writer_meta=writer_meta, dry_run=dry_run,
        )

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
    # Parse FROM/JOIN alias maps once per object so the per-column narrator
    # can resolve `mfts.X` style references back to physical UC FQNs without
    # re-parsing the source code on every column.
    scopes_map, cte_ranges_list = _parse_scopes(source_code) if source_code else ({}, [])

    # Load Phase 4.5/4.6 artifacts. These power the 8-section synthesis.
    concepts_doc = read_concepts(schema_root, obj_name)
    formulas_doc = read_formulas(schema_root, obj_name)
    concepts = concepts_doc.get("concepts", [])
    formulas_by_col = {
        (f.get("column") or "").lower(): f
        for f in formulas_doc.get("formulas", [])
    }
    # Build column→concepts index so each Tier-2 description can pick its
    # business name from the concept that owns the column.
    concepts_by_col: dict[str, list[dict]] = defaultdict(list)
    for c in concepts:
        for col in c.get("columns_involved") or []:
            concepts_by_col[col.lower()].append(c)

    # Hard gate: TABLE objects with no discoverable writer cannot be documented
    # mechanically from real evidence. The live UC comments on such a table
    # (however populated they look) are explicitly NOT a source of truth — they
    # are the artifact this pipeline is intended to replace. Emitting a wiki
    # full of (Tier U — unclassified) rows just ships honest noise; skipping and
    # recording a `Skipped` audit row points exactly at the gap that must be
    # fixed (writer discovery / notebook fetch / SP resolution) before this
    # table can be documented at all.
    is_view = (inv_obj.get("table_type") or "").upper() in ("VIEW", "MATERIALIZED_VIEW")
    if (not is_view) and writer_kind == "unknown":
        live_comment_cols = sum(
            1 for c in columns if (c.get("comment") or "").strip()
        )
        folder = "Tables"
        out_dir = schema_root / folder
        out_dir.mkdir(parents=True, exist_ok=True)
        out_status = out_dir / f"{obj_name}.status.json"
        skip_payload = {
            "object": f"main.{schema}.{obj_name}",
            "status": "Skipped",
            "status_detail": (
                f"TABLE writer not discoverable ({writer_kind}); blocked on writer/notebook/SP discovery. "
                f"Live UC comments on this table ({live_comment_cols}/{len(columns)} columns) "
                f"are intentionally NOT used as a source — they are the artifact to be replaced."
            ),
            "blocked_on_upstream": None,
            "all_blocked_upstreams": [],
            "routing_attempts": "writer-discovery exhausted: no source on disk, no notebook/job entity_id resolved. Live UC comments are not used as anchor.",
            "n_unverified": len(columns),
            "tier_counts": {"U": len(columns)},
            "generated_at": _now_iso_z(),
            "writer_kind": writer_kind,
            "live_comment_columns": live_comment_cols,
            "total_columns": len(columns),
        }
        if not dry_run:
            out_status.write_text(json.dumps(skip_payload, indent=2, ensure_ascii=False),
                                   encoding="utf-8")
            # Best-effort: clear out any prior all-Tier-U .md / .review-needed.md
            # that an earlier (laundering) run wrote, so the bank stops shipping
            # garbage from this table.
            for stale_ext in (".md", ".review-needed.md"):
                stale = out_dir / f"{obj_name}{stale_ext}"
                if stale.exists():
                    stale.unlink()
        return {
            "obj": obj_name,
            "wrote": [str(out_status.relative_to(REPO))] if not dry_run else [],
            "tier_counts": {"U": len(columns)},
            "n_unverified": len(columns),
            "status": "Skipped",
            "blocked_on_upstream": None,
        }

    upstreams_seen: list[str] = []
    for r in lineage_rows:
        s = r.get("source_object")
        if not s or s in ("—", "(computed)", "(literal)"):
            continue
        if s not in upstreams_seen:
            upstreams_seen.append(s)

    # Augment with upstreams cached by Phase 3 — BUT only from this object's
    # per-object slice of `_index.json`, AND only entries that exist in the
    # catalog DAG. This filters out CTE-name garbage (`main.basedata`,
    # `main.ftd_iban`, ...) that pre-fix runs of `cache_upstream_wikis.py`
    # had written into `per_object_upstreams`.
    per_obj_ups = (ux_index.get("per_object_upstreams") or {}).get(obj_name) or []
    if per_obj_ups:
        candidates = list(per_obj_ups)
    else:
        candidates = [e.get("full_name") for e in ux_index.get("upstreams", [])]
    for fn in candidates:
        if not fn:
            continue
        if fn in upstreams_seen:
            continue
        if _norm(fn) not in dag_nodes:
            # Not a real UC object — drop. This is the CTE-name filter.
            continue
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

    # DWH semantic-doc Rule 15 — Tier 5 (reviewer corrections from `.review-needed.md`)
    # is an ABSOLUTE override. Read the prior sidecar at the start of generation;
    # any column that has a correction row short-circuits the entire tier search.
    reviewer_corrections = read_reviewer_corrections(out_review)

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

        # Tier 5 short-circuit: reviewer correction from `.review-needed.md`.
        # This OVERRIDES every other tier (DWH framework Rule 15). No further
        # tier resolution runs for this column.
        correction = reviewer_corrections.get(cname.lower())
        if correction:
            description = _ensure_tier_tag(correction, "5", "domain expert")
            elements_rows.append({"ordinal": ordinal, "name": cname, "type": ctype,
                                  "nullable": nullable, "description": description})
            tier_counts["5"] += 1
            provenance_rows.append({
                "column": cname,
                "source": f"sidecar reviewer correction (`{out_review.relative_to(REPO).as_posix()}`)",
                "tier": "5",
                "cited_as": "(Tier 5 — domain expert)",
            })
            continue

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
                    description = _ensure_tier_tag(description, "N", "terminal-no-wiki")
                    tier_letter = "N"
                    provenance_source = f"null-with-provenance (terminal upstream `{src_obj}`)"
                    cited_as = "(Tier N — terminal-no-wiki)"
                elif up_status == "in_scope_not_yet_authored":
                    # Honest disclosure: the upstream object IS in our scope but its
                    # wiki hasn't been authored yet. Block on it explicitly rather
                    # than synthesizing a description from any other source. When
                    # the upstream wiki lands, regenerating this object will pick
                    # up the inheritance automatically.
                    description = (
                        f"Source: `{src_obj}.{src_col}`. Upstream wiki is in-scope "
                        f"but not yet authored as of {check_date}; this column will be "
                        f"re-resolved when the upstream wiki is generated."
                    )
                    description = _ensure_tier_tag(description, "N", f"blocked-on-upstream `{src_obj}`")
                    tier_letter = "N"
                    provenance_source = f"blocked: upstream wiki for `{src_obj}` not yet authored"
                    cited_as = "(Tier N — blocked-on-upstream)"
                    sidecar_warnings.append(
                        f"`{cname}`: blocked on upstream `{src_obj}` wiki (in-scope, not yet authored).")

        # Tier 2 — Bucket (B): formula-backed description. Phase 4.6 (formulas.json)
        # has the predicate-explicit, alias-resolved formula; Phase 4.5 (concepts.json)
        # provides the business name when the column is part of a discovered concept.
        # The formula+concept combo replaces the raw snippet that the older
        # narrator emitted.
        if description is None:
            formula_entry = formulas_by_col.get(cname.lower())
            concepts_for_col = concepts_by_col.get(cname.lower(), [])
            formula_desc = _build_formula_backed_description(
                cname, formula_entry, concepts_for_col,
            )
            if formula_desc:
                description = formula_desc
                tier_letter = "2"
                provenance_source = (
                    f"formula lookup ({formula_entry.get('transform_kind') if formula_entry else 'n/a'})"
                )
                cited_as = (
                    "[uc_view_ddl]" if writer_kind == "view_definition"
                    else f"[notebook:{source_path_rel}]"
                )

        # Fallback: snippet narrator (older path) for columns the formula
        # extractor couldn't classify but the snippet locator can.
        if description is None and source_code:
            narrated = _narrate_from_source_code(cname, source_code, src_obj,
                                                  source_path_rel or "(no source cached)",
                                                  writer_kind,
                                                  scopes=scopes_map,
                                                  cte_ranges=cte_ranges_list)
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
                          f"no upstream wiki match and no source-code expression. "
                          f"NOTE: live UC comment (if any) is intentionally NOT used as a source — "
                          f"the live UC comment is the artifact we are trying to replace, not anchor against.",
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
    n_5 = tier_counts.get("5", 0)  # Domain-expert / sidecar override (DWH framework).
    n_null = tier_counts.get("N", 0)  # null-with-provenance gap disclosure.
    n_unverified = tier_counts.get("U", 0)
    n_null_prov = n_null

    kind_label_map = {"view_definition": "view", "sp_or_sql": "table (SP/SQL writer)",
                       "notebook": "table (notebook writer)", "script": "table (script writer)",
                       "unknown": "table (unknown writer)"}
    table_type_label = (inv_obj.get("table_type") or "").upper() or "VIEW"
    kind_label = kind_label_map.get(writer_kind, table_type_label.lower())

    obj_fqn = f"main.{schema}.{obj_name}"
    fm = {
        # Canonical keys expected by validate_pipeline_wiki.py + adversarial_evaluate.py:
        "object_fqn": obj_fqn,
        "object_type": table_type_label,
        "producer_kind": writer_kind,
        "generator": "tools/uc_pipelines/generate_wiki.py",
        # Back-compat aliases used by older readers in the pack:
        "object": obj_fqn,
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
        # Phase 4.5/4.6 artifact counts — drive §1/§2 validation in Phase 6.
        "concept_count": len(concepts),
        "formula_count": sum(1 for f in formulas_doc.get("formulas", []) if f.get("formula")),
        "tier_breakdown": {
            "tier1_columns": n_pass,
            "tier2_columns": n_narr,
            "tier3_columns": n_3,
            "tier4_columns": n_4,
            "tier5_columns": n_5,
            "tier_null_columns": n_null,
            "unverified_columns": n_unverified,
        },
    }

    try:
        import yaml  # type: ignore
        fm_text = yaml.safe_dump(fm, sort_keys=False, allow_unicode=True).rstrip()
    except Exception:
        fm_text = json.dumps(fm, indent=2)

    prop_table = _build_property_table_v8(obj_name, inv_obj, schema,
                                            len(concepts), downstream)
    # Find the primary upstream's wiki path for §1 paragraph 2.
    primary_upstream_wiki = None
    for u in upstream_table_rows[:1]:
        if u.get("wiki_path"):
            primary_upstream_wiki = u["wiki_path"]

    section1 = _build_section1_v8(obj_name, schema, kind_label, upstreams_seen,
                                    concepts, inv_obj, primary_upstream_wiki,
                                    n_pass, n_narr, n_null)
    if _is_pure_passthrough(lineage_rows) and not concepts:
        section2 = _build_section2_pure_passthrough(upstreams_seen)
    else:
        section2 = _build_section2_v8(concepts, lineage_rows,
                                       source_path_rel or "(no source cached)")
    section3 = _build_section3_v8(inv_obj, concepts, upstreams_seen, downstream)

    elements_lines = ["| # | Element | Type | Nullable | Description |",
                       "|---|---------|------|----------|-------------|"]
    for r in sorted(elements_rows, key=lambda x: x["ordinal"]):
        desc = r["description"].replace("|", "\\|").replace("\n", " ")
        elements_lines.append(f"| {r['ordinal']} | {r['name']} | {r['type']} | {r['nullable']} | {desc} |")
    section4_elements = "\n".join(elements_lines)

    section5_lineage = _build_section4(obj_name, schema, upstream_table_rows, downstream,
                                          lineage_stats["parsed"], lineage_stats["runtime"],
                                          lineage_stats["mismatches"])
    section6 = _build_section6_relationships(upstream_table_rows, downstream)
    section7 = _build_section7_sample_queries()
    section8 = _build_section8_atlassian()

    tier_legend = (
        "- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough/rename/cast).\n"
        "- **Tier 2** — column described from a formula in `formulas.json` + an optional named concept from `concepts.json`. The formula is the predicate-explicit, alias-resolved SQL transformation; the concept gives the business name.\n"
        "- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides every other tier including Tier 1 (per DWH semantic-doc framework).\n"
        "- **Tier N** — null-with-provenance: column points at an upstream that is either terminal-with-no-wiki, or in-scope-but-not-yet-authored. Explicit gap disclosure.\n"
        "- **Tier U** — unclassifiable: no upstream wiki match, no formula, no source-code snippet. Mechanical disclosure of unclassifiability — see `.review-needed.md`."
    )

    md_parts = [
        "---", fm_text, "---", "",
        f"# {obj_name}", "",
        f"> {kind_label.capitalize()} in `main.{schema}`. {len(concepts)} business concept(s) in §2; "
        f"{n_pass + n_narr + n_null} of {len(columns)} columns documented from anchored evidence; "
        f"{n_unverified} unverified (see sidecar).",
        "", prop_table, "", "---", "",
        "## 1. Business Meaning", "", section1, "", "---", "",
        "## 2. Business Logic", "", section2, "", "---", "",
        "## 3. Query Advisory", "", section3, "", "---", "",
        "## 4. Elements", "", section4_elements, "", "---", "",
        "## 5. Lineage", "", section5_lineage, "", "---", "",
        "## 6. Relationships", "", section6, "", "---", "",
        "## 7. Sample Queries", "", section7, "", "---", "",
        "## 8. Atlassian Knowledge Sources", "", section8, "", "---", "",
        "## Tier Legend", "", tier_legend, "",
        f"*Generated: {_today_iso()} | Concepts: {len(concepts)} | "
        f"Formulas: {sum(1 for f in formulas_doc.get('formulas', []) if f.get('formula'))} | "
        f"Tiers: {n_pass} T1, {n_narr} T2, {n_3} T3, {n_4} T4, {n_5} T5, {n_null} TN, {n_unverified} U "
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

    # Reviewer Corrections — DWH semantic-doc Rule 15. Reviewers add rows here
    # and the next `generate_wiki.py` run applies them as Tier 5 (absolute
    # override) descriptions. Existing corrections from prior runs are carried
    # forward verbatim so they persist across regenerations.
    sidecar_parts.extend([
        "",
        "## Reviewer Corrections",
        "",
        "> Domain-expert overrides applied as **Tier 5** on the next regeneration.",
        "> Tier 5 is absolute — it overrides every other tier including Tier 1.",
        "",
        "| Column | Correction | Current (wrong) | Reason | Reviewer |",
        "|--------|------------|-----------------|--------|----------|",
    ])
    if reviewer_corrections:
        for col_lower, correction in sorted(reviewer_corrections.items()):
            safe_corr = correction.replace("|", "\\|")
            sidecar_parts.append(f"| `{col_lower}` | {safe_corr} | (carried forward) | [RESOLVED] | (prior reviewer) |")
    else:
        sidecar_parts.append("| _(none)_ | | | | |")

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
