#!/usr/bin/env python3
"""
propagate_upstream_cols.py — Phase 1: Upstream Column Fill

For every DWH view UC target, propagate the upstream base table's column
descriptions (COMMENT + PII tag) to the view's UC path.

Idempotent: skips columns already present in the view's alter.sql file.

Phase 2 (deep-lineage downstream propagation) is a separate run AFTER this
script completes and its deployments are live in UC.

Usage:
    cd Databricks_Knowledge
    python tools/propagate_upstream_cols.py          # OAuth (browser popup once)
    DATABRICKS_TOKEN=dapi... python tools/propagate_upstream_cols.py  # PAT
"""

import re
import os
from datetime import datetime, timezone
from databricks import sql

# ── Connection ────────────────────────────────────────────────────────────────

SERVER_HOSTNAME = "adb-5142916747090026.6.azuredatabricks.net"
HTTP_PATH       = "/sql/1.0/warehouses/208214768b0e0308"
REPO_ROOT       = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
NOW             = datetime.now(timezone.utc).strftime("%Y-%m-%d")


# ── Column data extraction ────────────────────────────────────────────────────

def parse_source_cols(path: str, is_stub: bool = False) -> dict:
    """
    Parse an ALTER script and return:
        {col_lower: {'col': original_case_str, 'comment': sql_escaped_str, 'pii': str}}

    is_stub=True: also parse lines that start with '-- ALTER TABLE' (commented-out
    stub lines), allowing data recovery from stub files.

    The returned 'comment' value is already SQL-escaped ('' for embedded single quotes),
    ready for direct insertion into an ALTER COLUMN COMMENT '...' statement.
    """
    comment_re = re.compile(
        r"ALTER TABLE\s+\S+\s+ALTER COLUMN\s+`?(\w+)`?\s+COMMENT\s+'((?:[^']|'')*)'",
        re.IGNORECASE,
    )
    pii_re = re.compile(
        r"ALTER TABLE\s+\S+\s+ALTER COLUMN\s+`?(\w+)`?\s+SET TAGS\s+\('pii'\s*=\s*'(\w+)'\)",
        re.IGNORECASE,
    )

    result: dict = {}

    with open(os.path.join(REPO_ROOT, path), encoding="utf-8") as fh:
        for raw in fh:
            line = raw.strip()

            if line.startswith("--"):
                if is_stub:
                    # Strip leading "-- " so the ALTER TABLE pattern can match
                    line = re.sub(r"^--\s*", "", line)
                else:
                    continue

            m = comment_re.search(line)
            if m:
                col, comment = m.group(1), m.group(2)
                entry = result.setdefault(
                    col.lower(), {"col": col, "comment": None, "pii": "none"}
                )
                entry["comment"] = comment
                entry["col"] = col  # keep canonical case from first occurrence
                continue

            m = pii_re.search(line)
            if m:
                col, pii = m.group(1), m.group(2)
                entry = result.setdefault(
                    col.lower(), {"col": col, "comment": None, "pii": "none"}
                )
                entry["pii"] = pii

    return {k: v for k, v in result.items() if v["comment"] is not None}


def get_deployed_cols_in_file(view_alter_path: str, uc_table: str) -> set:
    """
    Return set of col_lower strings that already have an ALTER COLUMN statement
    for the given uc_table in the view alter file.  Used to avoid duplicate appends.
    """
    pattern = re.compile(
        rf"ALTER TABLE\s+{re.escape(uc_table)}\s+ALTER COLUMN\s+`?(\w+)`?",
        re.IGNORECASE,
    )
    found: set = set()
    full_path = os.path.join(REPO_ROOT, view_alter_path)
    if not os.path.exists(full_path):
        return found
    with open(full_path, encoding="utf-8") as fh:
        for line in fh:
            m = pattern.search(line)
            if m:
                found.add(m.group(1).lower())
    return found


def describe_cols(cursor, uc_table: str) -> list:
    """
    Return list of column names (original case) present in the UC table/view.
    Filters out DESCRIBE metadata rows (those starting with '#' or empty string).
    """
    cursor.execute(f"DESCRIBE TABLE {uc_table}")
    rows = cursor.fetchall()
    cols = []
    for row in rows:
        col_name = str(row[0]).strip() if row[0] else ""
        if col_name and not col_name.startswith("#"):
            cols.append(col_name)
    return cols


