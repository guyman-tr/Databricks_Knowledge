"""
Post-process Lakebridge BladeBridge output so every Synapse SP reads from
the snapshot schema and writes to the migration schema, both living in the
single ``dwh_daily_process`` catalog.

Routing rules:
    DWH_staging.<X>                       -> dwh_daily_process.daily_snapshot.<X>
    <any other known Synapse schema>.<X>  -> dwh_daily_process.migration_tables.<X>

The rewriter handles all four reference styles produced by BladeBridge:
    `Schema`.`Table`     `Schema`.Table     Schema.`Table`     Schema.Table

Anything whose left side is not in the explicit allow-list is left alone
(this protects column aliases like a.CountryID, false positives like
"deposit.amount" in comments, etc.).

Each rewritten file is also prepended with:
    USE CATALOG dwh_daily_process;
    USE SCHEMA migration_tables;

So unqualified CREATE/INSERT statements land in the migration schema by
default.

Usage:
    python tools/lakebridge/rewrite_to_dual_target.py [--src <dir>] [--dst <dir>] [--limit N] [--dry-run]

Defaults:
    --src  C:/Users/guyman/Desktop/lakebridge_transplier
    --dst  C:/Users/guyman/Desktop/lakebridge_transplier_v3
"""

from __future__ import annotations

import argparse
import csv
import re
import shutil
import sys
from pathlib import Path

# --- routing config ---------------------------------------------------------

SNAPSHOT_TARGET = "dwh_daily_process.daily_snapshot"
OUTPUT_TARGET = "dwh_daily_process.migration_tables"

SNAPSHOT_SCHEMAS = {
    "dwh_staging",
}

OUTPUT_SCHEMAS = {
    # DWH family
    "dwh_dbo", "dwh_pagetracking", "dwh_tracking",
    "dwh_watchlists", "dwh_migration",
    # BI_DB family
    "bi_db_dbo", "bi_db_python", "bi_db_staging",
    "bi_db_mixpanel", "bi_db_migration",
    # Dealing
    "dealing_dbo", "dealing_staging",
    # EXW / EXE
    "exw_dbo", "exe_dbo",
    # eMoney
    "emoney_dbo",
    # DE
    "de_dbo",
}

HEADER = "USE CATALOG dwh_daily_process;\nUSE SCHEMA migration_tables;\n\n"

# --- regex ------------------------------------------------------------------

# Match `<schema>`.`<table>` or `<schema>`.<table> or <schema>.`<table>` or <schema>.<table>
# Schema and table are word-characters (letters, digits, underscore) starting
# with a letter or underscore.
REF_PATTERN = re.compile(
    r"`?(?P<schema>[A-Za-z_][\w]*)`?\s*\.\s*`?(?P<table>[A-Za-z_][\w]*)`?"
)

# Header guard — don't double-prepend if the file already has the preamble.
HEADER_GUARD = re.compile(
    r"^\s*USE\s+CATALOG\s+dwh_daily_process\s*;",
    re.IGNORECASE,
)

# --- core -------------------------------------------------------------------


def rewrite_match(m: re.Match) -> str:
    schema = m.group("schema")
    table = m.group("table")
    s = schema.lower()
    if s in SNAPSHOT_SCHEMAS:
        return f"{SNAPSHOT_TARGET}.{table}"
    if s in OUTPUT_SCHEMAS:
        return f"{OUTPUT_TARGET}.{table}"
    return m.group(0)


def count_hits(text: str) -> tuple[int, int, int]:
    """Return (snapshot_hits, output_hits, ignored_dot_refs)."""
    snap = out = ignored = 0
    for m in REF_PATTERN.finditer(text):
        s = m.group("schema").lower()
        if s in SNAPSHOT_SCHEMAS:
            snap += 1
        elif s in OUTPUT_SCHEMAS:
            out += 1
        else:
            ignored += 1
    return snap, out, ignored


def process_text(text: str) -> str:
    new = REF_PATTERN.sub(rewrite_match, text)
    if HEADER_GUARD.search(new):
        return new
    return HEADER + new


def process_file(src: Path, dst: Path) -> dict:
    raw = src.read_bytes()
    # Try utf-8-sig first to swallow BOM, fall back to utf-8 with replace.
    try:
        text = raw.decode("utf-8-sig")
    except UnicodeDecodeError:
        text = raw.decode("utf-8", errors="replace")
    snap, out, ignored = count_hits(text)
    new = process_text(text)
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(new, encoding="utf-8", newline="\n")
    return {
        "rel": str(src),
        "snapshot_hits": snap,
        "output_hits": out,
        "ignored_dot_refs": ignored,
        "bytes_before": len(raw),
        "bytes_after": len(new.encode("utf-8")),
    }


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--src", default=r"C:\Users\guyman\Desktop\lakebridge_transplier")
    p.add_argument("--dst", default=r"C:\Users\guyman\Desktop\lakebridge_transplier_v3")
    p.add_argument("--limit", type=int, default=0, help="Process only first N files (sorted). 0 = all.")
    p.add_argument("--only-name-contains", default="", help="Restrict to files whose name contains this string.")
    p.add_argument("--report", default="rewrite_report.csv", help="CSV report filename (written into --dst).")
    p.add_argument("--dry-run", action="store_true", help="Don't write any files; just print stats.")
    p.add_argument("--clean", action="store_true", help="Delete --dst before writing (default keeps existing files).")
    args = p.parse_args(argv)

    src = Path(args.src)
    dst = Path(args.dst)
    if not src.exists():
        print(f"ERROR: source dir does not exist: {src}", file=sys.stderr)
        return 2

    files = sorted(src.rglob("*.sql"))
    if args.only_name_contains:
        files = [f for f in files if args.only_name_contains.lower() in f.name.lower()]
    if args.limit:
        files = files[: args.limit]

    if not files:
        print("No .sql files matched.", file=sys.stderr)
        return 1

    if args.clean and dst.exists() and not args.dry_run:
        shutil.rmtree(dst)
    if not args.dry_run:
        dst.mkdir(parents=True, exist_ok=True)

    rows: list[dict] = []
    for f in files:
        rel = f.relative_to(src)
        if args.dry_run:
            text = f.read_text(encoding="utf-8-sig", errors="replace")
            snap, out, ignored = count_hits(text)
            row = {
                "rel": str(rel),
                "snapshot_hits": snap,
                "output_hits": out,
                "ignored_dot_refs": ignored,
                "bytes_before": len(text.encode("utf-8")),
                "bytes_after": -1,
            }
        else:
            row = process_file(f, dst / rel)
            row["rel"] = str(rel)
        rows.append(row)

    total_snap = sum(r["snapshot_hits"] for r in rows)
    total_out = sum(r["output_hits"] for r in rows)
    total_ign = sum(r["ignored_dot_refs"] for r in rows)
    print(f"Files processed       : {len(rows)}")
    print(f"  -> snapshot rewrites: {total_snap}")
    print(f"  -> output rewrites  : {total_out}")
    print(f"  -> dot refs ignored : {total_ign}  (these are aliases / non-Synapse names)")

    if not args.dry_run:
        report_path = dst / args.report
        with report_path.open("w", encoding="utf-8", newline="") as fh:
            w = csv.DictWriter(
                fh,
                fieldnames=["rel", "snapshot_hits", "output_hits", "ignored_dot_refs", "bytes_before", "bytes_after"],
            )
            w.writeheader()
            w.writerows(rows)
        print(f"Report written to     : {report_path}")
        print(f"Rewritten files in    : {dst}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
