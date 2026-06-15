#!/usr/bin/env python3
"""
Phase 4.6 — Computation Formula Extraction (UC-Pipeline pack).

For every column in `uc_inventory.json`, mine the cached view DDL / notebook
source code and emit a structured formula lookup that Phase 5 will assemble
into Tier-2 §4 Elements descriptions.

For each column emits:
  - `column`         : the target column name
  - `formula`        : predicate-explicit, alias-resolved expression
                       (e.g. `CASE WHEN TxTypeID IN (5) THEN 33 ELSE 0`)
  - `expression_raw` : the original SELECT-list expression text (alias-prefixed)
  - `inputs`         : list of physical UC FQNs the expression reads from
                       (or `["literal"]` for pure literals)
  - `transform_kind` : passthrough | rename | cast | case_flag | coalesce |
                       arithmetic | literal | function | unknown
  - `evidence_lines` : source-file line range

Same alias-level attribution rule as DWH Phase 9: source = SELECT-list alias
prefix resolved via enclosing scope's alias map. JOIN clauses are NOT bled
into other columns' attribution.

Output: `_discovery/formulas/{Object}.json` — see `04.6-formula-extraction.mdc`.

Usage:
  python tools/uc_pipelines/extract_formulas.py --schema etoro_kpi_prep --object v_mimo_emoneyplatform
  python tools/uc_pipelines/extract_formulas.py --schema etoro_kpi_prep
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "tools" / "uc_pipelines"))

from generate_wiki import (  # noqa: E402
    _strip_sql_comments_and_strings,
    _parse_scopes,
    _find_column_expression_lines,
    _scope_for_line,
    _resolve_terminal_upstreams,
    _snippet_has_column_refs,
    OBJ_OUT_ROOT,
)


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


def _read_lineage_by_col(schema: str, obj_name: str) -> dict[str, dict]:
    from generate_wiki import _parse_lineage_rows
    schema_root = OBJ_OUT_ROOT / schema
    for folder in ("Tables", "Views"):
        lp = schema_root / folder / f"{obj_name}.lineage.md"
        if lp.exists():
            rows = _parse_lineage_rows(lp.read_text(encoding="utf-8"))
            return {r["name"].lower(): r for r in rows}
    return {}


# ---------------------------------------------------------------------------
# Formula normalization
# ---------------------------------------------------------------------------

_ALIAS_PREFIX_RE = re.compile(r"\b([A-Za-z_][A-Za-z0-9_]*)\.([A-Za-z_])")


def _strip_trailing_as(expr: str) -> str:
    """Strip trailing `AS <alias>` from a SELECT-list expression. Used to
    isolate the transformation logic from the bound name."""
    expr = expr.strip()
    # Strip from rightmost ` AS <ident>` to end-of-string.
    m = re.search(r"\bAS\s+`?[A-Za-z_][A-Za-z0-9_]*`?\s*$", expr, re.IGNORECASE)
    if m:
        expr = expr[: m.start()].rstrip()
    return expr


def _strip_alias_prefixes(expr: str, known_aliases: set[str]) -> str:
    """Strip `alias.` prefix from identifier references when the alias is in
    `known_aliases`. Leaves unknown qualifiers intact (e.g. function-qualified
    calls or column names that happen to start with letters)."""
    def repl(m: re.Match) -> str:
        alias = m.group(1)
        nxt = m.group(2)
        if alias in known_aliases:
            return nxt
        return m.group(0)
    return _ALIAS_PREFIX_RE.sub(repl, expr)


def _normalize_whitespace(expr: str) -> str:
    expr = re.sub(r"\s+", " ", expr.strip())
    return expr.rstrip(",")


def _classify_transform_kind(expr: str) -> str:
    upper = expr.upper()
    if not expr.strip():
        return "unknown"
    stripped = expr.strip()
    # Pure quoted-string literal: starts and ends with a quote, with no
    # extra characters after the closing quote (e.g. `'Deposit'`).
    if re.match(r"^'[^']*'$", stripped) or re.match(r'^"[^"]*"$', stripped):
        return "literal"
    # Pure numeric literal: optional sign, digits, optional decimal.
    if re.match(r"^-?\d+(?:\.\d+)?$", stripped):
        return "literal"
    # NULL keyword (case-insensitive).
    if stripped.upper() == "NULL":
        return "literal"
    # Pure literal: starts with digit / quote / function like CURRENT_*()
    if (stripped.startswith(("'", '"'))
            or stripped[:1].isdigit()
            or stripped[:2] in ("-1", "-2", "-3", "-4", "-5", "-6", "-7", "-8", "-9")):
        if not re.search(r"[A-Za-z_][A-Za-z0-9_]*\.[A-Za-z_]", expr):
            # Truly literal (no col.col refs anywhere)
            if not _snippet_has_column_refs(expr):
                return "literal"
    # CURRENT_TIMESTAMP() / NOW() / GETDATE() etc.
    if re.match(r"^(CURRENT_TIMESTAMP|CURRENT_DATE|NOW|GETDATE|SYSDATE)\s*\(", upper):
        return "literal"
    # CASE flag
    if "CASE" in upper and "WHEN" in upper:
        return "case_flag"
    # COALESCE / IFNULL / NVL / ISNULL
    if re.match(r"^(COALESCE|IFNULL|NVL|ISNULL|NULLIF)\s*\(", upper):
        return "coalesce"
    # CAST / TRY_CAST
    if re.match(r"^(CAST|TRY_CAST)\s*\(", upper):
        return "cast"
    # Aggregates
    if re.match(r"^(SUM|COUNT|AVG|MIN|MAX|FIRST|LAST)\s*\(", upper):
        return "aggregate"
    # Window functions (LAG/LEAD/ROW_NUMBER/etc with OVER)
    if "OVER" in upper and re.search(r"\b(LAG|LEAD|ROW_NUMBER|RANK|DENSE_RANK|FIRST_VALUE|LAST_VALUE)\s*\(", upper):
        return "window"
    # Arithmetic if expression contains operators
    if re.search(r"[+\-*/]", expr) and re.search(r"[A-Za-z_]", expr):
        return "arithmetic"
    # Bare identifier — passthrough or rename
    if re.match(r"^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)?$", stripped):
        return "passthrough"
    # Function call default
    if re.match(r"^[A-Za-z_]\w*\s*\(", stripped):
        return "function"
    return "unknown"


# ---------------------------------------------------------------------------
# Per-column extraction
# ---------------------------------------------------------------------------

def _extract_formula_for_column(
    target_column: str,
    source_code: str,
    scopes: dict[str, dict[str, str]],
    cte_ranges: list[tuple[str, int, int]],
) -> dict | None:
    loc = _find_column_expression_lines(source_code, target_column)
    if not loc:
        return None
    start_line, end_line, snippet = loc
    expression_raw = snippet.strip()
    # Strip the AS-binding for the canonical formula text.
    expr_no_as = _strip_trailing_as(expression_raw)
    scope = _scope_for_line(end_line, source_code, cte_ranges)
    known_aliases = set(scopes.get(scope, {}).keys()) | {"main"}
    formula_text = _strip_alias_prefixes(expr_no_as, known_aliases)
    formula_text = _normalize_whitespace(formula_text)
    inputs = _resolve_terminal_upstreams(expr_no_as, scope, scopes)
    transform_kind = _classify_transform_kind(formula_text)
    if transform_kind == "literal":
        inputs = ["literal"]
    if not inputs and transform_kind in ("passthrough", "arithmetic", "coalesce", "cast", "case_flag"):
        # Fall back: no aliased upstream resolvable from snippet itself.
        # This happens for bare column refs inside CTEs (e.g.
        # `COALESCE(TransactionID, -1)` in the outer SELECT, where
        # `TransactionID` is a column the CTE projected up).
        inputs = ["computed in source"]
    # Trim formula if extremely long (200 chars max for the lookup).
    if len(formula_text) > 200:
        formula_text = formula_text[:200] + "…"
    return {
        "column": target_column,
        "formula": formula_text,
        "expression_raw": expression_raw,
        "inputs": inputs,
        "transform_kind": transform_kind,
        "evidence_lines": f"L{start_line}-L{end_line}",
        "scope": scope,
    }


def extract_for_object(schema: str, obj_name: str) -> dict:
    schema_root = OBJ_OUT_ROOT / schema
    if not schema_root.is_dir():
        raise RuntimeError(f"schema folder not found: {schema_root}")
    inv = _read_inventory(schema_root)
    inv_obj = next((o for o in inv.get("objects", []) if o["name"] == obj_name), None)
    if not inv_obj:
        raise RuntimeError(f"object {obj_name} not found in uc_inventory.json")
    columns = inv_obj.get("columns") or []
    source_code, source_path = _read_source(schema_root, obj_name)

    formulas: list[dict] = []
    if not source_code:
        for col in columns:
            formulas.append({
                "column": col["name"],
                "formula": None,
                "expression_raw": None,
                "inputs": [],
                "transform_kind": "unknown",
                "evidence_lines": None,
                "reason": "no source code cached",
            })
    else:
        scopes, cte_ranges = _parse_scopes(source_code)
        lineage_by_col = _read_lineage_by_col(schema, obj_name)
        for col in columns:
            cname = col["name"]
            f = _extract_formula_for_column(cname, source_code, scopes, cte_ranges)
            if f is None:
                # Fall back to lineage row if present.
                lin = lineage_by_col.get(cname.lower())
                if lin:
                    src = lin.get("source_object") or ""
                    src_col = lin.get("source_column") or cname
                    formulas.append({
                        "column": cname,
                        "formula": None,
                        "expression_raw": None,
                        "inputs": [src] if src and src not in ("—", "(literal)", "(computed)") else [],
                        "transform_kind": lin.get("transform") or "unknown",
                        "evidence_lines": None,
                        "reason": "expression not locatable in source; fell back to lineage row",
                        "fallback_source_column": src_col,
                    })
                else:
                    formulas.append({
                        "column": cname,
                        "formula": None,
                        "expression_raw": None,
                        "inputs": [],
                        "transform_kind": "unknown",
                        "evidence_lines": None,
                        "reason": "expression not locatable AND no lineage row",
                    })
            else:
                formulas.append(f)

    out = {
        "object_fqn": f"main.{schema}.{obj_name}",
        "generated_at": _now_iso(),
        "formula_count": len(formulas),
        "formulas": formulas,
        "source": source_path,
    }
    out_dir = schema_root / "_discovery" / "formulas"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{obj_name}.json"
    out_path.write_text(json.dumps(out, indent=2, ensure_ascii=False),
                          encoding="utf-8")
    n_with_formula = sum(1 for f in formulas if f.get("formula"))
    return {
        "obj": obj_name,
        "wrote": str(out_path.relative_to(REPO)),
        "formula_count": len(formulas),
        "n_with_formula": n_with_formula,
    }


def _enumerate_targets(schema: str, obj_arg: str | None) -> list[str]:
    if obj_arg:
        return [obj_arg]
    schema_root = OBJ_OUT_ROOT / schema
    inv = _read_inventory(schema_root)
    return [o["name"] for o in inv.get("objects", []) if o.get("in_scope")]


def main() -> int:
    ap = argparse.ArgumentParser(description="Phase 4.6 — Formula Extraction")
    ap.add_argument("--schema", required=True)
    ap.add_argument("--object", default=None,
                    help="Optional: single object (default: all in-scope)")
    ap.add_argument("--force", action="store_true",
                    help="Regenerate even if formulas.json exists")
    args = ap.parse_args()

    schema_root = OBJ_OUT_ROOT / args.schema
    if not schema_root.is_dir():
        print(f"ERROR: schema folder not found: {schema_root}", file=sys.stderr)
        return 2

    targets = _enumerate_targets(args.schema, args.object)
    if not targets:
        print(f"[extract-formulas] no in-scope objects in {schema_root}",
              file=sys.stderr)
        return 0

    print(f"[extract-formulas] {args.schema}: {len(targets)} object(s)",
          file=sys.stderr)
    errors = 0
    for name in targets:
        out_path = schema_root / "_discovery" / "formulas" / f"{name}.json"
        if out_path.exists() and not args.force:
            try:
                d = json.loads(out_path.read_text(encoding="utf-8"))
                print(f"  [SKIP] {name} — formula_count={d.get('formula_count', 0)} (use --force)",
                      file=sys.stderr)
                continue
            except Exception:
                pass
        try:
            r = extract_for_object(args.schema, name)
            print(f"  [OK] {name} — {r['n_with_formula']}/{r['formula_count']} formulas",
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
