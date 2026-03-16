"""
Bottom-Up Deep Lineage Propagation Orchestrator.

Scans all documented Synapse tables (those with .alter.sql files),
sorts them by dependency depth (bottom-up: shallowest first), and
runs discover_tree() + execute_batches() for each in order.

Usage:
    python _run_bottom_up.py                     # full run (discover + execute)
    python _run_bottom_up.py --dry-run            # discover only, no execute
    python _run_bottom_up.py --resume             # skip already-completed tables
    python _run_bottom_up.py --batch-size 50      # custom batch size
    python _run_bottom_up.py --table DWH_dbo.Dim_Position  # single table only
"""
import sys, os, json, argparse, glob, time
from datetime import datetime, timezone

sys.stdout.reconfigure(line_buffering=True)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _deep_propagate_lib as lib

WIKI_ROOT = os.path.dirname(os.path.abspath(__file__))
REPORT_PATH = os.path.join(WIKI_ROOT, "_bottom_up_report.md")


def scan_documented_tables() -> list:
    """
    Walk Wiki/*/Tables/ for *.alter.sql files (excluding *.downstream.alter.sql).
    Returns list of dicts: {alter_sql_path, object_dir, object_name, uc_target, synapse_source}.
    """
    pattern = os.path.join(WIKI_ROOT, "*", "Tables", "*.alter.sql")
    found = []

    for path in glob.glob(pattern):
        basename = os.path.basename(path)
        if basename.endswith(".downstream.alter.sql"):
            continue

        object_name = basename.replace(".alter.sql", "")
        object_dir = os.path.dirname(path)

        meta = lib.parse_alter_sql_metadata(path)
        if not meta["uc_target"] or not meta["synapse_source"]:
            print(f"  SKIP: {basename} — missing UC Target or Synapse Source in header")
            continue

        found.append({
            "alter_sql_path": path,
            "object_dir": object_dir,
            "object_name": object_name,
            "uc_target": meta["uc_target"],
            "synapse_source": meta["synapse_source"],
        })

    return found


