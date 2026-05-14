"""Sync column comments between pii_data.<X> and main.{dwh,bi_db}.<X>_masked.

Wiki authors target one side or the other (some target masked, some target pii)
when writing ALTER scripts. The other side ends up empty. This tool copies
column comments from whichever side has them to the side that doesn't, so the
sibling tables stay in parity.

Behaviour per column:
  - both empty     -> no-op
  - one has, other empty -> ALTER the empty side using the populated comment
  - both have, same value -> no-op
  - both have, different  -> log as CONFLICT, no-op (caller decides)

Output:
  knowledge/_sync_pii_masked.sql           generated ALTER statements
  knowledge/_sync_pii_masked_report.csv    per-statement run report
  knowledge/_sync_pii_masked_conflicts.csv mismatched comments not auto-resolved

Usage:
  python tools/sync_pii_masked_comments.py                    # dry-run
  python tools/sync_pii_masked_comments.py --apply            # execute against UC
  python tools/sync_pii_masked_comments.py --tables a b c     # restrict to these masked-name short tables
"""
from __future__ import annotations

import argparse
import csv
import os
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
OUT_SQL = REPO / "knowledge" / "_sync_pii_masked.sql"
REPORT_CSV = REPO / "knowledge" / "_sync_pii_masked_report.csv"
CONFLICTS_CSV = REPO / "knowledge" / "_sync_pii_masked_conflicts.csv"


def _connect():
    try:
        from databricks import sql  # type: ignore
    except ImportError:
        print("ERROR: databricks-sql-connector not installed.", file=sys.stderr)
        return None
    host = os.environ.get(
        "DATABRICKS_SERVER_HOSTNAME",
        "adb-5142916747090026.6.azuredatabricks.net",
    )
    http_path = os.environ.get(
        "DATABRICKS_HTTP_PATH", "/sql/1.0/warehouses/208214768b0e0308"
    )
    token = (os.environ.get("DATABRICKS_TOKEN") or "").strip()
    if token:
        print("Auth: PAT (DATABRICKS_TOKEN)", flush=True)
        return sql.connect(
            server_hostname=host, http_path=http_path, access_token=token,
        )
    print("Auth: databricks-oauth (browser)", flush=True)
    return sql.connect(
        server_hostname=host, http_path=http_path,
        auth_type="databricks-oauth",
    )


def _sql_escape(s: str) -> str:
    return s.replace("'", "''")


def discover_pairs(cur, restrict: set[str] | None) -> list[dict]:
    """Find every (masked, pii) sibling pair in UC. The pii_data variant has the
    same table_name as the masked variant minus the `_masked` suffix."""
    cur.execute(
        """
        WITH masked AS (
            SELECT table_schema, table_name AS masked_name,
                   REPLACE(table_name, '_masked', '') AS base_name
            FROM main.information_schema.tables
            WHERE table_catalog = 'main'
              AND table_schema IN ('dwh','bi_db')
              AND table_name LIKE '%_masked'
        ),
        pii AS (
            SELECT table_name AS pii_name
            FROM main.information_schema.tables
            WHERE table_catalog = 'main' AND table_schema = 'pii_data'
        )
        SELECT m.table_schema AS masked_schema, m.masked_name, m.base_name,
               p.pii_name
        FROM masked m JOIN pii p ON m.base_name = p.pii_name
        ORDER BY m.masked_name
        """
    )
    rows = []
    for r in cur.fetchall():
        masked_schema = r[0]
        masked_name = r[1]
        base = r[2]
        pii_name = r[3]
        if restrict and base not in restrict and masked_name not in restrict:
            continue
        rows.append({
            "masked_table": f"main.{masked_schema}.{masked_name}",
            "pii_table": f"main.pii_data.{pii_name}",
            "base_name": base,
        })
    return rows


def fetch_column_comments(cur, full_table: str) -> dict[str, str]:
    catalog, schema, name = full_table.split(".")
    cur.execute(
        """
        SELECT column_name, COALESCE(comment, '') AS comment
        FROM main.information_schema.columns
        WHERE table_catalog = %(c)s AND table_schema = %(s)s
          AND table_name = %(t)s
        """,
        {"c": catalog, "s": schema, "t": name},
    )
    return {r[0]: (r[1] or "").strip() for r in cur.fetchall()}


