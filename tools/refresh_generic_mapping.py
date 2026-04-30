"""Refresh knowledge/synapse/Wiki/_generic_pipeline_mapping.json from Databricks.

Replaces the old paginated-markdown workflow at knowledge/synapse/Wiki/_refresh_mapping.py
with a single direct SQL fetch.

CRITICAL: The source view
  main.general.bronze_opsdb_dbo_vw_unitycatalog_mapping_tables
has MISALIGNED column headers — the column NAMES do not match the column POSITIONS
of the data values. The view is an EXEC of an underlying stored proc whose select-list
got out of sync with its CREATE VIEW header. Selecting by column name therefore returns
the WRONG values. This script uses SELECT * and pulls fields by KNOWN-CORRECT
positions (verified against UI 2026-04-30 against AlertServiceDB.Alert.Alert and
USABroker.Dictionary.AccountType).

Position map verified 2026-04-30. If the underlying proc/select changes, re-verify by:
  SELECT * FROM main.general.bronze_opsdb_dbo_vw_unitycatalog_mapping_tables
    WHERE DatabaseName='AlertServiceDB' AND SchemaName='Alert' AND TableName='Alert'
and confirm uc_table at position 33 = 'billing.bronze_alertservicedb_alert_alert'.

Usage:
    python tools/refresh_generic_mapping.py [--dry-run]

Auth: prefers env DATABRICKS_TOKEN (PAT). Falls back to databricks-oauth (browser).
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUTPUT = REPO / "knowledge" / "synapse" / "Wiki" / "_generic_pipeline_mapping.json"

# Field name -> 0-based column position in `SELECT *`. See module docstring re:
# why we cannot select by column name.
POSITION_MAP: dict[str, int] = {
    "generic_id":         0,
    "database_name":      1,
    "schema_name":        2,
    "table_name":         3,
    "server_name":        20,
    "copy_strategy":      17,
    "frequency_minutes":  12,
    "file_type":          16,
    "file_location":      19,
    "datalake_path":      31,
    "business_group":     32,
    "uc_table":           33,
    "source_type":        27,
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="Print row count, do not write file")
    args = parser.parse_args()

    from databricks import sql  # type: ignore

    host = os.environ.get("DATABRICKS_SERVER_HOSTNAME", "adb-5142916747090026.6.azuredatabricks.net")
    http_path = os.environ.get("DATABRICKS_HTTP_PATH", "/sql/1.0/warehouses/208214768b0e0308")
    token = (os.environ.get("DATABRICKS_TOKEN") or "").strip()

    if token:
        print("auth: PAT (DATABRICKS_TOKEN)")
        conn = sql.connect(server_hostname=host, http_path=http_path, access_token=token)
    else:
        print("auth: databricks-oauth (browser)")
        conn = sql.connect(server_hostname=host, http_path=http_path, auth_type="databricks-oauth")

    cur = conn.cursor()
    cur.execute(
        "SELECT * FROM main.general.bronze_opsdb_dbo_vw_unitycatalog_mapping_tables "
        "ORDER BY DatabaseName, SchemaName, TableName"
    )
    raw_rows = cur.fetchall()
    cur.close()
    conn.close()

    print(f"fetched {len(raw_rows)} rows")

    mappings: list[dict[str, str]] = []
    for r in raw_rows:
        row_d: dict[str, str] = {}
        for field, pos in POSITION_MAP.items():
            v = r[pos] if pos < len(r) else None
            row_d[field] = "" if v is None else str(v)
        mappings.append(row_d)

    # Sanity check: row 0 if it's the AlertServiceDB.Alert.Alert anchor we used to verify
    sanity = next(
        (m for m in mappings
         if m["database_name"] == "AlertServiceDB" and m["schema_name"] == "Alert" and m["table_name"] == "Alert"),
        None,
    )
    if sanity is not None:
        expected = "billing.bronze_alertservicedb_alert_alert"
        if sanity["uc_table"] != expected:
            print(
                f"WARNING: position-map sanity check failed. "
                f"AlertServiceDB.Alert.Alert.uc_table={sanity['uc_table']!r}, expected {expected!r}. "
                f"View column layout may have changed — re-verify POSITION_MAP."
            )
        else:
            print(f"position-map sanity check: PASS (anchor row uc_table={sanity['uc_table']!r})")
    else:
        print("(no AlertServiceDB.Alert.Alert anchor row found; skipping sanity check)")

    if args.dry_run:
        print("(dry-run: not writing file)")
        return 0

    payload = {
        "_metadata": {
            "source": "main.general.bronze_opsdb_dbo_vw_unitycatalog_mapping_tables",
            "description": "Static backup of Generic Pipeline mapping. Fallback for Phase 13 when Databricks MCP is unavailable.",
            "row_count": len(mappings),
            "exported_at": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
            "exported_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "refresh_instruction": "python tools/refresh_generic_mapping.py",
            "extraction_method": "SELECT * with position-based field map (view header names do not match column positions; see tools/refresh_generic_mapping.py docstring).",
        },
        "mappings": mappings,
    }

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(f"wrote {OUTPUT.relative_to(REPO)} ({len(mappings)} rows)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
