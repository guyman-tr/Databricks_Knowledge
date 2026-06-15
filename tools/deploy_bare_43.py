"""Generic UC ALTER deployer for files produced by scaffold_alter_for_uc_targets.py.

Per uc-deploy-comments skill:
  * Use databricks.sql single-cursor connection (fast).
  * Pre-flight every file with uc_comment_validator.validate_alter_sql.
  * Retry up to 3x with backoff on DELTA_METADATA_CHANGED.
  * Append `-- == LAST EXECUTION ==` footer to each alter file.
  * Write a deploy-report CSV.

Originally written for the bare-43 backfill; now accepts any scaffold summary
file (the JSON written by scaffold's --summary-out flag).

Usage:
    python -u tools/deploy_bare_43.py
    python -u tools/deploy_bare_43.py --summary tools/lakebridge/<some_summary>.json
    python -u tools/deploy_bare_43.py --report tools/lakebridge/<out>.csv
    python -u tools/deploy_bare_43.py --dry-run
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))
from uc_comment_validator import validate_alter_sql


STATEMENT_TERMINATOR = re.compile(r";\s*\n", re.MULTILINE)


def split_statements(alter_text: str) -> list[str]:
    """Split a .alter.sql file into individual statements. Drops -- comment-only
    blocks and blank lines."""
    code = []
    for raw in alter_text.splitlines():
        s = raw.rstrip()
        if not s.strip():
            continue
        if s.lstrip().startswith("--"):
            continue
        code.append(s)
    blob = "\n".join(code) + "\n"
    parts: list[str] = []
    buf: list[str] = []
    for piece in re.split(r";\n", blob):
        chunk = piece.strip()
        if not chunk:
            continue
        parts.append(chunk + ";")
    return parts


def is_transient_error(msg: str) -> bool:
    lo = (msg or "").lower()
    return (
        "delta_metadata_changed" in lo
        or "metadatachangedexception" in lo
        or "concurrentmodificationexception" in lo
    )


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--summary", default="tools/lakebridge/bare_43_scaffold_summary.json")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--report", default="tools/lakebridge/bare_43_deploy_report.csv")
    args = ap.parse_args()

    summary = json.loads(Path(args.summary).read_text(encoding="utf-8"))
    targets = [s for s in summary if s.get("alter_path")]
    print(f"Found {len(targets)} alter files to deploy")

    # Pre-flight validation pass on EVERY file before opening a connection.
    blocked: list[tuple[str, list[str]]] = []
    valid: list[dict] = []
    for s in targets:
        path = REPO / s["alter_path"]
        text = path.read_text(encoding="utf-8")
        problems = validate_alter_sql(text, source=s["alter_path"])
        if problems:
            blocked.append((s["alter_path"], problems))
        else:
            valid.append(s)
    if blocked:
        print(f"\nDRIFT GUARD blocked {len(blocked)} files — refusing to deploy ANY:")
        for path, probs in blocked:
            print(f"  {path}: {probs[:3]}")
        sys.exit(2)
    print(f"Pre-flight OK: all {len(valid)} files pass drift validator")

    if args.dry_run:
        for s in valid:
            text = (REPO / s["alter_path"]).read_text(encoding="utf-8")
            n = len(split_statements(text))
            print(f"[dry-run] {s['alter_path']}  →  {n} statements")
        print(f"\n[dry-run] Would execute {sum(len(split_statements((REPO / s['alter_path']).read_text(encoding='utf-8'))) for s in valid)} statements total")
        return

    from databricks import sql as dbsql
    host = os.environ.get(
        "DATABRICKS_SERVER_HOSTNAME", "adb-5142916747090026.6.azuredatabricks.net"
    )
    http_path = os.environ.get(
        "DATABRICKS_HTTP_PATH", "/sql/1.0/warehouses/208214768b0e0308"
    )
    token = (os.environ.get("DATABRICKS_TOKEN") or "").strip()
    print(f"\nConnecting to {host} ...")
    if token:
        conn = dbsql.connect(server_hostname=host, http_path=http_path, access_token=token)
    else:
        conn = dbsql.connect(server_hostname=host, http_path=http_path, auth_type="databricks-oauth")
    cur = conn.cursor()

    report_rows: list[dict] = []
    total_ok = 0
    total_fail = 0
    file_no = 0

    for s in valid:
        file_no += 1
        path = REPO / s["alter_path"]
        text = path.read_text(encoding="utf-8")
        statements = split_statements(text)
        file_ok = 0
        file_fail = 0
        file_errors: list[str] = []
        print(f"\n[{file_no:>2}/{len(valid)}] {s['alter_path']}  ({len(statements)} statements, uc={s['uc']})", flush=True)

        for i, stmt in enumerate(statements, 1):
            attempt = 0
            while True:
                attempt += 1
                try:
                    cur.execute(stmt)
                    file_ok += 1
                    break
                except Exception as e:
                    msg = str(e)
                    if is_transient_error(msg) and attempt <= 3:
                        wait = 10 * attempt
                        print(f"     [{i}] transient ({msg[:60]}...) — retry in {wait}s (attempt {attempt}/3)", flush=True)
                        time.sleep(wait)
                        continue
                    file_fail += 1
                    short = msg.splitlines()[0][:240]
                    file_errors.append(f"stmt[{i}]: {short}")
                    print(f"     [{i}] FAIL: {short}", flush=True)
                    break

        total_ok += file_ok
        total_fail += file_fail
        print(f"     done: {file_ok}/{len(statements)} ok, {file_fail} fail", flush=True)

        # Append execution footer to the alter file
        footer = (
            "\n"
            "-- == LAST EXECUTION ==\n"
            f"-- Timestamp: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}\n"
            f"-- Statements: {file_ok}/{len(statements)} succeeded\n"
        )
        if file_errors:
            footer += "-- First errors:\n"
            for e in file_errors[:5]:
                footer += f"--   {e}\n"
        footer += "-- ====================\n"
        # Strip prior footer if present so we don't keep stacking
        body = re.sub(
            r"\n-- == LAST EXECUTION ==.*?-- ====================\n?",
            "",
            text,
            flags=re.DOTALL,
        )
        path.write_text(body.rstrip() + "\n" + footer, encoding="utf-8")

        report_rows.append({
            "alter_path": s["alter_path"],
            "uc_target": s["uc"],
            "statements_total": len(statements),
            "statements_ok": file_ok,
            "statements_fail": file_fail,
            "uc_cols_total": s.get("uc_cols", 0),
            "paired_cols": s.get("paired", 0),
            "errors": " | ".join(file_errors)[:1000],
        })

    cur.close()
    conn.close()

    out = REPO / args.report
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=[
            "alter_path", "uc_target", "statements_total", "statements_ok",
            "statements_fail", "uc_cols_total", "paired_cols", "errors",
        ])
        w.writeheader()
        w.writerows(report_rows)
    print(f"\n{'='*78}")
    print(f"DEPLOY COMPLETE  files={file_no}  total_ok={total_ok}  total_fail={total_fail}")
    print(f"Report: {out.relative_to(REPO).as_posix()}")
    if total_fail:
        sys.exit(1)


if __name__ == "__main__":
    main()
