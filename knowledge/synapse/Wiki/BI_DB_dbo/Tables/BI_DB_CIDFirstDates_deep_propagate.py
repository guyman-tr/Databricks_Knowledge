"""Deep lineage propagation for BI_DB_dbo.BI_DB_CIDFirstDates."""
import sys, os
sys.stdout.reconfigure(line_buffering=True)
sys.path.insert(0, os.path.normpath(os.path.join(os.path.dirname(__file__), "../..")))
import _deep_propagate_lib as lib

SOURCE_UC = "main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates"
SOURCE_SYNAPSE = "BI_DB_dbo.BI_DB_CIDFirstDates"
OBJECT_DIR = os.path.dirname(os.path.abspath(__file__))
OBJECT_NAME = "BI_DB_CIDFirstDates"

TREE_PATH = os.path.join(OBJECT_DIR, f"{OBJECT_NAME}.lineage-tree.json")
PROGRESS_PATH = os.path.join(OBJECT_DIR, f"{OBJECT_NAME}.propagation-progress.json")
ALTER_SQL_PATH = os.path.join(OBJECT_DIR, f"{OBJECT_NAME}.alter.sql")
DOWNSTREAM_PATH = os.path.join(OBJECT_DIR, f"{OBJECT_NAME}.downstream.alter.sql")
SCOPE_PATH = os.path.join(OBJECT_DIR, f"{OBJECT_NAME}.propagation-scope.md")

def main():
    import argparse
    parser = argparse.ArgumentParser(description=f"Deep propagation: {SOURCE_SYNAPSE}")
    parser.add_argument("command", choices=["discover", "execute", "both"],
                        help="discover=build lineage tree, execute=run ALTER statements, both=full run")
    parser.add_argument("--batch-size", type=int, default=lib.DEFAULT_BATCH_SIZE)
    parser.add_argument("--schema-filter", type=str, default=None,
                        help="Comma-separated schema list to limit execution (e.g., main.bi_output,main.etoro_kpi)")
    args = parser.parse_args()

    blacklist = lib.load_blacklist()
    print(f"Blacklist: {len(blacklist)} columns")

    source_descs = lib.load_source_descriptions(ALTER_SQL_PATH)
    if not source_descs:
        print("ERROR: No source descriptions found. Run the main documentation pipeline first.")
        sys.exit(1)

    if args.command in ("discover", "both"):
        print(f"\n=== DISCOVER: {SOURCE_SYNAPSE} ===")
        lib.discover_tree(SOURCE_UC, SOURCE_SYNAPSE, source_descs, blacklist, TREE_PATH)
        lib.generate_scope_report(TREE_PATH, SCOPE_PATH, source_descs, blacklist, args.batch_size)

    if args.command in ("execute", "both"):
        print(f"\n=== EXECUTE: {SOURCE_SYNAPSE} ===")
        if not os.path.isfile(TREE_PATH):
            print("ERROR: No lineage tree found. Run 'discover' first.")
            sys.exit(1)
        sf = set(args.schema_filter.split(",")) if args.schema_filter else None
        lib.execute_batches(TREE_PATH, PROGRESS_PATH, args.batch_size, sf)
        lib.generate_downstream_alter_sql(TREE_PATH, DOWNSTREAM_PATH, SOURCE_SYNAPSE)

    lib.close_connection()
    print("\nDone.")

if __name__ == "__main__":
    main()