def load_dependency_depths() -> dict:
    """
    Read _dependency_order.json and return {synapse_name_lower: depth}.
    """
    dep_path = lib.DEPENDENCY_ORDER_PATH
    if not os.path.isfile(dep_path):
        print(f"  WARNING: {dep_path} not found — all tables will have depth 0")
        return {}

    with open(dep_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    return {obj["table"].lower(): obj.get("depth", 0) for obj in data}


def sort_by_depth(tables: list, depths: dict) -> list:
    """Sort tables by dependency depth ascending (shallowest first = bottom-up)."""
    for t in tables:
        syn_lower = t["synapse_source"].lower()
        t["depth"] = depths.get(syn_lower, 0)

    return sorted(tables, key=lambda t: (t["depth"], t["synapse_source"]))


def is_already_completed(object_dir: str, object_name: str) -> bool:
    """Check if a table's propagation progress shows all batches completed."""
    progress_path = os.path.join(object_dir, f"{object_name}.propagation-progress.json")
    if not os.path.isfile(progress_path):
        return False

    try:
        with open(progress_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        total = data.get("total_batches", 0)
        completed = data.get("completed_batches", 0)
        return total > 0 and completed >= total
    except Exception:
        return False


def run_table(table: dict, batch_size: int, dry_run: bool,
              include_uc_lineage: bool = False) -> dict:
    """
    Run discover + execute for a single table.
    Returns a result dict for the summary report.
    """
    result = {
        "synapse_source": table["synapse_source"],
        "uc_target": table["uc_target"],
        "depth": table["depth"],
        "status": "pending",
        "downstream_objects": 0,
        "column_matches": 0,
        "renames": 0,
        "statements_succeeded": 0,
        "statements_failed": 0,
        "elapsed_seconds": 0,
        "error": "",
    }

    object_dir = table["object_dir"]
    object_name = table["object_name"]
    tree_path = os.path.join(object_dir, f"{object_name}.lineage-tree.json")
    progress_path = os.path.join(object_dir, f"{object_name}.propagation-progress.json")
    downstream_path = os.path.join(object_dir, f"{object_name}.downstream.alter.sql")
    scope_path = os.path.join(object_dir, f"{object_name}.propagation-scope.md")
    alter_sql_path = table["alter_sql_path"]

    blacklist = lib.load_blacklist()
    source_descs = lib.load_source_descriptions(alter_sql_path)

    if not source_descs:
        result["status"] = "skipped"
        result["error"] = "No source descriptions found in .alter.sql"
        return result

    start = time.time()

    try:
        print(f"\n{'='*70}")
        print(f"  DISCOVER: {table['synapse_source']} (depth {table['depth']})")
        print(f"  UC: {table['uc_target']}")
        print(f"{'='*70}")

        tree = lib.discover_tree(
            table["uc_target"],
            table["synapse_source"],
            source_descs,
            blacklist,
            tree_path,
            include_uc_lineage=include_uc_lineage,
        )
        lib.generate_scope_report(tree_path, scope_path, source_descs, blacklist, batch_size)

        result["downstream_objects"] = tree.total_downstream_objects
        result["column_matches"] = tree.total_column_matches
        result["renames"] = tree.total_renames

        if dry_run:
            result["status"] = "discovered"
        else:
            print(f"\n  EXECUTE: {table['synapse_source']}")
            all_stmts, progress = lib.execute_batches(tree_path, progress_path, batch_size)
            lib.generate_downstream_alter_sql(tree_path, downstream_path, table["synapse_source"])

            total_succeeded = sum(
                b.get("statements_succeeded", 0) for b in progress.batches
            )
            total_failed = sum(
                b.get("statements_failed", 0) for b in progress.batches
            )
            result["statements_succeeded"] = total_succeeded
            result["statements_failed"] = total_failed
            result["status"] = "completed"

    except Exception as e:
        result["status"] = "failed"
        result["error"] = str(e)[:500]
        print(f"  ERROR: {e}")

    result["elapsed_seconds"] = round(time.time() - start, 1)
    return result


def write_summary_report(results: list, total_elapsed: float, dry_run: bool):
    """Write _bottom_up_report.md summarizing the full run."""
    lines = []
    lines.append("# Bottom-Up Deep Lineage Propagation Report")
    lines.append("")
    mode = "DRY RUN (discover only)" if dry_run else "FULL RUN (discover + execute)"
    lines.append(f"**Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M')} | Mode: {mode}")
    lines.append(f"**Total elapsed**: {total_elapsed:.0f}s ({total_elapsed/60:.1f} min)")
    lines.append(f"**Tables processed**: {len(results)}")
    lines.append("")

    total_objects = sum(r["downstream_objects"] for r in results)
    total_matches = sum(r["column_matches"] for r in results)
    total_renames = sum(r["renames"] for r in results)
    total_succeeded = sum(r["statements_succeeded"] for r in results)
    total_failed = sum(r["statements_failed"] for r in results)

    lines.append("## Summary")
    lines.append("")
    lines.append("| Metric | Value |")
    lines.append("|--------|-------|")
    lines.append(f"| Tables processed | {len(results)} |")
    lines.append(f"| Downstream objects discovered | {total_objects} |")
    lines.append(f"| Column matches (identical) | {total_matches} |")
    lines.append(f"| Renames detected | {total_renames} |")
    if not dry_run:
        lines.append(f"| Statements succeeded | {total_succeeded} |")
        lines.append(f"| Statements failed | {total_failed} |")
    lines.append("")

    lines.append("## Per-Table Results")
    lines.append("")
    if dry_run:
        lines.append("| # | Table | Depth | Downstream | Matches | Renames | Time | Status |")
        lines.append("|---|-------|-------|------------|---------|---------|------|--------|")
    else:
        lines.append("| # | Table | Depth | Downstream | Matches | Renames | Succeeded | Failed | Time | Status |")
        lines.append("|---|-------|-------|------------|---------|---------|-----------|--------|------|--------|")

    for i, r in enumerate(results, 1):
        if dry_run:
            lines.append(
                f"| {i} | `{r['synapse_source']}` | {r['depth']} "
                f"| {r['downstream_objects']} | {r['column_matches']} "
                f"| {r['renames']} | {r['elapsed_seconds']}s | {r['status']} |"
            )
        else:
            lines.append(
                f"| {i} | `{r['synapse_source']}` | {r['depth']} "
                f"| {r['downstream_objects']} | {r['column_matches']} "
                f"| {r['renames']} | {r['statements_succeeded']} "
                f"| {r['statements_failed']} | {r['elapsed_seconds']}s | {r['status']} |"
            )
    lines.append("")

    failed_tables = [r for r in results if r["status"] == "failed"]
    if failed_tables:
        lines.append("## Failures")
        lines.append("")
        for r in failed_tables:
            lines.append(f"### {r['synapse_source']}")
            lines.append(f"```\n{r['error']}\n```")
            lines.append("")

    skipped = [r for r in results if r["status"] == "skipped"]
    if skipped:
        lines.append("## Skipped Tables")
        lines.append("")
        for r in skipped:
            lines.append(f"- `{r['synapse_source']}` — {r['error']}")
        lines.append("")

    with open(REPORT_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"\n  Summary report: {REPORT_PATH}")


def main():
    parser = argparse.ArgumentParser(
        description="Bottom-up deep lineage propagation for all documented Synapse tables"
    )
    parser.add_argument("--dry-run", action="store_true",
                        help="Discover only — no execute")
    parser.add_argument("--resume", action="store_true",
                        help="Skip tables that already have completed propagation progress")
    parser.add_argument("--batch-size", type=int, default=lib.DEFAULT_BATCH_SIZE,
                        help=f"Batch size for execution (default: {lib.DEFAULT_BATCH_SIZE})")
    parser.add_argument("--table", type=str, default=None,
                        help="Process a single table only (Synapse name, e.g. DWH_dbo.Dim_Position)")
    parser.add_argument("--include-uc-lineage", action="store_true",
                        help="Also query system.access.column_lineage (slow, usually not needed for DWH tables)")
    args = parser.parse_args()

    print("=" * 70)
    print("  BOTTOM-UP DEEP LINEAGE PROPAGATION")
    print(f"  Mode: {'DRY RUN' if args.dry_run else 'FULL RUN'}")
    print(f"  Resume: {args.resume}")
    print(f"  Batch size: {args.batch_size}")
    if args.table:
        print(f"  Single table: {args.table}")
    print(f"  UC lineage: {'ENABLED' if args.include_uc_lineage else 'DISABLED (DWH default)'}")
    print("=" * 70)

    # Step 1: Scan for documented tables
    print("\n[1/4] Scanning for documented tables...")
    tables = scan_documented_tables()
    print(f"  Found {len(tables)} documented tables")

    if not tables:
        print("  No documented tables found. Run the Phase 1-14 pipeline first.")
        sys.exit(0)

    # Step 2: Load dependency depths and sort
    print("\n[2/4] Loading dependency order...")
    depths = load_dependency_depths()
    tables = sort_by_depth(tables, depths)

    for t in tables:
        print(f"  depth {t['depth']}: {t['synapse_source']} -> {t['uc_target']}")

    # Filter to single table if specified
    if args.table:
        tables = [t for t in tables if t["synapse_source"].lower() == args.table.lower()]
        if not tables:
            print(f"\n  ERROR: Table '{args.table}' not found among documented tables.")
            sys.exit(1)

    # Step 3: Process each table in order
    print(f"\n[3/4] Processing {len(tables)} tables in dependency order...")
    results = []
    total_start = time.time()

    for idx, table in enumerate(tables, 1):
        print(f"\n{'#'*70}")
        print(f"  TABLE {idx}/{len(tables)}: {table['synapse_source']} (depth {table['depth']})")
        print(f"{'#'*70}")

        if args.resume and is_already_completed(table["object_dir"], table["object_name"]):
            print(f"  SKIPPED — already completed (--resume)")
            results.append({
                "synapse_source": table["synapse_source"],
                "uc_target": table["uc_target"],
                "depth": table["depth"],
                "status": "skipped_resume",
                "downstream_objects": 0,
                "column_matches": 0,
                "renames": 0,
                "statements_succeeded": 0,
                "statements_failed": 0,
                "elapsed_seconds": 0,
                "error": "Skipped (already completed)",
            })
            continue

        result = run_table(table, args.batch_size, args.dry_run, args.include_uc_lineage)
        results.append(result)

    total_elapsed = time.time() - total_start

    # Step 4: Write summary report
    print(f"\n[4/4] Writing summary report...")
    write_summary_report(results, total_elapsed, args.dry_run)

    # Cleanup
    lib.close_connection()

    print(f"\n{'='*70}")
    print(f"  COMPLETE — {len(results)} tables, {total_elapsed:.0f}s total")
    processed = [r for r in results if r["status"] in ("completed", "discovered")]
    if processed:
        total_obj = sum(r["downstream_objects"] for r in processed)
        total_succ = sum(r["statements_succeeded"] for r in processed)
        print(f"  {total_obj} downstream objects, {total_succ} statements succeeded")
    print(f"  Report: {REPORT_PATH}")
    print(f"{'='*70}")


if __name__ == "__main__":
    main()
