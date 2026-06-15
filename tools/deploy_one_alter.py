"""Targeted single-file ALTER deployer.

Use when you have ONE or two specific .alter.sql files that drifted in UC
(e.g. the 2026-05-03 tier-token leak on BI_DB_First5Actions /
BI_DB_IFRS15_Daily_Balance) and you want a surgical re-deploy without
involving the whole `_deploy-index.md` resume machinery.

Behaviour:
 1. Validate each .alter.sql via tools/uc_comment_validator (refuses to run
    if any column comment still smells like a Tier-token / header-label
    drift).
 2. Open ONE databricks.sql session (PAT if `DATABRICKS_TOKEN` set, else
    databricks-oauth — single browser tab).
 3. For each file: parse statements, run them in order, count ok/fail.
 4. Print summary per file + grand total.

Usage:
  python tools/deploy_one_alter.py path/to/X.alter.sql [path/to/Y.alter.sql ...]
"""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))

from uc_comment_validator import validate_alter_sql

_STMT_STARTS = ("ALTER TABLE", "ALTER VIEW", "COMMENT ON")


def _is_stmt_start(line: str) -> bool:
    s = line.strip().upper()
    return any(s.startswith(p) for p in _STMT_STARTS)


def _strip_footer(raw: str) -> str:
    return re.sub(
        r"\n*-- == LAST EXECUTION ==.*?-- ====================",
        "",
        raw,
        flags=re.DOTALL,
    ).rstrip()


def parse_statements(content: str) -> list[str]:
    content = _strip_footer(content)
    statements: list[str] = []
    current: list[str] = []
    for line in content.splitlines():
        if _is_stmt_start(line):
            if current:
                statements.append("\n".join(current).strip())
            current = [line]
        elif current:
            current.append(line)
            if line.rstrip().endswith(";"):
                statements.append("\n".join(current).strip())
                current = []
    if current:
        statements.append("\n".join(current).strip())
    return [s for s in statements if s]


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2

    paths = [Path(p).resolve() for p in sys.argv[1:]]
    for p in paths:
        if not p.is_file():
            print(f"NOT FOUND: {p}", file=sys.stderr)
            return 2

    print(f"--- pre-flight validation ({len(paths)} files) ---", flush=True)
    any_bad = False
    for p in paths:
        txt = p.read_text(encoding="utf-8")
        probs = validate_alter_sql(txt, source=str(p))
        if probs:
            any_bad = True
            print(f"FAIL {p.name}: {len(probs)} bad comments", flush=True)
            for x in probs[:5]:
                print(f"   {x}", flush=True)
        else:
            print(f"OK   {p.name}", flush=True)
    if any_bad:
        print("Aborting — fix bad comments first.", flush=True)
        return 1

    print("--- connecting to Databricks ---", flush=True)
    from databricks import sql

    host = os.environ.get(
        "DATABRICKS_SERVER_HOSTNAME", "adb-5142916747090026.6.azuredatabricks.net"
    )
    http_path = os.environ.get(
        "DATABRICKS_HTTP_PATH", "/sql/1.0/warehouses/208214768b0e0308"
    )
    token = (os.environ.get("DATABRICKS_TOKEN") or "").strip()

    if token:
        print("Auth: PAT (DATABRICKS_TOKEN)", flush=True)
        conn = sql.connect(server_hostname=host, http_path=http_path, access_token=token)
    else:
        print("Auth: databricks-oauth (browser may open)", flush=True)
        conn = sql.connect(
            server_hostname=host, http_path=http_path, auth_type="databricks-oauth"
        )
    cur = conn.cursor()

    grand_ok = grand_fail = 0
    failures: list[tuple[str, str, str]] = []  # (file, stmt_head, error)

    for p in paths:
        print(f"\n--- deploying {p.name} ---", flush=True)
        stmts = parse_statements(p.read_text(encoding="utf-8"))
        print(f"   {len(stmts)} statements", flush=True)
        ok = fail = 0
        for stmt in stmts:
            head = stmt.splitlines()[0][:120]
            try:
                cur.execute(stmt)
                ok += 1
            except Exception as e:
                fail += 1
                failures.append((p.name, head, str(e)[:300]))
        print(f"   ok={ok}, fail={fail}", flush=True)
        grand_ok += ok
        grand_fail += fail

    cur.close()
    conn.close()

    print(f"\n=== TOTAL: ok={grand_ok}, fail={grand_fail} ===", flush=True)
    for f, head, err in failures[:30]:
        print(f"  FAIL [{f}] {head}\n     -> {err}", flush=True)
    return 0 if grand_fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
