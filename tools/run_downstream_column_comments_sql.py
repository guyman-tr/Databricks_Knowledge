#!/usr/bin/env python3
"""
Execute an existing downstream COMMENT script (default: _downstream_column_comments.sql).
Does NOT regenerate SQL — only runs ALTER statements and records failures.

Connection (same as dwh_dbo_deploy_resume_batch.py):
  DATABRICKS_TOKEN  -> PAT auth (no browser)
  else              -> databricks-oauth

Usage:
  python tools/run_downstream_column_comments_sql.py
  python tools/run_downstream_column_comments_sql.py --sql-file path/to/file.sql
  python tools/run_downstream_column_comments_sql.py --limit 50 --dry-run
  python tools/run_downstream_column_comments_sql.py -o knowledge/synapse/Wiki/_downstream_column_comments_run_report.md
  python tools/run_downstream_column_comments_sql.py --progress-every 10 -v

See: knowledge/synapse/Wiki/README_downstream_column_comments.md
"""
from __future__ import annotations

import argparse
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
DEFAULT_SQL = REPO / "knowledge/synapse/Wiki/_downstream_column_comments.sql"
DEFAULT_REPORT = REPO / "knowledge/synapse/Wiki/_downstream_column_comments_run_report.md"


def extract_statements(raw: str) -> list[str]:
    """One ALTER per line; skip comments and blanks."""
    out: list[str] = []
    for line in raw.splitlines():
        s = line.strip()
        if not s or s.startswith("--"):
            continue
        if s.upper().startswith("ALTER TABLE") and s.endswith(";"):
            out.append(s)
    return out


def _format_elapsed(seconds: float) -> str:
    if seconds < 60:
        return f"{seconds:.0f}s"
    m, s = divmod(int(seconds), 60)
    if m < 60:
        return f"{m}m{s:02d}s"
    h, m = divmod(m, 60)
    return f"{h}h{m:02d}m"


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--sql-file",
        type=Path,
        default=DEFAULT_SQL,
        help=f"Path to SQL file (default: {DEFAULT_SQL})",
    )
    ap.add_argument(
        "-o",
        "--report",
        type=Path,
        default=DEFAULT_REPORT,
        help=f"Markdown report path (default: {DEFAULT_REPORT})",
    )
    ap.add_argument("--limit", type=int, default=0, help="Max statements (0 = all)")
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse and count only; no DB connection",
    )
    ap.add_argument(
        "--progress-every",
        type=int,
        default=50,
        metavar="N",
        help="Print progress every N statements (0 = only start and finish; default 50)",
    )
    ap.add_argument("-v", "--verbose", action="store_true")
    args = ap.parse_args()

    sql_path: Path = args.sql_file.resolve()
    if not sql_path.is_file():
        print(f"Missing SQL file: {sql_path}", file=sys.stderr)
        sys.exit(1)

    raw = sql_path.read_text(encoding="utf-8")
    stmts = extract_statements(raw)
    total = len(stmts)
    if args.limit and args.limit > 0:
        stmts = stmts[: args.limit]

    print(f"Parsed {total} ALTER statements; will run {len(stmts)}", flush=True)

    if args.dry_run:
        sys.exit(0)

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
        conn = sql.connect(
            server_hostname=host, http_path=http_path, access_token=token
        )
    else:
        print("Auth: databricks-oauth (browser)", flush=True)
        conn = sql.connect(
            server_hostname=host,
            http_path=http_path,
            auth_type="databricks-oauth",
        )
    cur = conn.cursor()

    n = len(stmts)
    pe = max(0, args.progress_every)
    print(
        f"Connected. Running {n} ALTER(s); "
        + (f"progress every {pe}." if pe else "progress: start + done only."),
        flush=True,
    )

    ok = 0
    failures: list[tuple[str, str]] = []
    t0 = time.monotonic()

    def emit_progress(i: int, *, final: bool = False) -> None:
        elapsed = time.monotonic() - t0
        rate = i / elapsed if elapsed > 0 else 0.0
        pct = (100.0 * i / n) if n else 100.0
        line = (
            f"[{i}/{n}] ok={ok} fail={len(failures)}  "
            f"{_format_elapsed(elapsed)}  {pct:.1f}%  ~{rate:.1f}/s"
        )
        if final:
            line += "  DONE"
        print(line, flush=True)

    for i, stmt in enumerate(stmts, start=1):
        try:
            cur.execute(stmt)
            ok += 1
        except Exception as e:
            msg = str(e).replace("\r", " ").replace("\n", " ")
            failures.append((stmt, msg))
            if args.verbose:
                print(f"  FAIL #{len(failures)}: {msg[:300]}", flush=True)

        # Progress after statement i completes (ok/fail counts are accurate).
        if pe and (i % pe == 0 or i == n):
            emit_progress(i, final=(i == n))
        elif args.verbose and (i % 200 == 0 or i == n):
            emit_progress(i, final=(i == n))

    if pe == 0 and not args.verbose:
        emit_progress(n, final=True)

    cur.close()
    conn.close()

    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    fail = len(failures)

    report_lines = [
        "# Downstream column comments — execution report",
        "",
        f"| Field | Value |",
        f"|--------|--------|",
        f"| **When** | {ts} |",
        f"| **SQL file** | `{sql_path.relative_to(REPO)}` |",
        f"| **Statements attempted** | {len(stmts)} |",
        f"| **Succeeded** | {ok} |",
        f"| **Failed** | {fail} |",
        "",
        "## Failures",
        "",
    ]
    if not failures:
        report_lines.append("*(None.)*")
    else:
        report_lines.append(f"Total failures: **{fail}** (full `ALTER` text + error).")
        report_lines.append("")
        for idx, (stmt, err) in enumerate(failures, start=1):
            report_lines.append(f"### {idx}")
            report_lines.append("")
            report_lines.append("**Error:**")
            report_lines.append("")
            report_lines.append(f"```text")
            report_lines.append(err[:4000])
            report_lines.append("```")
            report_lines.append("")
            report_lines.append("**Statement:**")
            report_lines.append("")
            report_lines.append("```sql")
            report_lines.append(stmt[:8000])
            report_lines.append("```")
            report_lines.append("")

    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text("\n".join(report_lines) + "\n", encoding="utf-8")

    print(f"\nDone: ok={ok} fail={fail}", flush=True)
    print(f"Report: {args.report}", flush=True)
    if fail:
        sys.exit(2)


if __name__ == "__main__":
    main()
