"""One-shot debugger: trace the walker through ClosedOnDate to see exactly
which subquery `_deepen` lands in and why it returns 0."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from sqlglot import expressions as exp  # noqa: E402

from tools.desc_quality.sql_walker import (  # noqa: E402
    _alias_map,
    _collect_cte_map,
    _extract_fn_inner,
    _parse,
    _project_inner,
    _project_name,
    _classify,
    _column_args_in,
)


SQL_PATH = Path(
    "C:/Users/guyman/Documents/github/DataPlatform/SynapseSQLPool1/sql_dp_prod_we/"
    "BI_DB_dbo/Functions/BI_DB_dbo.Function_PnL_Single_Day.sql"
)


def main() -> None:
    text = SQL_PATH.read_text(encoding="utf-8", errors="ignore")
    inner = _extract_fn_inner(text)
    root = _parse(inner)
    if isinstance(root, exp.With):
        root = root.this
    cte_map = _collect_cte_map(root)
    print(f"CTE keys: {list(cte_map.keys())}")

    # Walk every SELECT that projects "ClosedOnDate" and report:
    #  - what the projection expression is
    #  - what its FROM/JOIN alias map looks like
    print("\nAll SELECTs that project ClosedOnDate:\n")
    for i, sel in enumerate(root.find_all(exp.Select)):
        for proj in sel.expressions or []:
            name = _project_name(proj)
            if name.lower() != "closedondate":
                continue
            inner_expr = _project_inner(proj)
            kind = _classify(inner_expr)
            try:
                expr_sql = inner_expr.sql(dialect="tsql")
            except Exception:
                expr_sql = str(inner_expr)
            print(f"  SELECT #{i}: ClosedOnDate = {expr_sql!r} (kind={kind})")
            am = _alias_map(sel)
            print(f"    FROM alias_map keys = {list(am.keys())}")
            joins = sel.args.get("joins") or []
            join_aliases = [
                (j.this.alias_or_name if hasattr(j.this, "alias_or_name") else "?")
                for j in joins
            ]
            print(f"    JOIN aliases       = {join_aliases}")
            break

    # Now demonstrate the bug: take the b-level SELECT whose projection is
    # `ISNULL(dp.ClosedOnDate, 0)` and show whether _alias_map captures `dp`.
    print("\nLooking specifically for the SELECT with ISNULL(dp.ClosedOnDate, 0):\n")
    for sel in root.find_all(exp.Select):
        for proj in sel.expressions or []:
            if _project_name(proj).lower() != "closedondate":
                continue
            inner_expr = _project_inner(proj)
            if _classify(inner_expr) != "coalesce":
                continue
            am = _alias_map(sel)
            print(f"  alias_map keys: {list(am.keys())}")
            cols = _column_args_in(inner_expr)
            for c in cols:
                a = (c.table or "").lower()
                print(f"  col arg: alias={a!r} name={c.name!r}  alias_in_map={a in am}")
                if a and a in am:
                    src = am[a]
                    print(f"     -> src kind: {type(src).__name__}")
            break


if __name__ == "__main__":
    main()
