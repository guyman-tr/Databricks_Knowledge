"""Re-deploy every wiki .alter.sql for a given semantic schema to Databricks UC.

Pulls every `.alter.sql` (excluding `*.downstream.alter.sql`) under
`knowledge/synapse/Wiki/<schema>/{Tables,Views}/`, extracts each
`ALTER TABLE ... ALTER COLUMN ... COMMENT '...';` statement, and runs them
sequentially through `databricks.sql`. Writes a per-schema run report.

Used to restore truth after the legacy downstream-propagator wipe.

Auth (same env vars as tools/deploy_alter_batch.py):
  DATABRICKS_SERVER_HOSTNAME, DATABRICKS_HTTP_PATH, DATABRICKS_TOKEN
  If DATABRICKS_TOKEN is unset, falls back to databricks-oauth (browser).

Usage:
  python tools/redeploy_schema.py --schema BI_DB_dbo                    # dry-run
  python tools/redeploy_schema.py --schema BI_DB_dbo --apply
  python tools/redeploy_schema.py --files <path> <path> ... --apply --label DWH_dbo_selective
"""
from __future__ import annotations

import argparse
import csv
import os
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
WIKI_ROOT = REPO / "knowledge" / "synapse" / "Wiki"

ALTER_RE = re.compile(
    r"^ALTER\s+TABLE\s+([A-Za-z0-9_.`-]+)\s+"
    r"ALTER\s+COLUMN\s+`?([A-Za-z0-9_]+)`?\s+"
    r"COMMENT\s+'((?:[^']|'')*)'\s*;",
    re.IGNORECASE,
)


def _strip_backticks(s: str) -> str:
    return s.replace("`", "")


def _posix(p: Path) -> str:
    return str(p.relative_to(REPO)).replace("\\", "/")


def _collect_schema_files(schema: str) -> list[Path]:
    base = WIKI_ROOT / schema
    if not base.is_dir():
        return []
    out: list[Path] = []
    for sub in ("Tables", "Views"):
        d = base / sub
        if d.is_dir():
            for p in sorted(d.rglob("*.alter.sql")):
                if p.name.endswith(".downstream.alter.sql"):
                    continue
                out.append(p)
    return out


def _extract_statements(sql_files: list[Path]) -> list[tuple[Path, str]]:
    """Return [(source_file, full_alter_statement)] for every ALTER COLUMN
    COMMENT line in every input file. Handles single-line ALTERs (the format
    used by every .alter.sql in this repo)."""
    out: list[tuple[Path, str]] = []
    for p in sql_files:
        try:
            text = p.read_text(encoding="utf-8")
        except OSError as e:
            print(f"  [warn] cannot read {_posix(p)}: {e}", file=sys.stderr)
            continue
        for line in text.splitlines():
            s = line.strip()
            if not s or s.startswith("--"):
                continue
            if ALTER_RE.match(s):
                out.append((p, s))
    return out


def _connect_databricks():
    try:
        from databricks import sql  # type: ignore
    except ImportError:
        print("ERROR: databricks-sql-connector not installed "
              "(`pip install databricks-sql-connector`).", file=sys.stderr)
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


def _load_previous_report(report_csv: Path) -> dict[tuple[str, str], str]:
    """Return {(uc_table, uc_column): status} for a previous run, empty if
    no report exists."""
    if not report_csv.is_file():
        return {}
    out: dict[tuple[str, str], str] = {}
    with report_csv.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            out[(r["uc_table"], r["uc_column"])] = r["status"]
    return out


def _run(statements: list[tuple[Path, str]], report_csv: Path,
         label: str, resume: bool) -> int:
    print(f"[{label}] {len(statements)} ALTER statements queued.", flush=True)
    prior: dict[tuple[str, str], str] = {}
    if resume:
        prior = _load_previous_report(report_csv)
        already_ok = sum(1 for v in prior.values() if v == "OK")
        print(f"[{label}] Resume mode: {already_ok} statements already OK "
              f"in previous report; will skip those.", flush=True)
    conn = _connect_databricks()
    if conn is None:
        return 3
    cur = conn.cursor()
    report_csv.parent.mkdir(parents=True, exist_ok=True)
    ok = fail = skipped = 0
    with report_csv.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=[
            "idx", "source_file", "uc_table", "uc_column",
            "status", "error",
        ])
        w.writeheader()
        for idx, (src, stmt) in enumerate(statements, start=1):
            m = ALTER_RE.match(stmt)
            uc_table = _strip_backticks(m.group(1)) if m else ""
            uc_column = m.group(2) if m else ""
            key = (uc_table, uc_column)
            if resume and prior.get(key) == "OK":
                w.writerow({
                    "idx": idx, "source_file": _posix(src),
                    "uc_table": uc_table, "uc_column": uc_column,
                    "status": "OK", "error": "(resume: skipped, already OK)",
                })
                skipped += 1
                ok += 1
                continue
            try:
                cur.execute(stmt.rstrip(";"))
                status = "OK"
                error = ""
                ok += 1
            except Exception as e:  # noqa: BLE001
                status = "FAIL"
                error = str(e)[:500]
                fail += 1
            w.writerow({
                "idx": idx, "source_file": _posix(src),
                "uc_table": uc_table, "uc_column": uc_column,
                "status": status, "error": error,
            })
            if idx % 100 == 0 or status == "FAIL":
                msg = (f"  [{label} {idx}/{len(statements)}] {status} "
                       f"{uc_table}.{uc_column}")
                if error:
                    msg += f" -- {error[:120]}"
                print(msg, flush=True)
    cur.close()
    conn.close()
    print(f"[{label}] DONE  OK={ok}  FAIL={fail}  SKIPPED={skipped}",
          flush=True)
    print(f"[{label}] Report: {_posix(report_csv)}", flush=True)
    return 0 if fail == 0 else 4


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--schema", help="Wiki schema folder name "
                                    "(e.g. BI_DB_dbo, Dealing_dbo).")
    g.add_argument("--files", nargs="+",
                   help="Explicit list of .alter.sql paths (repo-relative or "
                        "absolute).")
    ap.add_argument("--label", help="Label for the run report (defaults to "
                                    "--schema, or 'custom' for --files).")
    ap.add_argument("--apply", action="store_true",
                    help="Actually execute. Without this flag, only counts.")
    ap.add_argument("--resume", action="store_true",
                    help="Read existing _redeploy_<label>_report.csv and "
                         "skip rows already marked OK.")
    args = ap.parse_args()

    if args.schema:
        files = _collect_schema_files(args.schema)
        label = args.label or args.schema
    else:
        files = []
        for f in args.files:
            p = Path(f)
            if not p.is_absolute():
                p = REPO / f
            if not p.is_file():
                print(f"ERROR: not a file: {p}", file=sys.stderr)
                return 2
            files.append(p)
        label = args.label or "custom"

    if not files:
        print(f"No .alter.sql files found for {label}.", file=sys.stderr)
        return 1

    print(f"[{label}] Source files: {len(files)}")
    for p in files:
        print(f"  - {_posix(p)}")

    stmts = _extract_statements(files)
    print(f"[{label}] Extracted statements: {len(stmts)}")
    if not args.apply:
        print(f"[{label}] DRY-RUN. Re-run with --apply to commit.")
        return 0

    report = REPO / "knowledge" / f"_redeploy_{label}_report.csv"
    return _run(stmts, report, label, args.resume)


if __name__ == "__main__":
    sys.exit(main())
