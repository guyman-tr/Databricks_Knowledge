"""
Broadcast Propagation for Blacklisted ETL Columns.

Standalone script that propagates canonical descriptions for ubiquitous
ETL infrastructure columns (etr_ymd, UpdateDate, etc.) across ALL instances
in the Unity Catalog, independent of the per-table pipeline.

Usage:
  python _broadcast_propagate.py              # execute
  python _broadcast_propagate.py --dry-run    # preview without executing
"""

import sys, os, json, argparse
from datetime import datetime, timezone

sys.stdout.reconfigure(line_buffering=True)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _deep_propagate_lib as lib

BROADCAST_BATCH_SIZE = 100
LOG_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_broadcast_propagation.log")


def find_all_instances(column_name: str, cursor) -> list:
    """Find all tables/views containing this column across the catalog."""
    query = f"""\
        SELECT table_catalog, table_schema, table_name, table_type
        FROM system.information_schema.columns
        WHERE LOWER(column_name) = '{column_name.lower()}'
          AND table_schema != 'information_schema'
    """
    try:
        cursor.execute(query)
        rows = cursor.fetchall()
    except Exception as e:
        print(f"  WARNING: Column search failed for {column_name}: {e}")
        return []

    results = []
    for row in rows:
        catalog, schema, table, ttype = row[0], row[1], row[2], row[3]
        if catalog.startswith("__databricks_internal"):
            continue
        full_name = f"{catalog}.{schema}.{table}"
        is_view = "VIEW" in str(ttype).upper()
        results.append({"full_name": full_name, "is_view": is_view})

    return results


def broadcast(dry_run: bool = False):
    blacklist_entries = lib.load_blacklist_full()
    if not blacklist_entries:
        print("No blacklist entries found in config.")
        return

    print(f"Broadcast propagation for {len(blacklist_entries)} blacklisted columns")
    print(f"Mode: {'DRY RUN' if dry_run else 'EXECUTE'}")
    print()

    conn = lib.get_connection()
    cursor = conn.cursor()

    log_lines = []
    log_lines.append(f"Broadcast Propagation Log — {datetime.now(timezone.utc).isoformat()}")
    log_lines.append(f"Mode: {'DRY RUN' if dry_run else 'EXECUTE'}")
    log_lines.append("")

    total_succeeded = 0
    total_failed = 0
    total_skipped = 0

    for entry in blacklist_entries:
        col_name = entry["column_name"]
        description = entry["canonical_description"]
        category = entry.get("category", "unknown")

        print(f"  {col_name} ({category})...")
        instances = find_all_instances(col_name, cursor)
        print(f"    Found {len(instances)} instances")

        log_lines.append(f"## {col_name} ({category})")
        log_lines.append(f"  Instances: {len(instances)}")
        log_lines.append(f"  Description: {description}")

        if dry_run:
            log_lines.append(f"  DRY RUN — would generate {len(instances)} ALTER statements")
            log_lines.append("")
            continue

        succeeded = 0
        failed = 0
        errors = []

        batches = [instances[i:i + BROADCAST_BATCH_SIZE]
                   for i in range(0, len(instances), BROADCAST_BATCH_SIZE)]

        for batch_idx, batch in enumerate(batches):
            for inst in batch:
                full_name = inst["full_name"]
                desc_escaped = description.replace("'", "''")

                if inst["is_view"]:
                    stmt = f"COMMENT ON COLUMN {full_name}.`{col_name}` IS '{desc_escaped}'"
                else:
                    stmt = f"ALTER TABLE {full_name} ALTER COLUMN `{col_name}` COMMENT '{desc_escaped}'"

                try:
                    cursor.execute(stmt)
                    succeeded += 1
                except Exception as e:
                    failed += 1
                    err_msg = str(e)[:150]
                    errors.append(f"    FAIL {full_name}: {err_msg}")

            print(f"    Batch {batch_idx + 1}/{len(batches)}: processed")

        total_succeeded += succeeded
        total_failed += failed

        log_lines.append(f"  Succeeded: {succeeded}")
        log_lines.append(f"  Failed: {failed}")
        for err in errors[:10]:
            log_lines.append(err)
        if len(errors) > 10:
            log_lines.append(f"    ... and {len(errors) - 10} more errors")
        log_lines.append("")

    cursor.close()
    lib.close_connection()

    log_lines.append("---")
    log_lines.append(f"Total succeeded: {total_succeeded}")
    log_lines.append(f"Total failed: {total_failed}")

    with open(LOG_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(log_lines))

    print(f"\nBroadcast complete:")
    print(f"  Succeeded: {total_succeeded}")
    print(f"  Failed: {total_failed}")
    print(f"  Log: {LOG_PATH}")


def main():
    parser = argparse.ArgumentParser(description="Broadcast propagation for blacklisted ETL columns")
    parser.add_argument("--dry-run", action="store_true",
                        help="Preview ALTER counts without executing")
    args = parser.parse_args()
    broadcast(dry_run=args.dry_run)


if __name__ == "__main__":
    main()
