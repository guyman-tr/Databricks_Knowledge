"""
Scan all cloned repos for upstream wiki documentation and generate a routing table.

Discovers {repo}/{database}/Wiki/{schema}/ patterns across all repos under REPOS_ROOT,
cross-references with _generic_pipeline_mapping.json to identify which pipeline databases
have wiki coverage, and outputs _upstream_wiki_routing.json.

Usage:
    python tools/scan_upstream_wikis.py                # scan, write routing file
    python tools/scan_upstream_wikis.py --dry-run      # scan, print to stdout only
    python tools/scan_upstream_wikis.py --stats         # print coverage statistics
"""

import argparse
import json
import os
import sys
from pathlib import Path
from datetime import datetime, timezone

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
REPOS_ROOT = REPO_ROOT.parent  # C:\Users\guyman\Documents\github

OUTPUT_FILE = REPO_ROOT / "knowledge" / "synapse" / "Wiki" / "_upstream_wiki_routing.json"
MAPPING_FILE = REPO_ROOT / "knowledge" / "synapse" / "Wiki" / "_generic_pipeline_mapping.json"

SKIP_REPOS = {
    ".git", "node_modules", ".venv", "__pycache__", ".cache",
    "Databricks_Knowledge",  # this repo — has DWH wiki, not upstream
}

SSDT_MARKERS = {".sqlproj", ".sln"}


def find_wiki_databases(repos_root: Path) -> dict:
    """Scan all repos for {repo}/{database}/Wiki/{schema}/ patterns."""
    results = {}

    for repo_dir in sorted(repos_root.iterdir()):
        if not repo_dir.is_dir() or repo_dir.name in SKIP_REPOS:
            continue
        if repo_dir.name.startswith("."):
            continue

        for db_dir in sorted(repo_dir.iterdir()):
            if not db_dir.is_dir() or db_dir.name.startswith("."):
                continue

            wiki_dir = db_dir / "Wiki"
            if not wiki_dir.is_dir():
                continue

            schemas = []
            wiki_file_count = 0
            for schema_dir in sorted(wiki_dir.iterdir()):
                if not schema_dir.is_dir() or schema_dir.name.startswith("_"):
                    continue

                md_files = list(schema_dir.rglob("*.md"))
                if md_files:
                    schemas.append({
                        "name": schema_dir.name,
                        "file_count": len(md_files),
                        "has_tables": (schema_dir / "Tables").is_dir(),
                        "has_views": (schema_dir / "Views").is_dir(),
                    })
                    wiki_file_count += len(md_files)

            if schemas:
                db_name = db_dir.name
                results[db_name] = {
                    "repo": repo_dir.name,
                    "repo_path": str(repo_dir),
                    "wiki_path": f"{db_name}/Wiki",
                    "schemas": [s["name"] for s in schemas],
                    "schema_details": schemas,
                    "total_wiki_files": wiki_file_count,
                }

    return results


def load_pipeline_databases(mapping_file: Path) -> set:
    """Extract all unique database_name values from the pipeline mapping."""
    if not mapping_file.exists():
        return set()
    with open(mapping_file, "r", encoding="utf-8") as f:
        data = json.load(f)
    mappings = data.get("mappings", data if isinstance(data, list) else [])
    return {m["database_name"] for m in mappings if "database_name" in m}


