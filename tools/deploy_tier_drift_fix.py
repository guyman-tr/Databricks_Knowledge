"""Targeted re-deploy of the 2 alter files repaired during the
2026-05-19 tier/header drift fix:
  * BI_DB_dbo/Tables/BI_DB_KYC_Panel.alter.sql
  * eMoney_dbo/Tables/eMoneyClientBalance.alter.sql

This is a one-shot script (kept in tree for audit + re-runnability).

Pre-flight: runs `validate_alter_sql` on each file. Refuses to send any
statement if the historic drift pattern is detected — so even if someone
re-introduces the bug into the alter file, deploy will halt before
writing to UC.

Auth: same as `deploy_alter_batch.py` (DATABRICKS_TOKEN PAT preferred,
else OAuth browser).
"""
from __future__ import annotations

import os
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))

from uc_comment_validator import validate_alter_sql

ALTER_FILES = [
    REPO / "knowledge" / "synapse" / "Wiki" / "BI_DB_dbo" / "Tables" / "BI_DB_KYC_Panel.alter.sql",
    REPO / "knowledge" / "synapse" / "Wiki" / "eMoney_dbo" / "Tables" / "eMoneyClientBalance.alter.sql",
]


def strip_footer(raw: str) -> str:
    return re.sub(
        r"\n*-- == LAST EXECUTION ==.*?-- ====================",
        "", raw, flags=re.DOTALL,
    ).rstrip()


def parse_statements(content: str) -> list[str]:
    content = strip_footer(content)
    stmts: list[str] = []
    current: list[str] = []
    for line in content.splitlines():
        if line.strip().startswith("ALTER TABLE") or line.strip().startswith("ALTER VIEW"):
            if current:
                stmts.append("\n".join(current).strip())
            current = [line]
        elif current:
            current.append(line)
            if line.rstrip().endswith(";"):
                stmts.append("\n".join(current).strip())
                current = []
    if current:
        stmts.append("\n".join(current).strip())
    return [s for s in stmts if s]


def sanitize_one_line(s: str, max_len: int = 500) -> str:
    s = (s or "").replace("\r", " ").replace("\n", " ").replace("|", "/")
    s = " ".join(s.split())
    return s[:max_len]


def main() -> None:
    # Pre-flight drift validation
    blocking = False
    for fpath in ALTER_FILES:
        if not fpath.is_file():
            print(f"[MISSING] {fpath}", flush=True)
            blocking = True
            continue
        raw = fpath.read_text(encoding="utf-8")
        problems = validate_alter_sql(raw, source=str(fpath.relative_to(REPO)))
        if problems:
            print(f"[DRIFT GUARD FAIL] {fpath.name}: {len(problems)} bad lines", flush=True)
            for p in problems[:5]:
                print(f"    {p}", flush=True)
            blocking = True
    if blocking:
        sys.exit("Aborting — fix drift issues before deploy.")

    from databricks import sql

    host = os.environ.get(
        "DATABRICKS_SERVER_HOSTNAME", "adb-5142916747090026.6.azuredatabricks.net"
    )
    http_path = os.environ.get(
        "DATABRICKS_HTTP_PATH", "/sql/1.0/warehouses/208214768b0e0308"
    )
    token = (os.environ.get("DATABRICKS_TOKEN") or "").strip()

    print("Connecting to Databricks...", flush=True)
    if token:
        print("Auth: PAT", flush=True)
        conn = sql.connect(server_hostname=host, http_path=http_path, access_token=token)
    else:
        print("Auth: databricks-oauth", flush=True)
        conn = sql.connect(server_hostname=host, http_path=http_path, auth_type="databricks-oauth")
    cur = conn.cursor()
    print("Connected.\n", flush=True)

    grand_ok = grand_fail = 0

    for fpath in ALTER_FILES:
        raw = fpath.read_text(encoding="utf-8")
        stmts = parse_statements(raw)
        print(f"{'=' * 70}", flush=True)
        print(f"{fpath.name}  ({len(stmts)} statements)", flush=True)
        print(f"{'=' * 70}", flush=True)

        ok = fail = 0
        last_err = ""
        t0 = time.time()
        for i, stmt in enumerate(stmts, 1):
            col_match = re.search(r"ALTER COLUMN [`]?(\w+)[`]?", stmt)
            tag = col_match.group(1) if col_match else "tbl"
            try:
                cur.execute(stmt)
                ok += 1
                if i % 25 == 0 or i == len(stmts):
                    print(f"  [{i}/{len(stmts)}] ok ({tag})", flush=True)
            except Exception as e:
                fail += 1
                last_err = sanitize_one_line(str(e), 460)
                print(f"  [{i}/{len(stmts)}] FAIL ({tag}): {last_err}", flush=True)
        dt = time.time() - t0
        print(f"-> {ok}/{ok + fail} succeeded in {dt:.1f}s", flush=True)
        grand_ok += ok
        grand_fail += fail

        ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
        footer = [
            "",
            "-- == LAST EXECUTION ==",
            f"-- Timestamp: {ts}",
            "-- Batch: tier_drift_fix (2026-05-19 one-shot)",
            f"-- Statements: {ok}/{ok + fail} succeeded",
        ]
        if last_err and fail > 0:
            footer.append(f"-- Error: {last_err}")
        footer.append("-- ====================")
        fpath.write_text(strip_footer(raw) + "\n" + "\n".join(footer) + "\n", encoding="utf-8")
        print(f"   footer written\n", flush=True)

    cur.close()
    conn.close()
    print(f"\nGrand total: {grand_ok}/{grand_ok + grand_fail} statements succeeded")


if __name__ == "__main__":
    main()