# ── Job definitions ───────────────────────────────────────────────────────────
#
# source_path   : ALTER script whose column COMMENT + SET TAGS lines are the source
# is_stub       : True = parse commented-out lines (-- ALTER TABLE ...) from stub files
# view_alter    : View's .alter.sql file to append new statements to
# uc_targets    : One or more UC fully-qualified table/view paths to update
# base_name     : Human-readable name of the upstream base table (for file headers)

JOBS = [
    # ── Job 1: V_Fact_SnapshotCustomer → pii_data unmasked view ──────────────
    # V_Fact_SnapshotCustomer.alter.sql has only DateKey; needs all 52 FSC cols.
    {
        "name": "V_Fact_SnapshotCustomer → pii_data",
        "source_path": "knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.alter.sql",
        "is_stub": False,
        "view_alter": "knowledge/synapse/Wiki/DWH_dbo/Views/V_Fact_SnapshotCustomer.alter.sql",
        "uc_targets": [
            "main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer",
        ],
        "base_name": "Fact_SnapshotCustomer",
    },

    # ── Job 2: V_Fact_SnapshotCustomer_FromDateID → masked + pii_data ────────
    # Masked target already has 52 cols deployed via Fact_SnapshotCustomer.alter.sql;
    # this run appends them to the VIEW alter file (idempotent re-deploy to UC).
    # pii_data target has only FromDateID + ToDateID; needs 52 FSC cols.
    {
        "name": "V_Fact_SnapshotCustomer_FromDateID → masked + pii_data",
        "source_path": "knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.alter.sql",
        "is_stub": False,
        "view_alter": "knowledge/synapse/Wiki/DWH_dbo/Views/V_Fact_SnapshotCustomer_FromDateID.alter.sql",
        "uc_targets": [
            "main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked",
            "main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid",
        ],
        "base_name": "Fact_SnapshotCustomer",
    },

    # ── Job 3: V_Fact_SnapshotEquity_FromDateID → dwh ────────────────────────
    # Fact_SnapshotEquity has no direct UC path; its 32 columns are propagated
    # to the sibling view V_Fact_SnapshotEquity_FromDateID (generic_id=1121).
    # Source is the stub alter.sql (commented-out lines); all cols are pii=none.
    {
        "name": "V_Fact_SnapshotEquity_FromDateID → dwh",
        "source_path": "knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotEquity.alter.sql",
        "is_stub": True,  # parse commented-out "-- ALTER TABLE" lines from stub
        "view_alter": "knowledge/synapse/Wiki/DWH_dbo/Views/V_Fact_SnapshotEquity_FromDateID.alter.sql",
        "uc_targets": [
            "main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid",
        ],
        "base_name": "Fact_SnapshotEquity",
    },

    # ── Job 4: v_Dim_Mirror → dwh ─────────────────────────────────────────────
    # v_Dim_Mirror.alter.sql has only snapshot_date; needs all 26 Dim_Mirror cols.
    {
        "name": "v_Dim_Mirror → dwh",
        "source_path": "knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Mirror.alter.sql",
        "is_stub": False,
        "view_alter": "knowledge/synapse/Wiki/DWH_dbo/Views/v_Dim_Mirror.alter.sql",
        "uc_targets": [
            "main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_dim_mirror",
        ],
        "base_name": "Dim_Mirror",
    },
]


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    token = os.environ.get("DATABRICKS_TOKEN")
    if token:
        conn = sql.connect(
            server_hostname=SERVER_HOSTNAME,
            http_path=HTTP_PATH,
            access_token=token,
        )
        print("Connected via PAT.")
    else:
        conn = sql.connect(
            server_hostname=SERVER_HOSTNAME,
            http_path=HTTP_PATH,
            auth_type="databricks-oauth",
        )
        print("Connected via OAuth (browser tab may open).")

    cursor = conn.cursor()
    grand_total_deployed = 0
    grand_total_failed = 0

    for job in JOBS:
        print(f"\n{'='*60}")
        print(f"JOB: {job['name']}")
        print(f"{'='*60}")

        # Step 1 — Load wiki column data from source alter.sql
        wiki_cols = parse_source_cols(job["source_path"], job["is_stub"])
        print(f"  Parsed {len(wiki_cols)} columns from: {job['source_path']}")
        if not wiki_cols:
            print("  WARNING: No columns parsed — skipping job.")
            continue

        # Step 2 — Process each UC target
        job_appends: list[tuple[str, list, list]] = []  # (uc_table, comment_stmts, tag_stmts)

        for uc_table in job["uc_targets"]:
            print(f"\n  ── Target: {uc_table}")

            # Check what is already in the view alter file for this target
            already_in_file = get_deployed_cols_in_file(job["view_alter"], uc_table)
            print(f"     Already in view alter file: {len(already_in_file)} col(s)")

            # DESCRIBE UC table to get actual column list
            try:
                uc_cols = describe_cols(cursor, uc_table)
                print(f"     UC columns discovered:      {len(uc_cols)}")
            except Exception as e:
                print(f"     ERROR describing {uc_table}: {e}")
                continue

            # Build statements for columns not already in the file
            comment_stmts: list[tuple[str, str]] = []  # (col_name, sql)
            tag_stmts:     list[tuple[str, str]] = []

            for uc_col in uc_cols:
                col_lower = uc_col.lower()
                if col_lower in already_in_file:
                    continue  # Already documented in file — skip
                if col_lower not in wiki_cols:
                    continue  # No description available for this column

                data    = wiki_cols[col_lower]
                comment = data["comment"]  # already SQL-escaped with '' for embedded '
                pii     = data["pii"]

                comment_stmts.append(
                    (uc_col, f"ALTER TABLE {uc_table} ALTER COLUMN `{uc_col}` COMMENT '{comment}';")
                )
                tag_stmts.append(
                    (uc_col, f"ALTER TABLE {uc_table} ALTER COLUMN `{uc_col}` SET TAGS ('pii' = '{pii}');")
                )

            total_stmts = len(comment_stmts) + len(tag_stmts)
            print(f"     Statements to deploy:       {total_stmts}  ({len(comment_stmts)} COMMENT + {len(tag_stmts)} SET TAGS)")

            if not comment_stmts and not tag_stmts:
                print("     Nothing to do — all columns already in file.")
                continue

            # Step 3 — Deploy
            target_succeeded = 0
            target_failed    = 0

            for col, stmt in comment_stmts:
                try:
                    cursor.execute(stmt)
                    target_succeeded += 1
                except Exception as e:
                    print(f"     FAILED [{col} COMMENT]: {e}")
                    target_failed += 1

            for col, stmt in tag_stmts:
                try:
                    cursor.execute(stmt)
                    target_succeeded += 1
                except Exception as e:
                    print(f"     FAILED [{col} SET TAGS]: {e}")
                    target_failed += 1

            grand_total_deployed += target_succeeded
            grand_total_failed   += target_failed
            print(f"     Result: {target_succeeded} succeeded / {target_failed} failed")

            job_appends.append((uc_table, comment_stmts, tag_stmts, target_succeeded, target_failed))

        # Step 4 — Append new statements to the view alter file
        if job_appends:
            view_alter_full = os.path.join(REPO_ROOT, job["view_alter"])
            with open(view_alter_full, "a", encoding="utf-8") as fh:
                for (uc_table, comment_stmts, tag_stmts, succeeded, failed) in job_appends:
                    if not comment_stmts and not tag_stmts:
                        continue
                    fh.write(f"\n-- ============================================================\n")
                    fh.write(f"-- Inherited from {job['base_name']} (propagated {NOW})\n")
                    fh.write(f"-- Target: {uc_table}\n")
                    fh.write(f"-- {len(comment_stmts)} column(s) | source: {job['source_path']}\n")
                    fh.write(f"-- ============================================================\n")
                    fh.write(f"\n-- ---- Column Comments (inherited) ----\n")
                    for _, stmt in comment_stmts:
                        fh.write(stmt + "\n")
                    fh.write(f"\n-- ---- Column PII Tags (inherited) ----\n")
                    for _, stmt in tag_stmts:
                        fh.write(stmt + "\n")
                    fh.write(f"\n-- == PROPAGATION EXECUTION ==\n")
                    fh.write(f"-- Timestamp: {NOW} UTC\n")
                    fh.write(f"-- Statements: {succeeded}/{succeeded + failed} succeeded\n")
                    fh.write(f"-- ====================\n")
            print(f"\n  Appended to: {job['view_alter']}")

    cursor.close()
    conn.close()

    print(f"\n{'='*60}")
    print(f"PHASE 1 COMPLETE")
    print(f"  Total deployed : {grand_total_deployed}")
    print(f"  Total failed   : {grand_total_failed}")
    print(f"")
    print(f"NEXT STEP — Phase 2: deep-lineage downstream propagation.")
    print(f"Run the _deep_propagate_lib.py machinery from each of these")
    print(f"5 UC starting points to propagate descriptions to their")
    print(f"downstream consumers:")
    print(f"  main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer")
    print(f"  main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked")
    print(f"  main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid")
    print(f"  main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid")
    print(f"  main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_dim_mirror")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