def build_routing_table(repos_root: Path, mapping_file: Path) -> dict:
    """Build the full routing table with coverage analysis."""
    wiki_dbs = find_wiki_databases(repos_root)
    pipeline_dbs = load_pipeline_databases(mapping_file)

    wiki_db_names_lower = {name.lower(): name for name in wiki_dbs}

    covered = []
    for pdb in sorted(pipeline_dbs):
        match = wiki_db_names_lower.get(pdb.lower())
        if match:
            covered.append(pdb)

    uncovered = sorted(pipeline_dbs - {c for c in covered})

    dwh_wiki = {}
    dwh_wiki_path = REPO_ROOT / "knowledge" / "synapse" / "Wiki"
    if dwh_wiki_path.is_dir():
        for schema_dir in sorted(dwh_wiki_path.iterdir()):
            if schema_dir.is_dir() and not schema_dir.name.startswith("_"):
                md_count = len(list(schema_dir.rglob("*.md")))
                if md_count > 0:
                    dwh_wiki[schema_dir.name] = {
                        "repo": "Databricks_Knowledge",
                        "repo_path": str(REPO_ROOT),
                        "wiki_path": f"knowledge/synapse/Wiki/{schema_dir.name}",
                        "file_count": md_count,
                    }

    return {
        "_metadata": {
            "generated": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC"),
            "repos_root": str(repos_root),
            "total_upstream_databases": len(wiki_dbs),
            "pipeline_databases_total": len(pipeline_dbs),
            "pipeline_databases_with_wiki": len(covered),
            "pipeline_databases_without_wiki": len(uncovered),
            "coverage_pct": round(len(covered) / len(pipeline_dbs) * 100, 1) if pipeline_dbs else 0,
        },
        "upstream_databases": wiki_dbs,
        "dwh_wiki_schemas": dwh_wiki,
        "pipeline_coverage": {
            "covered": covered,
            "uncovered": uncovered,
        },
    }


def print_stats(routing: dict):
    """Print human-readable coverage statistics."""
    meta = routing["_metadata"]
    print(f"{'=' * 60}")
    print(f"Upstream Wiki Routing — Coverage Report")
    print(f"{'=' * 60}")
    print(f"Repos root:        {meta['repos_root']}")
    print(f"Generated:         {meta['generated']}")
    print()
    print(f"Upstream databases with wikis:  {meta['total_upstream_databases']}")
    print(f"Pipeline databases (total):     {meta['pipeline_databases_total']}")
    print(f"Pipeline DBs WITH wiki:         {meta['pipeline_databases_with_wiki']}")
    print(f"Pipeline DBs WITHOUT wiki:      {meta['pipeline_databases_without_wiki']}")
    print(f"Coverage:                        {meta['coverage_pct']}%")
    print()

    print("COVERED (pipeline DB → repo):")
    for db_name in routing["pipeline_coverage"]["covered"]:
        entry = routing["upstream_databases"].get(db_name)
        if entry:
            print(f"  {db_name:30s} → {entry['repo']:20s} ({entry['total_wiki_files']} wiki files)")
    print()

    print("UNCOVERED (pipeline DB, no wiki found):")
    for db_name in routing["pipeline_coverage"]["uncovered"]:
        print(f"  {db_name}")
    print()

    print("DWH Wiki Schemas (this repo):")
    for schema, info in routing["dwh_wiki_schemas"].items():
        print(f"  {schema:30s} ({info['file_count']} files)")
    print()

    print("ALL upstream databases (including non-pipeline):")
    for db_name, entry in sorted(routing["upstream_databases"].items()):
        in_pipeline = "✓" if db_name in routing["pipeline_coverage"]["covered"] else " "
        print(f"  [{in_pipeline}] {db_name:30s} → {entry['repo']:20s} | {len(entry['schemas'])} schemas, {entry['total_wiki_files']} files")


def main():
    parser = argparse.ArgumentParser(description="Scan upstream wiki repos and generate routing table")
    parser.add_argument("--dry-run", action="store_true", help="Print JSON to stdout, don't write file")
    parser.add_argument("--stats", action="store_true", help="Print coverage statistics")
    args = parser.parse_args()

    routing = build_routing_table(REPOS_ROOT, MAPPING_FILE)

    if args.stats:
        print_stats(routing)
        return

    output = json.dumps(routing, indent=2, ensure_ascii=False)

    if args.dry_run:
        print(output)
    else:
        OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT_FILE.write_text(output, encoding="utf-8")
        print(f"Written: {OUTPUT_FILE}", flush=True)
        print(f"  {routing['_metadata']['total_upstream_databases']} upstream databases discovered", flush=True)
        print(f"  {routing['_metadata']['pipeline_databases_with_wiki']}/{routing['_metadata']['pipeline_databases_total']} pipeline databases have wiki coverage", flush=True)

    if args.stats or not args.dry_run:
        print_stats(routing)


if __name__ == "__main__":
    main()
