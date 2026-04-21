"""Deep lineage propagation for DWH_dbo.V_Fact_SnapshotEquity_FromDateID."""
import sys, os
sys.stdout.reconfigure(line_buffering=True)
sys.path.insert(0, os.path.normpath(os.path.join(os.path.dirname(__file__), "../..")))
import _deep_propagate_lib as lib

SOURCE_UC = "main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid"
SOURCE_SYNAPSE = "DWH_dbo.V_Fact_SnapshotEquity_FromDateID"
OBJECT_DIR = os.path.dirname(os.path.abspath(__file__))
OBJECT_NAME = "V_Fact_SnapshotEquity_FromDateID"

TREE_PATH      = os.path.join(OBJECT_DIR, f"{OBJECT_NAME}.lineage-tree.json")
PROGRESS_PATH  = os.path.join(OBJECT_DIR, f"{OBJECT_NAME}.propagation-progress.json")
ALTER_SQL_PATH  = os.path.join(OBJECT_DIR, f"{OBJECT_NAME}.alter.sql")
DOWNSTREAM_PATH = os.path.join(OBJECT_DIR, f"{OBJECT_NAME}.downstream.alter.sql")
SCOPE_PATH      = os.path.join(OBJECT_DIR, f"{OBJECT_NAME}.propagation-scope.md")

def main():
    import argparse
    parser = argparse.ArgumentParser(description=f"Deep propagation: {SOURCE_SYNAPSE}")
    parser.add_argument("command", choices=["discover", "execute", "both"])
    parser.add_argument("--batch-size", type=int, default=lib.DEFAULT_BATCH_SIZE)
    parser.add_argument("--schema-filter", type=str, default=None)
    parser.add_argument("--include-uc-lineage", action="store_true")
    args = parser.parse_args()

    blacklist = lib.load_blacklist()
    print(f"Blacklist: {len(blacklist)} columns")

    source_descs = lib.load_source_descriptions(ALTER_SQL_PATH)
    if not source_descs:
        print("ERROR: No source descriptions found.")
        sys.exit(1)

    if args.command in ("discover", "both"):
        print(f"\n=== DISCOVER: {SOURCE_SYNAPSE} ===")
        lib.discover_tree(SOURCE_UC, SOURCE_SYNAPSE, source_descs, blacklist, TREE_PATH,
                          include_uc_lineage=args.include_uc_lineage)
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
