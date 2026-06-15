#!/usr/bin/env python3
"""
Phase 4.5 — Concept Discovery (UC-Pipeline pack).

Mines the cached view DDL / notebook source code for NAMED BUSINESS CONCEPTS
that Phase 5 will compose into §1 Business Meaning + §2 Business Logic
subsections.

Concept kinds detected:
  - case_flag           : `CASE WHEN ... THEN <const> ELSE <const> END AS <col>`
  - union_leg_sign_flip : two SELECT blocks unioned where one projects `-1 *`
                          on amount columns (deposit + withdraw legs)
  - dim_lookup          : `JOIN <dim_fqn> <alias>` where dim_fqn is in lineage
                          upstreams AND its name matches `*dim_*`
  - filter_block        : `WHERE <status_col> = <const>` / `IN (...)` at the
                          top of a CTE — applies to all rows in that scope
  - pair_group          : column-name pattern groups (Init*/End*, Is*+*Date,
                          ID+ParentID) detected over `uc_inventory.json`

For each concept, attempts to decode `<x>ID = <N>` predicates against the
upstream wiki's Elements row for `<x>ID` — if the upstream description
contains `N=Label` pairs, the decode goes into `upstream_enum_decodes` and
Phase 5 will use it in the §2 Rules bullets.

Output: `_discovery/concepts/{Object}.json` — see `04.5-concept-discovery.mdc`
schema.

Usage:
  python tools/uc_pipelines/discover_concepts.py --schema etoro_kpi_prep --object v_mimo_emoneyplatform
  python tools/uc_pipelines/discover_concepts.py --schema etoro_kpi_prep
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "tools" / "uc_pipelines"))

# Re-use parsing helpers from generate_wiki to keep semantics identical.
from generate_wiki import (  # noqa: E402
    _strip_sql_comments_and_strings,
    _parse_scopes,
    _alias_map_for_body,
    _parse_elements_rows,
    _find_column_expression_lines,
    _scope_for_line,
    _resolve_terminal_upstreams,
    _norm,
    OBJ_OUT_ROOT,
)


# ---------------------------------------------------------------------------
# Regex patterns for concept detectors
# ---------------------------------------------------------------------------

# CASE flag: optionally multi-line, captures the WHEN expression, the THEN
# constant, optional ELSE constant, and the bound column name. The constant
# must be a number or a single-quoted string literal (1, 0, 33, 'X').
_CASE_FLAG_RE = re.compile(
    r"CASE\s+WHEN\s+(?P<when>.+?)\s+THEN\s+(?P<then>(?:-?\d+(?:\.\d+)?)|(?:'[^']*'))\s*"
    r"(?:ELSE\s+(?P<elseval>(?:-?\d+(?:\.\d+)?)|(?:'[^']*'))\s*)?"
    r"END\s+AS\s+`?(?P<col>[A-Za-z_][A-Za-z0-9_]*)`?",
    re.IGNORECASE | re.DOTALL,
)

# Generic predicate inside a CASE WHEN expression: `col op value` where op is
# one of =, !=, <, <=, >, >=, IN, LIKE. Values are numbers, string literals,
# or parenthesized IN lists.
_PREDICATE_RE = re.compile(
    r"(?P<col>(?:`?[A-Za-z_][A-Za-z0-9_]*`?\.)?`?[A-Za-z_][A-Za-z0-9_]*`?)\s*"
    r"(?P<op>=|!=|<>|>=|<=|>|<|\bIN\b|\bNOT\s+IN\b|\bLIKE\b)\s*"
    r"(?P<val>\(\s*-?\d+(?:\s*,\s*-?\d+)*\s*\)"
    r"|'[^']*'"
    r"|-?\d+(?:\.\d+)?"
    r"|NULL)",
    re.IGNORECASE,
)

# Sign-flip projection: `-1 *` or `(-1) *` or `- ` prefix on an amount column
_SIGN_FLIP_RE = re.compile(
    r"(?P<sign>-\s*1\s*\*|\(\s*-\s*1\s*\)\s*\*|-(?=[A-Za-z_]))"
    r"\s*(?P<expr>[A-Za-z_][\w\.]*)\s+AS\s+`?(?P<col>[A-Za-z_][A-Za-z0-9_]*)`?",
    re.IGNORECASE,
)

# JOIN to a physical dim_*: captures the dim FQN + alias
_DIM_JOIN_RE = re.compile(
    r"\bJOIN\s+(?P<fqn>main\.[A-Za-z_][\w]*\.[A-Za-z_][\w]*dim[\w]*)\s+"
    r"(?:AS\s+)?(?P<alias>[A-Za-z_][\w]*)?",
    re.IGNORECASE,
)

# Top-of-CTE filter: `WHERE <col> = <const>` or `WHERE <col> IN (...)`
# We capture all such predicates per scope.
_WHERE_PRED_RE = re.compile(
    r"\bWHERE\s+(?P<body>.+?)(?:\bUNION\b|\bGROUP\s+BY\b|\bORDER\s+BY\b|\bHAVING\b|\)|$)",
    re.IGNORECASE | re.DOTALL,
)

# Inline `N=Label, ...` enum pairs in an upstream wiki Elements description.
# Examples that match:
#   "1=CardPayment, 2=Contactless, 3=OnlinePayment"
#   "5=TransferReceived"
_ENUM_PAIR_RE = re.compile(r"\b(\d+)\s*=\s*([A-Za-z][A-Za-z0-9_ /-]{2,40})")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _now_iso() -> str:
    return dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"


def _read_source(schema_root: Path, obj_name: str) -> tuple[str, str | None]:
    for ext in ("sql", "py", "scala", "r"):
        p = schema_root / "_discovery" / "source_code" / f"{obj_name}.{ext}"
        if p.exists():
            return (p.read_text(encoding="utf-8", errors="replace"),
                    str(p.relative_to(REPO)).replace("\\", "/"))
    return ("", None)


def _read_inventory(schema_root: Path) -> dict:
    p = schema_root / "_discovery" / "uc_inventory.json"
    if not p.exists():
        return {"objects": []}
    return json.loads(p.read_text(encoding="utf-8"))


def _read_lineage_rows(schema: str, obj_name: str) -> list[dict]:
    from generate_wiki import _parse_lineage_rows  # local import
    schema_root = OBJ_OUT_ROOT / schema
    for folder in ("Tables", "Views"):
        lp = schema_root / folder / f"{obj_name}.lineage.md"
        if lp.exists():
            return _parse_lineage_rows(lp.read_text(encoding="utf-8"))
    return []


def _read_upstream_index(schema_root: Path) -> dict:
    p = schema_root / "_discovery" / "upstream_wikis" / "_index.json"
    if not p.exists():
        return {"upstreams": []}
    return json.loads(p.read_text(encoding="utf-8"))


def _read_upstream_wiki(schema_root: Path, upstream_fqn: str, ux_index: dict) -> Path | None:
    from generate_wiki import _find_cached_upstream_wiki  # local import
    return _find_cached_upstream_wiki(schema_root, upstream_fqn, ux_index)


def _line_for_offset(source_code: str, offset: int) -> int:
    return source_code.count("\n", 0, offset) + 1


# ---------------------------------------------------------------------------
# Enum decoding
# ---------------------------------------------------------------------------

def _decode_enum_from_upstream_wiki(
    schema_root: Path, upstream_fqn: str, ux_index: dict, column_name: str,
) -> dict[str, str]:
    """Return {value_str: label_str} from the upstream wiki's Elements row
    for column_name. Empty dict if upstream missing or no enum pairs found.
    """
    wiki_path = _read_upstream_wiki(schema_root, upstream_fqn, ux_index)
    if not wiki_path or not wiki_path.exists():
        return {}
    try:
        text = wiki_path.read_text(encoding="utf-8")
    except Exception:
        return {}
    rows = _parse_elements_rows(text)
    row = rows.get(column_name.lower())
    if not row:
        return {}
    desc = row.get("description") or ""
    decoded: dict[str, str] = {}
    for m in _ENUM_PAIR_RE.finditer(desc):
        val, label = m.group(1), m.group(2).strip().rstrip(",.;")
        decoded[val] = label
    return decoded


# ---------------------------------------------------------------------------
# Concept detectors
# ---------------------------------------------------------------------------

def _extract_predicates(when_expr: str) -> list[dict]:
    """Pull every `col op val` predicate out of a CASE WHEN expression."""
    preds: list[dict] = []
    for m in _PREDICATE_RE.finditer(when_expr):
        col = m.group("col").strip("` ")
        # Strip alias prefix if present (`mfts.TxTypeID` → `TxTypeID`)
        col_bare = col.rsplit(".", 1)[-1]
        op = m.group("op").upper().replace("NOT  IN", "NOT IN")
        val = m.group("val")
        # Skip predicates that match function calls / literals on the LHS.
        if col_bare.upper() in {"CASE", "WHEN", "THEN", "ELSE", "END", "AND", "OR", "NOT", "NULL"}:
            continue
        preds.append({"col": col_bare, "op": op, "val": val})
    return preds


def _resolve_predicate_inputs(
    snippet: str, scope: str, scopes: dict[str, dict[str, str]],
) -> list[str]:
    """For a CASE expression snippet, what physical UC FQN(s) does it read from?"""
    return _resolve_terminal_upstreams(snippet, scope, scopes)


def _build_case_flag_concepts(
    source_code: str,
    sanitized: str,
    scopes: dict[str, dict[str, str]],
    cte_ranges: list[tuple[str, int, int]],
    schema_root: Path,
    ux_index: dict,
    lineage_rows: list[dict],
) -> list[dict]:
    """Detect every `CASE WHEN ... THEN <const> ELSE <const> END AS <col>` in the source."""
    concepts: list[dict] = []
    lineage_by_col = {r["name"].lower(): r for r in lineage_rows}

    for m in _CASE_FLAG_RE.finditer(sanitized):
        col = m.group("col")
        when_expr = m.group("when")
        then_val = m.group("then")
        else_val = m.group("elseval")
        match_start = m.start()
        match_end = m.end()
        start_line = _line_for_offset(sanitized, match_start)
        end_line = _line_for_offset(sanitized, match_end)
        # Resolve scope + physical inputs
        scope = _scope_for_line(end_line, source_code, cte_ranges)
        # We pass the ORIGINAL snippet (from source_code, not sanitized) so
        # the resolver can read alias prefixes intact.
        original_snippet = source_code[match_start:match_end]
        inputs = _resolve_predicate_inputs(original_snippet, scope, scopes)

        # Extract predicates
        preds = _extract_predicates(when_expr)

        # Per-predicate enum decoding (only for IN/= against a single upstream)
        decodes: dict[str, str] = {}
        if inputs:
            primary_upstream = inputs[0]
            for p in preds:
                col_lower = p["col"].lower()
                up_decodes = _decode_enum_from_upstream_wiki(
                    schema_root, primary_upstream, ux_index, p["col"]
                )
                if not up_decodes:
                    continue
                # IN (5, 6) → emit per-value decodes
                val = p["val"].strip()
                if val.startswith("("):
                    nums = re.findall(r"-?\d+", val)
                    for n in nums:
                        if n in up_decodes:
                            decodes[f"{p['col']}={n}"] = up_decodes[n]
                else:
                    n = val.strip("'\"")
                    if n in up_decodes:
                        decodes[f"{p['col']}={n}"] = up_decodes[n]

        # Concept name + id
        # Heuristic: name = "<col> classifier" — Phase 5 will use the
        # column's role + concept.kind to produce richer prose.
        concept_id = f"case_flag_{col.lower()}"
        # If the target column is in lineage with a known transform,
        # qualify the name.
        lin = lineage_by_col.get(col.lower())
        kind_suffix = lin.get("transform") if lin else ""
        name = f"{col} computed flag"

        concepts.append({
            "id": concept_id,
            "name": name,
            "kind": "case_flag",
            "columns_involved": [col],
            "predicates": preds,
            "then_value": then_val,
            "else_value": else_val,
            "upstream_enum_decodes": decodes,
            "physical_inputs": inputs,
            "evidence_lines": f"{schema_root.name}.sql L{start_line}-L{end_line}",
            "scope": scope,
        })

    # Deduplicate by (kind, sorted columns_involved, predicates-as-tuple)
    seen: set[tuple] = set()
    deduped: list[dict] = []
    for c in concepts:
        key = (c["kind"], tuple(sorted(c["columns_involved"])),
                tuple((p["col"], p["op"], p["val"]) for p in c["predicates"]),
                c.get("then_value"), c.get("else_value"))
        if key in seen:
            continue
        seen.add(key)
        deduped.append(c)
    return deduped


def _build_sign_flip_concepts(
    source_code: str, sanitized: str,
    scopes: dict[str, dict[str, str]],
    cte_ranges: list[tuple[str, int, int]],
) -> list[dict]:
    """Detect `-1 * <amount> AS <col>` patterns — typical of withdraw / cashout legs."""
    concepts: list[dict] = []
    cols_by_scope: dict[str, list[dict]] = defaultdict(list)
    for m in _SIGN_FLIP_RE.finditer(sanitized):
        col = m.group("col")
        expr = m.group("expr")
        offset = m.start()
        line = _line_for_offset(sanitized, offset)
        scope = _scope_for_line(line, source_code, cte_ranges)
        cols_by_scope[scope].append({
            "column": col, "expression": expr.strip(), "line": line,
        })
    for scope, hits in cols_by_scope.items():
        if not hits:
            continue
        line_list = ",".join("L{}".format(h["line"]) for h in hits)
        concepts.append({
            "id": f"union_leg_sign_flip_{scope}",
            "name": f"Sign-flip leg ({scope})",
            "kind": "union_leg_sign_flip",
            "columns_involved": [h["column"] for h in hits],
            "predicates": [],
            "sign": "-1",
            "expressions": [h["expression"] for h in hits],
            "physical_inputs": list(scopes.get(scope, {}).values()),
            "evidence_lines": line_list,
            "scope": scope,
        })
    return concepts


def _build_dim_lookup_concepts(
    source_code: str, sanitized: str,
    scopes: dict[str, dict[str, str]],
    cte_ranges: list[tuple[str, int, int]],
    ux_index: dict,
) -> list[dict]:
    """Detect `JOIN main.<db>.<...dim_...>` patterns and capture the alias +
    join condition. Dedupe by dim_fqn so the same dim joined in multiple
    legs/CTEs surfaces ONCE with the per-leg join_conditions concatenated.
    """
    upstream_fqns = {_norm(u.get("full_name")) for u in ux_index.get("upstreams", [])}
    by_fqn: dict[str, dict] = {}
    for m in _DIM_JOIN_RE.finditer(sanitized):
        fqn = m.group("fqn")
        alias = m.group("alias") or fqn.rsplit(".", 1)[-1]
        offset = m.start()
        line = _line_for_offset(sanitized, offset)
        scope = _scope_for_line(line, source_code, cte_ranges)
        on_search = re.search(
            r"ON\s+(.+?)(?:\bWHERE\b|\bLEFT\b|\bRIGHT\b|\bINNER\b|\bJOIN\b|\bUNION\b|\)|$)",
            sanitized[m.end():m.end() + 400],
            re.IGNORECASE | re.DOTALL,
        )
        join_cond = on_search.group(1).strip()[:200] if on_search else ""
        if fqn not in by_fqn:
            by_fqn[fqn] = {
                "id": f"dim_lookup_{alias}",
                "name": f"Dim lookup via {alias}",
                "kind": "dim_lookup",
                "columns_involved": [],
                "predicates": [],
                "dim_fqn": fqn,
                "alias": alias,
                "join_conditions": [],
                "physical_inputs": [fqn],
                "upstream_wiki_exists": _norm(fqn) in upstream_fqns,
                "evidence_lines": [],
                "scopes": [],
            }
        entry = by_fqn[fqn]
        cond_key = (scope, join_cond)
        if cond_key not in [(s, c) for s, c in zip(entry["scopes"], entry["join_conditions"])]:
            entry["join_conditions"].append(join_cond)
            entry["scopes"].append(scope)
            entry["evidence_lines"].append(f"L{line}")
    # Finalize: collapse evidence/scopes into strings for downstream readers.
    out: list[dict] = []
    for fqn, entry in by_fqn.items():
        entry["evidence_lines"] = ",".join(entry["evidence_lines"])
        entry["scope"] = entry["scopes"][0] if entry["scopes"] else "main"
        # Keep the most-common join_condition as the canonical one; full
        # list stays under join_conditions for diff visibility.
        entry["join_condition"] = entry["join_conditions"][0] if entry["join_conditions"] else ""
        out.append(entry)
    return out


def _build_filter_block_concepts(
    source_code: str, sanitized: str,
    cte_ranges: list[tuple[str, int, int]],
) -> list[dict]:
    """For each CTE (and main), capture its top-level WHERE predicates.
    These become §3.4 Gotchas — "applied to all rows in this scope".
    """
    concepts: list[dict] = []
    # For each CTE body, find the WHERE clause and pull predicates.
    for name, start, end in cte_ranges:
        body = sanitized[start:end]
        match = _WHERE_PRED_RE.search(body)
        if not match:
            continue
        where_body = match.group("body")
        preds = _extract_predicates(where_body)
        if not preds:
            continue
        offset = start + match.start()
        line = _line_for_offset(sanitized, offset)
        concepts.append({
            "id": f"filter_block_{name}",
            "name": f"Filter block on {name}",
            "kind": "filter_block",
            "columns_involved": [p["col"] for p in preds],
            "predicates": preds,
            "physical_inputs": [],  # caller decorates
            "evidence_lines": f"L{line}",
            "scope": name,
            "applies_to_all_rows_in_scope": True,
        })
    return concepts


def _build_pair_group_concepts(columns: list[dict]) -> list[dict]:
    """Detect column-name pattern pairs from uc_inventory.json columns."""
    by_name = {c["name"].lower(): c["name"] for c in columns}
    concepts: list[dict] = []

    # Init*/End* pair
    init_cols = sorted(n for n in by_name if n.startswith("init"))
    end_cols = sorted(n for n in by_name if n.startswith("end"))
    paired: list[tuple[str, str]] = []
    for ic in init_cols:
        suffix = ic[4:]
        if not suffix:
            continue
        partner = "end" + suffix
        if partner in by_name:
            paired.append((by_name[ic], by_name[partner]))
    if paired:
        concepts.append({
            "id": "pair_init_end",
            "name": "Lifecycle pair (open → close)",
            "kind": "pair_group",
            "columns_involved": [c for p in paired for c in p],
            "predicates": [],
            "pattern": "Init*/End*",
            "physical_inputs": [],
            "evidence_lines": "uc_inventory.json",
            "scope": "schema",
        })

    # Is* + *Date pair: e.g. IsClosed + CloseDate
    is_cols = [n for n in by_name if n.startswith("is")]
    date_cols = [n for n in by_name if n.endswith("date")]
    state_pairs: list[tuple[str, str]] = []
    for ic in is_cols:
        verb = ic[2:]  # "Closed"
        if not verb:
            continue
        partner = verb + "date"
        if partner in by_name:
            state_pairs.append((by_name[ic], by_name[partner]))
    if state_pairs:
        concepts.append({
            "id": "pair_state_timestamp",
            "name": "State + timestamp pair",
            "kind": "pair_group",
            "columns_involved": [c for p in state_pairs for c in p],
            "predicates": [],
            "pattern": "Is* + *Date",
            "physical_inputs": [],
            "evidence_lines": "uc_inventory.json",
            "scope": "schema",
        })

    return concepts


# ---------------------------------------------------------------------------
# Top-level driver
# ---------------------------------------------------------------------------

def discover_for_object(schema: str, obj_name: str) -> dict:
    schema_root = OBJ_OUT_ROOT / schema
    if not schema_root.is_dir():
        raise RuntimeError(f"schema folder not found: {schema_root}")
    inv = _read_inventory(schema_root)
    inv_obj = next((o for o in inv.get("objects", []) if o["name"] == obj_name), None)
    if not inv_obj:
        raise RuntimeError(f"object {obj_name} not found in uc_inventory.json")
    columns = inv_obj.get("columns") or []

    source_code, source_path = _read_source(schema_root, obj_name)
    if not source_code:
        # No source — emit empty concept file so downstream phases don't crash.
        return _write({
            "object_fqn": f"main.{schema}.{obj_name}",
            "generated_at": _now_iso(),
            "concept_count": 0,
            "concepts": [],
            "source": None,
        }, schema_root, obj_name)

    sanitized = _strip_sql_comments_and_strings(source_code)
    scopes, cte_ranges = _parse_scopes(source_code)
    lineage_rows = _read_lineage_rows(schema, obj_name)
    ux_index = _read_upstream_index(schema_root)

    concepts: list[dict] = []
    concepts.extend(_build_case_flag_concepts(
        source_code, sanitized, scopes, cte_ranges,
        schema_root, ux_index, lineage_rows,
    ))
    concepts.extend(_build_sign_flip_concepts(
        source_code, sanitized, scopes, cte_ranges,
    ))
    concepts.extend(_build_dim_lookup_concepts(
        source_code, sanitized, scopes, cte_ranges, ux_index,
    ))
    concepts.extend(_build_filter_block_concepts(
        source_code, sanitized, cte_ranges,
    ))
    concepts.extend(_build_pair_group_concepts(columns))

    out = {
        "object_fqn": f"main.{schema}.{obj_name}",
        "generated_at": _now_iso(),
        "concept_count": len(concepts),
        "concepts": concepts,
        "source": source_path,
    }
    return _write(out, schema_root, obj_name)


def _write(data: dict, schema_root: Path, obj_name: str) -> dict:
    out_dir = schema_root / "_discovery" / "concepts"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{obj_name}.json"
    out_path.write_text(json.dumps(data, indent=2, ensure_ascii=False),
                          encoding="utf-8")
    return {
        "obj": obj_name,
        "wrote": str(out_path.relative_to(REPO)),
        "concept_count": data.get("concept_count", 0),
    }


def _enumerate_targets(schema: str, obj_arg: str | None) -> list[str]:
    if obj_arg:
        return [obj_arg]
    schema_root = OBJ_OUT_ROOT / schema
    inv = _read_inventory(schema_root)
    return [o["name"] for o in inv.get("objects", []) if o.get("in_scope")]


def main() -> int:
    ap = argparse.ArgumentParser(description="Phase 4.5 — Concept Discovery")
    ap.add_argument("--schema", required=True)
    ap.add_argument("--object", default=None,
                    help="Optional: single object (default: all in-scope)")
    ap.add_argument("--force", action="store_true",
                    help="Regenerate even if concepts.json exists")
    args = ap.parse_args()

    schema_root = OBJ_OUT_ROOT / args.schema
    if not schema_root.is_dir():
        print(f"ERROR: schema folder not found: {schema_root}", file=sys.stderr)
        return 2

    targets = _enumerate_targets(args.schema, args.object)
    if not targets:
        print(f"[discover-concepts] no in-scope objects in {schema_root}",
              file=sys.stderr)
        return 0

    print(f"[discover-concepts] {args.schema}: {len(targets)} object(s)",
          file=sys.stderr)
    errors = 0
    for name in targets:
        out_path = schema_root / "_discovery" / "concepts" / f"{name}.json"
        if out_path.exists() and not args.force:
            try:
                d = json.loads(out_path.read_text(encoding="utf-8"))
                print(f"  [SKIP] {name} — concept_count={d.get('concept_count', 0)} (use --force)",
                      file=sys.stderr)
                continue
            except Exception:
                pass
        try:
            r = discover_for_object(args.schema, name)
            print(f"  [OK] {name} — concept_count={r['concept_count']}",
                  file=sys.stderr)
        except Exception as e:
            errors += 1
            print(f"  [FAIL] {name} — {e}", file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr, flush=True)
        sys.exit(1)
