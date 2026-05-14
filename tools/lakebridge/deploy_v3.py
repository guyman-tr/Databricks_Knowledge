"""
Deploy the v3 transpiled SQL output (dwh_daily_process.migration_tables) to
Databricks. Walks the rewritten lakebridge tree in dependency order:

    Tables  ->  External Tables  ->  Functions  ->  Views  ->  Stored Procedures

Each .sql file is one CREATE statement (the leading USE CATALOG / USE SCHEMA
lines are folded into a single per-session call, not re-issued per file).

Results are written to a CSV report so the script can be re-run with --resume
to skip already-deployed files.

Usage (PowerShell)::

    python -u tools\lakebridge\deploy_v3.py                 # all phases, all files
    python -u tools\lakebridge\deploy_v3.py --phase tables  # tables only
    python -u tools\lakebridge\deploy_v3.py --only-name-contains dim_customer --resume
    python -u tools\lakebridge\deploy_v3.py --dry-run

It re-uses the same Databricks profile / OAuth credential surface as the
``databricks_sql`` MCP (see ``knowledge/skills/databricks-connection``).
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import subprocess
import sys
import time
import traceback
from configparser import ConfigParser
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

DEFAULT_SRC = r"C:\Users\guyman\Desktop\lakebridge_transplier_v3"
DEFAULT_REPORT = r"C:\Users\guyman\Documents\github\Databricks_Knowledge\tools\lakebridge\deploy_report.csv"
DEFAULT_PROFILE = os.environ.get("DATABRICKS_CONFIG_PROFILE", "name-of-profile")
DEFAULT_HTTP_PATH = "/sql/1.0/warehouses/208214768b0e0308"  # bi-sql-warehouse-customer
DEFAULT_TARGET_CATALOG = "dwh_daily_process"
DEFAULT_TARGET_SCHEMA = "migration_tables"

PHASE_ORDER = ["tables", "external_tables", "functions", "views", "stored_procedures"]
PHASE_DIRS = {
    "tables": "Tables",
    "external_tables": "External Tables",
    "functions": "Functions",
    "views": "Views",
    "stored_procedures": "Stored Procedures",
}
PHASE_ALIASES = {
    "tables": "tables",
    "external": "external_tables",
    "external-tables": "external_tables",
    "external_tables": "external_tables",
    "functions": "functions",
    "views": "views",
    "sps": "stored_procedures",
    "stored-procedures": "stored_procedures",
    "stored_procedures": "stored_procedures",
}


# ---------------------------------------------------------------------------
# .databrickscfg helpers
# ---------------------------------------------------------------------------


def read_host_from_profile(profile: str) -> str:
    cfg_path = Path.home() / ".databrickscfg"
    if not cfg_path.exists():
        raise SystemExit(f".databrickscfg not found at {cfg_path}")
    cp = ConfigParser()
    cp.read(cfg_path, encoding="utf-8")
    if profile not in cp:
        raise SystemExit(
            f"profile [{profile}] not in {cfg_path}. Available: {sorted(cp.sections())}"
        )
    host = cp[profile].get("host", "").strip()
    if not host:
        raise SystemExit(f"profile [{profile}] has no 'host' entry in {cfg_path}")
    host = host.replace("https://", "").replace("http://", "").rstrip("/")
    return host


def fetch_token(profile: str) -> str:
    """Get a fresh OAuth bearer token via the unified Databricks CLI.

    Works for the [profile] entries that use ``auth_type = databricks-cli`` in
    ``~/.databrickscfg`` -- which is what ``databricks auth login`` produces.
    The token is short-lived (~1 h) but the script is fast enough that a single
    deploy run fits comfortably inside that window.
    """
    try:
        result = subprocess.run(
            ["databricks", "auth", "token", "--profile", profile, "-o", "json"],
            capture_output=True,
            text=True,
            check=True,
            shell=True,
        )
    except subprocess.CalledProcessError as exc:
        raise SystemExit(
            f"`databricks auth token --profile {profile}` failed:\n"
            f"  stderr: {exc.stderr.strip()}\n"
            "Run `databricks auth login --profile {profile}` first."
        ) from exc
    data = json.loads(result.stdout)
    token = data.get("access_token", "").strip()
    if not token:
        raise SystemExit(f"databricks auth token returned no access_token: {result.stdout}")
    return token


# ---------------------------------------------------------------------------
# SQL body extraction
# ---------------------------------------------------------------------------

_USE_CATALOG_RE = re.compile(r"^\s*USE\s+CATALOG\s+\w+\s*;\s*", re.IGNORECASE)
_USE_SCHEMA_RE = re.compile(r"^\s*USE\s+SCHEMA\s+\w+\s*;\s*", re.IGNORECASE)


def extract_body(text: str) -> str:
    """Strip USE CATALOG / USE SCHEMA lines and trailing whitespace/semicolons."""
    body = _USE_CATALOG_RE.sub("", text, count=1)
    body = _USE_SCHEMA_RE.sub("", body, count=1)
    body = body.strip()
    # Strip trailing terminator(s) so cursor.execute doesn't choke on empty
    # follow-up statements.
    while body.endswith(";"):
        body = body[:-1].rstrip()
    return body


# ---------------------------------------------------------------------------
# Synapse -> Databricks DDL fixups
# ---------------------------------------------------------------------------
#
# These are dialect quirks BladeBridge leaves behind. We strip them just in
# time before sending DDL to Databricks. They are intentionally conservative:
# only patterns observed in the v3 output are touched, with no semantic
# alteration of columns that Databricks itself accepts.

# Backtick-wrapped data-type tokens that BladeBridge mistakenly quoted as
# identifiers. Only unwrap when the trailing context is one of the column-DDL
# follow-on tokens (, / NOT NULL / NULL / DEFAULT / closing paren) -- that
# protects real columns whose *name* happens to be a reserved type word.
_BACKTICK_TYPE_RE = re.compile(
    r"`(?P<t>BOOLEAN|TIMESTAMP|DATE|DATETIME|INT|INTEGER|BIGINT|SMALLINT|TINYINT|"
    r"FLOAT|DOUBLE|REAL|STRING|VARCHAR|CHAR|TEXT|"
    r"DECIMAL\s*\(\s*\d+(?:\s*,\s*\d+)?\s*\)|"
    r"NUMERIC\s*\(\s*\d+(?:\s*,\s*\d+)?\s*\))`"
    r"(?=\s*(?:,|NOT\s+NULL|NULL|DEFAULT|\)))",
    re.IGNORECASE,
)

_FIXUP_PATTERNS: list[tuple[re.Pattern[str], object]] = [
    # MASKED WITH(FUNCTION = '...')  -- the inner string can contain () (e.g.
    # 'default()'), so we anchor on the FUNCTION = '<single-quoted>' form
    # instead of a naive [^)]*.
    (re.compile(
        r"\s+MASKED\s+WITH\s*\(\s*FUNCTION\s*=\s*'[^']*'\s*\)",
        re.IGNORECASE,
    ), ""),
    # Backtick-wrapped types: see _BACKTICK_TYPE_RE above.
    (_BACKTICK_TYPE_RE, lambda m: m.group("t")),
    # Synapse index hints that don't apply to Delta.
    (re.compile(r"\bNONCLUSTERED\b", re.IGNORECASE), ""),
    (re.compile(r"\bCLUSTERED\s+COLUMNSTORE\s+INDEX\b", re.IGNORECASE), ""),
    # Backticked types with trailing precision: `TIMESTAMP`(7) -> TIMESTAMP.
    (re.compile(
        r"`(BOOLEAN|TIMESTAMP|DATETIME|DATE|VARCHAR|CHAR|STRING|TEXT)`\s*\(\s*\d+(?:\s*,\s*\d+)?\s*\)",
        re.IGNORECASE,
    ), lambda m: m.group(1).upper() if m.group(1).upper() != "VARCHAR" else "STRING"),
    # TIMESTAMP(N) precision is unsupported -- Databricks TIMESTAMP only.
    (re.compile(r"\bTIMESTAMP\s*\(\s*\d+\s*\)", re.IGNORECASE), "TIMESTAMP"),
    # string(N) -- Databricks STRING is unbounded; drop the length spec.
    (re.compile(r"\bSTRING\s*\(\s*\d+\s*\)", re.IGNORECASE), "STRING"),
    # Strip the entire CONSTRAINT ... PRIMARY KEY ... NOT ENFORCED block.
    # PK constraints in Databricks are metadata-only; Synapse-style PK lists
    # cause real problems here (ASC/DESC modifiers, duplicate columns from
    # upstream typos, and re-used constraint names across tables). Removing
    # the block trades documentation metadata for deployability.
    (re.compile(
        r",?\s*CONSTRAINT\s+`[^`]+`\s+PRIMARY\s+KEY\b[^()]*\([^)]*\)\s*NOT\s+ENFORCED\s*",
        re.IGNORECASE | re.DOTALL,
    ), "\n"),
    # PRIMARY KEY column ordering -- Synapse emits `col` ASC inside PK lists;
    # Databricks doesn't accept ASC/DESC inside a PK constraint. Kept as a
    # safety net for any PK clauses that escape the broader strip above.
    (re.compile(r"(`\w+`)\s+(?:ASC|DESC)\b", re.IGNORECASE), r"\1"),
    # Synapse "WITH (DISTRIBUTION = ..., HEAP)" trailing clauses.
    (re.compile(
        r"\bWITH\s*\(\s*(?:DISTRIBUTION|HEAP|CLUSTERED|PARTITION)\b[^)]*\)",
        re.IGNORECASE | re.DOTALL,
    ), ""),
]


def fixup_ddl(body: str) -> tuple[str, list[str]]:
    """Apply Synapse-leftover -> Databricks fixups.

    Returns (new_body, applied_labels). applied_labels is a stable list of
    pattern names that fired, so deploy reports show *why* a file was
    munged.
    """
    applied: list[str] = []
    new = body
    for pat, repl in _FIXUP_PATTERNS:
        if pat.search(new):
            applied.append(pat.pattern if len(pat.pattern) < 60 else pat.pattern[:60] + "...")
            new = pat.sub(repl, new)
    return new, applied


# ---------------------------------------------------------------------------
# Report I/O
# ---------------------------------------------------------------------------


def load_report(path: Path) -> dict[str, dict]:
    """Return {relpath: row_dict}."""
    if not path.exists():
        return {}
    rows = {}
    with path.open("r", encoding="utf-8", newline="") as fh:
        for r in csv.DictReader(fh):
            rows[r["rel"]] = r
    return rows


REPORT_FIELDS = ["rel", "phase", "status", "elapsed_ms", "object_kind", "fixups", "error", "ts"]


def write_report(path: Path, rows: dict[str, dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=REPORT_FIELDS)
        w.writeheader()
        for rel in sorted(rows):
            row = {k: rows[rel].get(k, "") for k in REPORT_FIELDS}
            row["rel"] = rel
            w.writerow(row)


# ---------------------------------------------------------------------------
# File enumeration
# ---------------------------------------------------------------------------


def enumerate_files(src: Path, phases: list[str], only_name_contains: str, limit: int):
    out: list[tuple[str, Path]] = []
    for phase in phases:
        subdir = src / PHASE_DIRS[phase]
        if not subdir.exists():
            continue
        files = sorted(p for p in subdir.glob("*.sql"))
        if only_name_contains:
            files = [p for p in files if only_name_contains.lower() in p.name.lower()]
        for p in files:
            out.append((phase, p))
    if limit:
        out = out[:limit]
    return out


# ---------------------------------------------------------------------------
# Object-kind detection (just for the report)
# ---------------------------------------------------------------------------

_KIND_RE = re.compile(
    r"\bCREATE\s+(?:OR\s+REPLACE\s+)?(EXTERNAL\s+TABLE|TABLE|VIEW|FUNCTION|PROCEDURE)\b",
    re.IGNORECASE,
)


def detect_kind(body: str) -> str:
    m = _KIND_RE.search(body[:400])
    if not m:
        return "?"
    return m.group(1).upper().replace(" ", "_")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main(argv: Optional[list[str]] = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--src", default=DEFAULT_SRC, help=f"Rewritten transpile tree (default: {DEFAULT_SRC})")
    p.add_argument("--report", default=DEFAULT_REPORT, help=f"Per-file deploy report CSV (default: {DEFAULT_REPORT})")
    p.add_argument("--profile", default=DEFAULT_PROFILE, help=f"Databricks profile in ~/.databrickscfg (default: {DEFAULT_PROFILE})")
    p.add_argument("--http-path", default=DEFAULT_HTTP_PATH, help=f"SQL warehouse http_path (default: {DEFAULT_HTTP_PATH})")
    p.add_argument("--phase", action="append", default=[], choices=sorted(set(PHASE_ALIASES.keys())), help="Phase(s) to deploy. Repeatable. Default: all in dependency order.")
    p.add_argument("--only-name-contains", default="", help="Restrict to files whose name contains this string (case-insensitive).")
    p.add_argument("--limit", type=int, default=0, help="Process only first N files in deploy order. 0 = all.")
    p.add_argument("--dry-run", action="store_true", help="Don't connect; just list what would deploy.")
    p.add_argument("--resume", action="store_true", help="Skip files already marked status=ok in the report.")
    p.add_argument("--drop-old-dim-customer", action="store_true", help="Drop main.de_output_synapse_migration.sp_dim_customer + test_sp before starting.")
    p.add_argument("--target-catalog", default=DEFAULT_TARGET_CATALOG)
    p.add_argument("--target-schema", default=DEFAULT_TARGET_SCHEMA)
    args = p.parse_args(argv)

    src = Path(args.src)
    if not src.exists():
        print(f"ERROR: --src does not exist: {src}", file=sys.stderr)
        return 2

    phases = [PHASE_ALIASES[ph] for ph in (args.phase or PHASE_ORDER)]
    phases = [ph for ph in PHASE_ORDER if ph in phases]  # preserve canonical order
    files = enumerate_files(src, phases, args.only_name_contains, args.limit)
    if not files:
        print("No .sql files matched the filters.", file=sys.stderr)
        return 1

    print(f"Source:       {src}")
    print(f"Profile:      {args.profile}")
    print(f"HTTP path:    {args.http_path}")
    print(f"Target:       {args.target_catalog}.{args.target_schema}")
    print(f"Phases:       {phases}")
    print(f"Total files:  {len(files)}")
    print(f"Report:       {args.report}")
    print(f"Resume mode:  {args.resume}")
    print()

    report_path = Path(args.report)
    existing = load_report(report_path) if args.resume else {}

    if args.dry_run:
        for phase, f in files:
            rel = f"{PHASE_DIRS[phase]}/{f.name}"
            existing_status = existing.get(rel, {}).get("status", "")
            skip = args.resume and existing_status == "ok"
            tag = "SKIP" if skip else "WILL DEPLOY"
            print(f"  [{tag:11}] {phase:18}  {rel}")
        return 0

    host = read_host_from_profile(args.profile)
    token = fetch_token(args.profile)
    print(f"Workspace host: {host}")
    print(f"Auth token:     {token[:24]}... (len={len(token)})")
    print(f"Opening Databricks SQL connection ...", flush=True)

    # Defer import so --dry-run works in environments without the connector.
    from databricks import sql as dbsql  # type: ignore

    conn = dbsql.connect(
        server_hostname=host,
        http_path=args.http_path,
        access_token=token,
    )
    cur = conn.cursor()

    # One-shot session setup -- USE CATALOG / USE SCHEMA so unqualified DDL
    # lands in the migration schema even when a file's CREATE statement uses
    # the unqualified name.
    cur.execute(f"USE CATALOG {args.target_catalog}")
    cur.execute(f"USE SCHEMA {args.target_schema}")
    print(f"Session bound to {args.target_catalog}.{args.target_schema}", flush=True)

    if args.drop_old_dim_customer:
        for stmt in [
            "DROP PROCEDURE IF EXISTS main.de_output_synapse_migration.sp_dim_customer",
            "DROP PROCEDURE IF EXISTS main.de_output_synapse_migration.test_sp",
        ]:
            try:
                cur.execute(stmt)
                print(f"  cleanup OK   : {stmt}", flush=True)
            except Exception as exc:
                print(f"  cleanup FAIL : {stmt} -- {exc}", flush=True)

    rows = existing.copy()
    ok = fail = skipped = 0
    t_start_total = time.time()

    for i, (phase, f) in enumerate(files, 1):
        rel = f"{PHASE_DIRS[phase]}/{f.name}"
        if args.resume and existing.get(rel, {}).get("status") == "ok":
            skipped += 1
            continue

        try:
            raw = f.read_text(encoding="utf-8-sig", errors="replace")
        except Exception as exc:
            rows[rel] = {
                "rel": rel,
                "phase": phase,
                "status": "read_error",
                "elapsed_ms": 0,
                "object_kind": "?",
                "error": str(exc),
                "ts": time.strftime("%Y-%m-%dT%H:%M:%S"),
            }
            fail += 1
            continue

        body = extract_body(raw)
        if not body:
            rows[rel] = {
                "rel": rel,
                "phase": phase,
                "status": "empty",
                "elapsed_ms": 0,
                "object_kind": "?",
                "fixups": "",
                "error": "no body after stripping USE headers",
                "ts": time.strftime("%Y-%m-%dT%H:%M:%S"),
            }
            fail += 1
            print(f"  [{i:4d}/{len(files)}] EMPTY        {rel}", flush=True)
            continue

        body, fixups = fixup_ddl(body)
        fixups_str = ";".join(fixups)
        kind = detect_kind(body)
        t0 = time.time()
        try:
            cur.execute(body)
            elapsed = int((time.time() - t0) * 1000)
            rows[rel] = {
                "rel": rel,
                "phase": phase,
                "status": "ok",
                "elapsed_ms": elapsed,
                "object_kind": kind,
                "fixups": fixups_str,
                "error": "",
                "ts": time.strftime("%Y-%m-%dT%H:%M:%S"),
            }
            ok += 1
            fixup_tag = f" [{len(fixups)} fix]" if fixups else ""
            print(f"  [{i:4d}/{len(files)}] OK   {elapsed:6d}ms {kind:18}  {rel}{fixup_tag}", flush=True)
        except Exception as exc:
            elapsed = int((time.time() - t0) * 1000)
            err_text = str(exc).strip()
            # Skip blank leading lines; the connector formats errors with a
            # leading newline before the [SQLCODE] header.
            err_lines = [ln for ln in err_text.splitlines() if ln.strip()]
            err = (err_lines[0] if err_lines else err_text or repr(exc))[:400]
            rows[rel] = {
                "rel": rel,
                "phase": phase,
                "status": "error",
                "elapsed_ms": elapsed,
                "object_kind": kind,
                "fixups": fixups_str,
                "error": err,
                "ts": time.strftime("%Y-%m-%dT%H:%M:%S"),
            }
            fail += 1
            print(f"  [{i:4d}/{len(files)}] FAIL {elapsed:6d}ms {kind:18}  {rel}", flush=True)
            print(f"              ^-- {err}", flush=True)

        # Persist the report every 25 statements so we can resume after crashes.
        if i % 25 == 0:
            write_report(report_path, rows)

    write_report(report_path, rows)
    cur.close()
    conn.close()

    total_elapsed = int((time.time() - t_start_total))
    print()
    print(f"Done in {total_elapsed}s. OK={ok}  FAIL={fail}  SKIP={skipped}  TOTAL={len(files)}")
    print(f"Report written to {report_path}")
    return 0 if fail == 0 else 3


if __name__ == "__main__":
    sys.exit(main())