def plan_for_pair(pair: dict, masked_cols: dict[str, str],
                  pii_cols: dict[str, str],
                  ) -> tuple[list[tuple[str, str, str, str]], list[dict]]:
    """Return (statements, conflicts).
    statements: list of (target_table, column, source_comment, direction).
    conflicts: list of {pair, column, masked_comment, pii_comment}.
    """
    statements = []
    conflicts = []
    all_cols = set(masked_cols) | set(pii_cols)
    for col in sorted(all_cols):
        m = masked_cols.get(col, "")
        p = pii_cols.get(col, "")
        if not m and not p:
            continue
        if m and p:
            if m == p:
                continue
            conflicts.append({
                "masked_table": pair["masked_table"],
                "pii_table": pair["pii_table"],
                "column": col,
                "masked_comment": m,
                "pii_comment": p,
            })
            continue
        if m and not p:
            statements.append((pair["pii_table"], col, m, "masked->pii"))
        elif p and not m:
            statements.append((pair["masked_table"], col, p, "pii->masked"))
    return statements, conflicts


def build_alter(target: str, column: str, comment: str) -> str:
    return (f"ALTER TABLE {target} ALTER COLUMN `{column}` "
            f"COMMENT '{_sql_escape(comment)}';")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--tables", nargs="*", default=None,
                    help="Restrict to these base/masked table names.")
    ap.add_argument("--apply", action="store_true",
                    help="Execute against UC. Without this flag, only emit "
                         "the SQL file and report what would change.")
    args = ap.parse_args()

    conn = _connect()
    if conn is None:
        return 3
    cur = conn.cursor()

    restrict = set(args.tables) if args.tables else None
    pairs = discover_pairs(cur, restrict)
    print(f"Discovered {len(pairs)} (masked, pii) sibling pair(s).")

    all_statements: list[tuple[str, str, str, str, str]] = []
    all_conflicts: list[dict] = []
    for pair in pairs:
        m = fetch_column_comments(cur, pair["masked_table"])
        p = fetch_column_comments(cur, pair["pii_table"])
        stmts, conflicts = plan_for_pair(pair, m, p)
        for s in stmts:
            all_statements.append((pair["base_name"], *s))
        all_conflicts.extend(conflicts)
        if stmts or conflicts:
            empty_pii = sum(1 for s in stmts if s[3] == "masked->pii")
            empty_masked = sum(1 for s in stmts if s[3] == "pii->masked")
            print(f"  {pair['base_name']:<70}  masked->pii={empty_pii:<3}  "
                  f"pii->masked={empty_masked:<3}  conflicts={len(conflicts)}")

    print()
    print(f"Total ALTER statements queued: {len(all_statements)}")
    print(f"Total conflicts (skipped):     {len(all_conflicts)}")

    sql_lines = [
        "-- =============================================================================",
        "-- Sync pii_data.<X> and main.{dwh,bi_db}.<X>_masked column comments.",
        "-- Generated by tools/sync_pii_masked_comments.py.",
        "-- =============================================================================",
        "",
    ]
    for base, target, col, comment, direction in all_statements:
        sql_lines.append(f"-- {base}  [{direction}]")
        sql_lines.append(build_alter(target, col, comment))
    OUT_SQL.parent.mkdir(parents=True, exist_ok=True)
    OUT_SQL.write_text("\n".join(sql_lines) + "\n", encoding="utf-8")
    print(f"Wrote {OUT_SQL.relative_to(REPO)}")

    if all_conflicts:
        with CONFLICTS_CSV.open("w", encoding="utf-8", newline="") as f:
            w = csv.DictWriter(f, fieldnames=[
                "masked_table", "pii_table", "column",
                "masked_comment", "pii_comment",
            ])
            w.writeheader()
            for c in all_conflicts:
                w.writerow(c)
        print(f"Wrote {CONFLICTS_CSV.relative_to(REPO)}")

    if not args.apply:
        print()
        print("DRY-RUN. Re-run with --apply to execute against UC.")
        cur.close()
        conn.close()
        return 0

    REPORT_CSV.parent.mkdir(parents=True, exist_ok=True)
    ok = fail = 0
    with REPORT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=[
            "idx", "base", "target_table", "column", "direction",
            "status", "error",
        ])
        w.writeheader()
        for idx, (base, target, col, comment, direction) in enumerate(
            all_statements, start=1,
        ):
            stmt = build_alter(target, col, comment).rstrip(";")
            try:
                cur.execute(stmt)
                status = "OK"
                error = ""
                ok += 1
            except Exception as e:  # noqa: BLE001
                status = "FAIL"
                error = str(e)[:500]
                fail += 1
            w.writerow({
                "idx": idx, "base": base, "target_table": target,
                "column": col, "direction": direction,
                "status": status, "error": error,
            })
            if idx % 50 == 0 or status == "FAIL":
                msg = f"  [{idx}/{len(all_statements)}] {status} {target}.{col}"
                if error:
                    msg += f" -- {error[:120]}"
                print(msg, flush=True)
    cur.close()
    conn.close()
    print()
    print(f"DONE  OK={ok}  FAIL={fail}")
    print(f"Wrote {REPORT_CSV.relative_to(REPO)}")
    return 0 if fail == 0 else 4


if __name__ == "__main__":
    sys.exit(main())
