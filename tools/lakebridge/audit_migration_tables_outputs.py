"""
audit_migration_tables_outputs.py

For every transpiled SP in lakebridge_transplier_v3/Stored Procedures/,
extract the set of `migration_tables.<table>` objects each procedure
WRITES TO (INSERT INTO, MERGE INTO, UPDATE, TRUNCATE TABLE, DELETE FROM).

Cross-reference against the actual list of tables/views currently
deployed in `dwh_daily_process.migration_tables` and produce a definitive
PRUNE CANDIDATES report:

  - Tables in the schema that NO SP writes to (these are the prune
    candidates -- likely nitsan_test, date-stamped snapshots, manual
    backups, dead lookup tables, etc.).
  - Tables WRITTEN by some SP but MISSING from the schema (these are
    a separate issue -- the SP would fail when called).

Output CSV: tools/lakebridge/audit/migration_tables_audit.csv
Output report (human-readable): tools/lakebridge/audit/PRUNE_LIST.md

Usage:
    python tools/lakebridge/audit_migration_tables_outputs.py
"""

from __future__ import annotations

import csv
import json
import re
import subprocess
from collections import defaultdict
from pathlib import Path


SP_DIR = Path(r"C:\Users\guyman\Desktop\lakebridge_transplier_v3\Stored Procedures")
OUT_DIR = Path(__file__).parent / "audit"
OUT_DIR.mkdir(exist_ok=True)


# --- regex for write-target detection ---------------------------------------
# Captures `<catalog>.<schema>.<table>` or `<schema>.<table>` or `<table>`,
# with optional [] / ` ` quoting around segments. We post-filter to the
# migration_tables schema after the match.
TBL_RE = (
    r"(?:`([^`]+)`|\[([^\]]+)\]|([A-Za-z_][\w$]*))"
)
QUALIFIED = (
    rf"(?:(?:{TBL_RE})\s*\.\s*)?"      # optional catalog
    rf"(?:(?:{TBL_RE})\s*\.\s*)?"      # optional schema
    rf"(?:{TBL_RE})"                   # required table name
)

# Note: keep the patterns tight so we don't pick up dotted column refs.
WRITE_PATTERNS = [
    (re.compile(rf"\bINSERT\s+INTO\s+(?:OVERWRITE\s+)?({QUALIFIED})", re.IGNORECASE), "INSERT"),
    (re.compile(rf"\bMERGE\s+INTO\s+({QUALIFIED})", re.IGNORECASE), "MERGE"),
    (re.compile(rf"\bTRUNCATE\s+TABLE\s+({QUALIFIED})", re.IGNORECASE), "TRUNCATE"),
    (re.compile(rf"\bDELETE\s+FROM\s+({QUALIFIED})", re.IGNORECASE), "DELETE"),
    # UPDATE <table> SET ...  (BladeBridge re-emits plain UPDATE for some
    # rewrites; we keep it.) Avoid matching `UPDATE A SET ... FROM ... JOIN`
    # where the alias isn't the table -- we only care about the catalog-
    # qualified form which only appears for the real target.
    (re.compile(rf"\bUPDATE\s+({QUALIFIED})\s+SET\b", re.IGNORECASE), "UPDATE"),
]


def first_nonempty(*groups: str | None) -> str | None:
    for g in groups:
        if g:
            return g
    return None


def parse_qualified(m: re.Match, start: int) -> tuple[str | None, str | None, str]:
    """Pull catalog, schema, table from a QUALIFIED capture starting at
    capture-group number `start` (1-indexed; `start` is the first of the
    9 sub-groups: 3 for catalog (`/[]/bare), 3 for schema, 3 for table).
    """
    cat = first_nonempty(m.group(start + 0), m.group(start + 1), m.group(start + 2))
    sch = first_nonempty(m.group(start + 3), m.group(start + 4), m.group(start + 5))
    tbl = first_nonempty(m.group(start + 6), m.group(start + 7), m.group(start + 8))
    if tbl is None and sch is None:
        return None, None, cat or ""
    if tbl is None and sch is not None:
        return None, cat, sch
    return cat, sch, tbl or ""


