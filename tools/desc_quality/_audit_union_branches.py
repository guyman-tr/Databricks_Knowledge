"""G1 audit: for every SQL-derived row in the latest proposed_fixes.csv,
enumerate all UNION branches in the source SQL and walk each one independently
for the target column. Flag any column whose branches disagree on the terminal
expression — that's where the current single-branch report is misleading.

Usage:
    python tools/desc_quality/_audit_union_branches.py \
        --fixes audits/_desc_quality_rewrite_corpus8/proposed_fixes.csv

Pure read-only. Writes a report next to the input CSV.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from dataclasses import dataclass
from pathlib import Path

# Make sibling-module imports work when run as a script.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from sqlglot import expressions as exp  # noqa: E402

from tools.desc_quality.sql_walker import (  # noqa: E402
    _classify,
    _collect_cte_map,
    _extract_fn_inner,
    _extract_view_inner,
    _flatten_union,
    _parse,
    _project_inner,
    _project_name,
    _walk,
)
from tools.cleanup_tier1.sql_locator import locate_sql  # noqa: E402


_REPO_ROOT = Path(__file__).resolve().parent.parent.parent

# Match lines of the form:
#   ... (sql-derived [case] from Function_PnL_Single_Day); where cpt = ...
SQL_DERIVED_RE = re.compile(r"\(sql-derived \[(?P<kind>[^\]]+)\] from (?P<obj>[^)]+)\)")


@dataclass
class BranchResult:
    branch_index: int
    terminal_expr: str
    kind: str
    source_object: str


@dataclass
class AuditFinding:
    wiki_path: str
    column: str
    sql_file: str
    proposed_kind: str
    proposed_object: str
    branches: list[BranchResult]
    divergent: bool
    note: str = ""


def _wiki_to_sql_path(wiki_rel_path: str) -> tuple[Path | None, str]:
    """Wrapper around locate_sql that returns (sql_path, object_kind) or (None, '')."""
    wp = (_REPO_ROOT / wiki_rel_path).resolve()
    if not wp.exists():
        return None, ""
    loc = locate_sql(wp)
    if not loc.sql_paths:
        return None, ""
    return loc.sql_paths[0], loc.object_kind


def _walk_branch_for_column(
    branch: exp.Select,
    cte_map: dict[str, exp.Expression],
    column: str,
) -> tuple[str, str, str]:
    """Walk a single SELECT branch for `column`. Returns (expr_sql, kind, src_obj).

    For a branch that doesn't produce the column at all, returns ("", "not_found", "").
    """
    chain: list[tuple[int, str, str]] = []
    aliases_out: dict[str, str] = {}
    return _walk(branch, column, cte_map, chain, 0, max_depth=15, aliases_out=aliases_out)


def _enumerate_branches(sql_text: str, kind: str) -> list[exp.Select]:
    """Strip the function/view shell, parse, and return all top-level UNION
    branches. For non-UNION queries returns a single-element list."""
    if kind == "function":
        inner = _extract_fn_inner(sql_text)
    elif kind == "view":
        inner = _extract_view_inner(sql_text)
    else:
        return []
    if inner is None:
        return []
    root = _parse(inner)
    if root is None:
        return []
    if isinstance(root, exp.With):
        root = root.this
    return _flatten_union(root)


def _normalise_expr(expr_text: str) -> str:
    """Cheap normaliser so we can compare branch outputs. Strips whitespace and
    collapses internal runs of whitespace; case-sensitive (SQL keywords are
    already uppercased by sqlglot)."""
    return " ".join(expr_text.split()).strip()


def audit_one_row(
    wiki_rel_path: str,
    column: str,
    proposed_kind: str,
    proposed_object: str,
) -> AuditFinding:
    sql_path, object_kind = _wiki_to_sql_path(wiki_rel_path)
    if sql_path is None:
        return AuditFinding(
            wiki_path=wiki_rel_path,
            column=column,
            sql_file="(not found)",
            proposed_kind=proposed_kind,
            proposed_object=proposed_object,
            branches=[],
            divergent=False,
            note="sql_path_not_resolved",
        )

    sql_text = sql_path.read_text(encoding="utf-8", errors="ignore")
    branches = _enumerate_branches(sql_text, object_kind)
    if not branches:
        return AuditFinding(
            wiki_path=wiki_rel_path,
            column=column,
            sql_file=str(sql_path.relative_to(_REPO_ROOT)).replace("\\", "/")
            if sql_path.is_relative_to(_REPO_ROOT)
            else str(sql_path),
            proposed_kind=proposed_kind,
            proposed_object=proposed_object,
            branches=[],
            divergent=False,
            note="no_branches_parsed",
        )

    # Build a CTE map from the full parsed tree (not just one branch) so that
    # walks into CTEs work regardless of which branch they live in.
    inner = (
        _extract_fn_inner(sql_text) if object_kind == "function"
        else _extract_view_inner(sql_text)
    )
    root = _parse(inner) if inner else None
    cte_map: dict[str, exp.Expression] = {}
    if root is not None:
        cte_map = _collect_cte_map(root)

    results: list[BranchResult] = []
    for idx, branch in enumerate(branches):
        tx, kind, src = _walk_branch_for_column(branch, cte_map, column)
        results.append(
            BranchResult(
                branch_index=idx,
                terminal_expr=tx,
                kind=kind,
                source_object=src,
            )
        )

    # Divergence test: any two non-empty branches with different normalised
    # terminal text count as divergent. "not_found" branches are ignored
    # (column may legitimately not exist in that branch — e.g., a UNION
    # branch with `NULL AS ColX`).
    seen: set[str] = set()
    real_kinds: set[str] = set()
    for r in results:
        if r.kind == "not_found" or not r.terminal_expr:
            continue
        seen.add(_normalise_expr(r.terminal_expr))
        real_kinds.add(r.kind)
    divergent = len(seen) > 1

    return AuditFinding(
        wiki_path=wiki_rel_path,
        column=column,
        sql_file=str(sql_path.relative_to(_REPO_ROOT)).replace("\\", "/")
        if sql_path.is_relative_to(_REPO_ROOT)
        else str(sql_path),
        proposed_kind=proposed_kind,
        proposed_object=proposed_object,
        branches=results,
        divergent=divergent,
        note=f"{len(branches)} branches; {len(seen)} distinct terminals; kinds={sorted(real_kinds)}",
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--fixes", required=True, help="Path to proposed_fixes.csv")
    ap.add_argument("--out", default=None, help="Output report path (default: next to --fixes)")
    args = ap.parse_args()

    fixes_path = (_REPO_ROOT / args.fixes).resolve() if not Path(args.fixes).is_absolute() else Path(args.fixes)
    if not fixes_path.exists():
        print(f"Fixes file not found: {fixes_path}", file=sys.stderr)
        return 2

    out_path = (
        Path(args.out).resolve() if args.out
        else fixes_path.parent / "union_branch_audit.md"
    )

    findings: list[AuditFinding] = []
    with fixes_path.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            new_desc = row.get("new_description", "")
            m = SQL_DERIVED_RE.search(new_desc)
            if not m:
                continue
            finding = audit_one_row(
                wiki_rel_path=row["wiki_path"],
                column=row["column"],
                proposed_kind=m.group("kind"),
                proposed_object=m.group("obj"),
            )
            findings.append(finding)

    if not findings:
        print("No SQL-derived rows found in fixes CSV.")
        return 0

    lines: list[str] = []
    lines.append("# UNION Branch Audit\n")
    lines.append(f"Source: `{fixes_path.relative_to(_REPO_ROOT)}`\n")
    lines.append(f"SQL-derived rows audited: {len(findings)}\n")
    divergent_count = sum(1 for f in findings if f.divergent)
    lines.append(f"Divergent (branches disagree): **{divergent_count}**\n")
    lines.append("")

    for f in findings:
        tag = "DIVERGENT" if f.divergent else "uniform"
        lines.append(f"## [{tag}] {f.wiki_path} :: `{f.column}`\n")
        lines.append(f"- SQL file: `{f.sql_file}`")
        lines.append(f"- Proposed: kind=`{f.proposed_kind}` object=`{f.proposed_object}`")
        lines.append(f"- {f.note}")
        if f.branches:
            lines.append("")
            lines.append("| Branch | Kind | Terminal expression |")
            lines.append("|--------|------|---------------------|")
            for b in f.branches:
                expr_safe = (b.terminal_expr or "").replace("|", "\\|").replace("\n", " ")
                if len(expr_safe) > 180:
                    expr_safe = expr_safe[:177] + "..."
                lines.append(f"| {b.branch_index} | {b.kind} | `{expr_safe}` |")
        lines.append("")

    out_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote: {out_path}")
    print(f"  SQL-derived rows: {len(findings)}")
    print(f"  Divergent: {divergent_count}")
    print()
    for f in findings:
        tag = "DIVERGENT" if f.divergent else "uniform"
        print(f"  [{tag}] {f.column}  ({Path(f.wiki_path).name})  -- {f.note}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