def strip_comments(sql: str) -> str:
    # remove block comments first, then line comments
    sql = re.sub(r"/\*.*?\*/", " ", sql, flags=re.DOTALL)
    sql = re.sub(r"--[^\n]*", " ", sql)
    return sql


def extract_writes(sql_path: Path) -> list[tuple[str, str, str | None, str | None, str]]:
    """Return list of (action, raw_match, catalog, schema, table_lower)."""
    raw = sql_path.read_text(encoding="utf-8-sig", errors="replace")
    body = strip_comments(raw)
    out: list[tuple[str, str, str | None, str | None, str]] = []
    for pat, action in WRITE_PATTERNS:
        for m in pat.finditer(body):
            # group 1 is the whole QUALIFIED; sub-groups start at 2.
            cat, sch, tbl = parse_qualified(m, start=2)
            if not tbl:
                continue
            raw_text = m.group(0)
            out.append(
                (action, raw_text.strip(), cat, sch, tbl.lower())
            )
    return out


def fetch_token(profile: str) -> str:
    res = subprocess.run(
        ["databricks", "auth", "token", "--profile", profile, "-o", "json"],
        capture_output=True, text=True, check=True, shell=True,
    )
    return json.loads(res.stdout)["access_token"]


def main() -> None:
    # ---- 1) scan every SP for write targets --------------------------------
    sp_files = sorted(SP_DIR.glob("*.sql"))
    print(f"Found {len(sp_files)} SP files in {SP_DIR}")

    # per-table: set of (sp_name, action)
    writes_by_table: dict[str, set[tuple[str, str]]] = defaultdict(set)
    # per-SP: set of tables it writes to
    tables_by_sp: dict[str, set[str]] = defaultdict(set)
    # non-migration-tables writes (cross-schema, unexpected)
    cross_schema: list[tuple[str, str, str, str | None, str | None, str]] = []

    for f in sp_files:
        sp_name = f.stem
        writes = extract_writes(f)
        for action, raw_text, cat, sch, tbl in writes:
            cat_l = (cat or "").lower()
            sch_l = (sch or "").lower()
            if sch_l in ("migration_tables", "") and (
                cat_l in ("dwh_daily_process", "") or cat_l == "dwh_daily_process"
            ):
                # Treat unqualified writes (no schema) as migration_tables
                # since that's the deployment target.
                writes_by_table[tbl].add((sp_name, action))
                tables_by_sp[sp_name].add(tbl)
            else:
                cross_schema.append((sp_name, action, raw_text, cat, sch, tbl))

    print(f"Distinct migration_tables write targets: {len(writes_by_table)}")
    print(f"Cross-schema write targets (informational): {len(cross_schema)}")

    # ---- 2) fetch the actual list of objects in migration_tables -----------
    token = fetch_token("name-of-profile")
    from databricks import sql as dbsql
    conn = dbsql.connect(
        server_hostname="adb-5142916747090026.6.azuredatabricks.net",
        http_path="/sql/1.0/warehouses/208214768b0e0308",
        access_token=token,
    )
    cur = conn.cursor()
    cur.execute(
        "SELECT lower(table_name) AS name, table_type, last_altered "
        "FROM system.information_schema.tables "
        "WHERE table_catalog='dwh_daily_process' AND table_schema='migration_tables'"
    )
    deployed_rows = cur.fetchall()
    deployed: dict[str, str] = {row[0]: row[1] for row in deployed_rows}
    last_altered: dict[str, str] = {
        row[0]: (row[2].isoformat() if row[2] is not None else "")
        for row in deployed_rows
    }
    print(f"Objects deployed in migration_tables: {len(deployed)}")

    # ---- 3) diff -----------------------------------------------------------
    sp_writes_set = set(writes_by_table.keys())
    deployed_set = set(deployed.keys())

    prune_candidates = sorted(deployed_set - sp_writes_set)
    # Filter out obvious parser-false-positives from "missing": CTE/temp
    # names that aren't real tables (1-3 letters, temp_table_ prefix,
    # SQL reserved-ish words).
    raw_missing = sorted(sp_writes_set - deployed_set)
    false_positive_names = {"c", "t", "t1", "cte", "fact"}
    missing_from_lake = [
        m for m in raw_missing
        if not m.startswith("temp_table_") and m not in false_positive_names
    ]
    missing_false_positives = [m for m in raw_missing if m not in missing_from_lake]
    matched = sorted(sp_writes_set & deployed_set)

    # ---- 3b) categorize prune candidates -----------------------------------
    def categorize(name: str) -> str:
        n = name.lower()
        # date-stamped backups / snapshots
        if re.search(r"(_bkp|_backup|_back20|_snapshot_\d|_\d{6,8}|_20\d{2})", n):
            return "BACKUP_DATED"
        # explicit version suffixes
        if re.search(r"(_ver\d|_old|_todelete|_poc|_for_check|_qa_)", n):
            return "BACKUP_DATED"
        # personal / test
        if re.search(r"(_test_|_nitzan|_assaf|_eyal|_ofir|test_nitzan|_junk)", n):
            return "TEST_PERSONAL"
        # known deprecated (replaced upstream)
        if n in {
            "ext_dim_customer_history_credit",
            "ext_dim_customer_phoneverificationdetails",
            "ext_dim_customer_worldcheck",
            "ext_fsc_phoneverificationdetails",
            "ext_fsc_phoneverificationdetailscloseyear",
        }:
            return "DEPRECATED"
        # infrastructure / replication tracking
        if re.search(r"^(log_|replcheck_|datalake|dwh_tables|dimpositiondatalakeexec|datasolution)", n):
            return "INFRASTRUCTURE"
        # views
        if deployed.get(n) == "VIEW":
            return "VIEW"
        return "UNCLEAR"

    cat: dict[str, str] = {n: categorize(n) for n in prune_candidates}

    # ---- 3c) fetch row counts for prune candidates -------------------------
    print(f"Fetching row counts for {len(prune_candidates)} prune candidates...")
    row_counts: dict[str, int] = {}
    cur = conn.cursor()
    for i, tbl in enumerate(prune_candidates):
        if deployed.get(tbl) == "VIEW":
            row_counts[tbl] = -1  # skip views
            continue
        try:
            cur.execute(f"SELECT COUNT(*) FROM dwh_daily_process.migration_tables.`{tbl}`")
            n = cur.fetchone()[0]
            row_counts[tbl] = int(n)
        except Exception as exc:
            row_counts[tbl] = -2  # error
        if (i + 1) % 25 == 0:
            print(f"  {i+1}/{len(prune_candidates)}...")
    cur.close()
    conn.close()

    print(f"Matched (in schema AND written by an SP): {len(matched)}")
    print(f"Prune candidates (in schema but NO SP writes): {len(prune_candidates)}")
    print(f"Missing from lake (an SP writes but not deployed): {len(missing_from_lake)}")

    # ---- 4) write CSV ------------------------------------------------------
    csv_path = OUT_DIR / "migration_tables_audit.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow([
            "table_name", "table_type", "in_lake", "written_by_sps", "sp_count",
            "prune_category", "row_count", "last_altered",
        ])
        for tbl in sorted(deployed_set | sp_writes_set):
            in_lake = "Y" if tbl in deployed_set else "N"
            ttype = deployed.get(tbl, "")
            sps = sorted({sp for (sp, _act) in writes_by_table.get(tbl, set())})
            pc = cat.get(tbl, "") if tbl in prune_candidates else ""
            rc = row_counts.get(tbl, "")
            la = last_altered.get(tbl, "")
            w.writerow([tbl, ttype, in_lake, ";".join(sps), len(sps), pc, rc, la])
    print(f"CSV written: {csv_path}")

    # ---- 5) human-readable prune list --------------------------------------
    md_path = OUT_DIR / "PRUNE_LIST.md"
    with md_path.open("w", encoding="utf-8") as fh:
        fh.write("# `migration_tables` prune audit\n\n")
        fh.write(f"- SP files scanned: **{len(sp_files)}** ({SP_DIR})\n")
        fh.write(f"- Objects in `dwh_daily_process.migration_tables`: **{len(deployed)}** ")
        fh.write(f"({sum(1 for v in deployed.values() if v=='MANAGED')} tables, ")
        fh.write(f"{sum(1 for v in deployed.values() if v=='VIEW')} views)\n")
        fh.write(f"- Distinct write targets across all SPs: **{len(sp_writes_set)}**\n\n")

        fh.write("## A. Prune candidates — in lake, NO SP writes to them\n\n")
        fh.write(f"**{len(prune_candidates)} objects.** Review each — anything ")
        fh.write("recognizably test/backup/dated should be deleted.\n\n")
        # group by category, ordered safest-to-prune -> needs-review
        cat_order = ["BACKUP_DATED", "TEST_PERSONAL", "DEPRECATED",
                     "INFRASTRUCTURE", "VIEW", "UNCLEAR"]
        by_cat: dict[str, list[str]] = defaultdict(list)
        for tbl in prune_candidates:
            by_cat[cat.get(tbl, "UNCLEAR")].append(tbl)
        for c in cat_order:
            tbls = sorted(by_cat.get(c, []))
            if not tbls:
                continue
            fh.write(f"\n### A.{cat_order.index(c)+1} {c} ({len(tbls)})\n\n")
            fh.write("| # | table_name | type | row_count | last_altered |\n")
            fh.write("|---:|---|---|---:|---|\n")
            for i, tbl in enumerate(tbls, 1):
                rc = row_counts.get(tbl, "")
                if rc == -1:
                    rc_s = "(view)"
                elif rc == -2:
                    rc_s = "ERR"
                else:
                    rc_s = f"{rc:,}"
                la = last_altered.get(tbl, "")
                fh.write(f"| {i} | `{tbl}` | {deployed[tbl]} | {rc_s} | {la} |\n")

        fh.write("\n## B. In lake AND written by an SP (KEEP — definitely in use)\n\n")
        fh.write(f"**{len(matched)} objects.** No action required.\n\n")
        fh.write("| # | table_name | type | # SPs | sample SPs |\n|---:|---|---|---:|---|\n")
        for i, tbl in enumerate(matched, 1):
            sps = sorted({sp for (sp, _act) in writes_by_table.get(tbl, set())})
            sample = ", ".join(sps[:3])
            if len(sps) > 3:
                sample += f", … (+{len(sps)-3})"
            fh.write(f"| {i} | `{tbl}` | {deployed[tbl]} | {len(sps)} | {sample} |\n")

        fh.write("\n## C. Missing from lake — an SP writes but table is NOT deployed\n\n")
        fh.write(f"**{len(missing_from_lake)} tables.** These would cause runtime ")
        fh.write("errors when the SP is called. Separate issue from pruning.\n")
        fh.write(f"(Filtered out {len(missing_false_positives)} parser false ")
        fh.write("positives: CTE / temp-view names like `t`, `cte`, `temp_table_*`.)\n\n")
        if missing_from_lake:
            fh.write("| # | table_name | written by SP(s) |\n|---:|---|---|\n")
            for i, tbl in enumerate(missing_from_lake, 1):
                sps = sorted({sp for (sp, _act) in writes_by_table.get(tbl, set())})
                fh.write(f"| {i} | `{tbl}` | {', '.join(sps)} |\n")
        else:
            fh.write("_(none)_\n")
        if missing_false_positives:
            fh.write("\n<details><summary>Parser false positives (ignore)</summary>\n\n")
            fh.write("| name | seen in |\n|---|---|\n")
            for tbl in missing_false_positives:
                sps = sorted({sp for (sp, _act) in writes_by_table.get(tbl, set())})
                fh.write(f"| `{tbl}` | {', '.join(sps[:3])}{' …' if len(sps) > 3 else ''} |\n")
            fh.write("\n</details>\n")

    print(f"Prune report written: {md_path}")


if __name__ == "__main__":
    main()
