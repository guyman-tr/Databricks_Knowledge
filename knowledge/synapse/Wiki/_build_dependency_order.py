"""
Build bottom-up dependency order for Synapse tables.

Reads the SSDT-generated Dependencies JSON from the DataPlatform repo,
parses each SP's .sql file to find write targets (INSERT INTO, MERGE INTO, UPDATE),
builds a table-to-table dependency graph, topologically sorts it, and writes
_dependency_order.json.

Usage:
    python _build_dependency_order.py [--repo PATH] [--out PATH]

Defaults:
    --repo  auto-detected relative to this script (../../../DataPlatform)
    --out   _dependency_order.json  (same directory as this script)
"""

import sys, os, json, re, argparse
from collections import defaultdict, deque
from pathlib import Path

sys.stdout.reconfigure(line_buffering=True)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_DEFAULT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", "..", "..", "..", "DataPlatform"))
DEPS_REL = os.path.join("SynapseSQLPool1", "sql_dp_prod_we", "DependenciesData", "sql_dp_prod_we_Dependencies.json")
SP_BASE_REL = os.path.join("SynapseSQLPool1", "sql_dp_prod_we")

WRITE_PATTERNS = [
    re.compile(r'\bINSERT\s+INTO\s+\[?(\w+)\]?\.\[?(\w+)\]?', re.IGNORECASE),
    re.compile(r'\bMERGE\s+(?:INTO\s+)?\[?(\w+)\]?\.\[?(\w+)\]?', re.IGNORECASE),
    re.compile(r'\bUPDATE\s+\[?(\w+)\]?\.\[?(\w+)\]?', re.IGNORECASE),
    re.compile(r'\bINSERT\s+INTO\s+\[?(\w+)\]?\.\[?(\w+)\]?\.\[?(\w+)\]?', re.IGNORECASE),
    re.compile(r'\bTRUNCATE\s+TABLE\s+\[?(\w+)\]?\.\[?(\w+)\]?', re.IGNORECASE),
]

# Skip temp tables and staging patterns
SKIP_PREFIXES = ('#', '@', 'tmp_', 'stg_', 'Stg_')


def load_dependencies(repo_path):
    deps_path = os.path.join(repo_path, DEPS_REL)
    print(f"Reading dependencies from {deps_path}...")
    with open(deps_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data.get("Objects", data) if isinstance(data, dict) else data


def find_sp_file(repo_path, schema, sp_name):
    """Locate the SP .sql file in the repo."""
    sp_dir = os.path.join(repo_path, SP_BASE_REL, schema, "Stored Procedures")
    filename = f"{schema}.{sp_name}.sql"
    full_path = os.path.join(sp_dir, filename)
    if os.path.isfile(full_path):
        return full_path
    return None


def extract_write_targets(sp_text):
    """Parse SQL text to find tables the SP writes to."""
    targets = set()
    for pattern in WRITE_PATTERNS:
        for match in pattern.finditer(sp_text):
            groups = match.groups()
            if len(groups) == 3:
                schema, table = groups[1], groups[2]
            else:
                schema, table = groups[0], groups[1]

            if any(table.startswith(p) for p in SKIP_PREFIXES):
                continue
            if schema.startswith('#') or schema.startswith('@'):
                continue

            targets.add(f"{schema}.{table}")
    return targets


def flatten_deps(dep_list):
    """Extract all referenced table names from a dependency list (recursive)."""
    tables = set()
    for dep in dep_list:
        obj_name = dep.get("Object Name", "")
        obj_type = dep.get("Type", "")
        if obj_type == "USER_TABLE":
            tables.add(obj_name)
        elif obj_type in ("VIEW", "SQL_INLINE_TABLE_VALUED_FUNCTION"):
            tables.add(obj_name)
            sub_deps = dep.get("Dependencies", [])
            if sub_deps:
                tables.update(flatten_deps(sub_deps))
    return tables


def build_graph(objects, repo_path):
    """Build table-to-table dependency graph from SSDT deps + SP write parsing."""
    # edges[target_table] = set of source_tables (tables that feed it)
    edges = defaultdict(set)
    all_tables = set()
    sp_count = 0
    sp_parsed = 0
    sp_no_file = 0
    sp_no_writes = 0
    write_map = {}  # sp_name -> set of write targets

    for obj in objects:
        obj_name = obj.get("Object Name", "")
        obj_type = obj.get("Type", "")
        deps = obj.get("Dependencies", [])

        if obj_type == "USER_TABLE":
            all_tables.add(obj_name)

        if obj_type != "SQL_STORED_PROCEDURE":
            continue

        sp_count += 1
        parts = obj_name.split(".", 1)
        if len(parts) != 2:
            continue
        schema, sp_name = parts

        sp_file = find_sp_file(repo_path, schema, sp_name)
        if not sp_file:
            sp_no_file += 1
            continue

        try:
            with open(sp_file, 'r', encoding='utf-8', errors='replace') as f:
                sp_text = f.read()
        except Exception:
            sp_no_file += 1
            continue

        sp_parsed += 1
        write_targets = extract_write_targets(sp_text)

        if not write_targets:
            sp_no_writes += 1
            continue

        write_map[obj_name] = write_targets
        read_tables = flatten_deps(deps)

        for wt in write_targets:
            all_tables.add(wt)
            sources = read_tables - write_targets - {wt}
            for src in sources:
                edges[wt].add(src)
                all_tables.add(src)

    # Also add view dependencies (view -> tables it reads from)
    for obj in objects:
        obj_name = obj.get("Object Name", "")
        obj_type = obj.get("Type", "")
        deps = obj.get("Dependencies", [])

        if obj_type == "VIEW" and deps:
            source_tables = flatten_deps(deps)
            for src in source_tables:
                if src != obj_name:
                    edges[obj_name].add(src)
                    all_tables.add(src)
            all_tables.add(obj_name)

    print(f"\nSP Analysis:")
    print(f"  Total SPs in deps JSON:  {sp_count}")
    print(f"  SP files found & parsed: {sp_parsed}")
    print(f"  SP files not found:      {sp_no_file}")
    print(f"  SPs with no write targets: {sp_no_writes}")
    print(f"  SPs with write targets:  {len(write_map)}")
    print(f"\nGraph:")
    print(f"  Total objects (tables+views): {len(all_tables)}")
    print(f"  Total dependency edges:       {sum(len(v) for v in edges.values())}")

    return edges, all_tables, write_map


def topo_sort(edges, all_nodes):
    """
    Kahn's algorithm. Returns nodes sorted bottom-up:
    depth 0 = leaf nodes (no dependencies = production source tables).
    """
    in_degree = defaultdict(int)
    reverse_edges = defaultdict(set)  # node -> set of nodes that depend on it

    for node in all_nodes:
        if node not in in_degree:
            in_degree[node] = 0

    for target, sources in edges.items():
        for src in sources:
            reverse_edges[src].add(target)
            in_degree[target] += 1

    # BFS from roots (nodes with no incoming edges in the depends-on graph)
    depth = {}
    visited = set()
    queue = deque()

    # Roots = nodes that appear in all_nodes but NOT as keys in edges (no dependencies)
    for node in all_nodes:
        if node not in edges or len(edges[node]) == 0:
            queue.append((node, 0))
            depth[node] = 0
            visited.add(node)

    while queue:
        node, d = queue.popleft()
        for dependent in reverse_edges.get(node, set()):
            new_depth = d + 1
            if dependent not in depth or new_depth > depth[dependent]:
                depth[dependent] = new_depth
            # Only process when all predecessors are visited
            preds = edges.get(dependent, set())
            if preds.issubset(visited):
                if dependent not in visited:
                    visited.add(dependent)
                    queue.append((dependent, depth[dependent]))

    # Add any remaining unvisited (cyclic) nodes
    for node in all_nodes:
        if node not in depth:
            depth[node] = -1  # cyclic or unreachable

    return depth


def main():
    parser = argparse.ArgumentParser(description="Build Synapse table dependency order")
    parser.add_argument("--repo", default=REPO_DEFAULT, help="DataPlatform repo path")
    parser.add_argument("--out", default=None, help="Output JSON path")
    args = parser.parse_args()

    if args.out is None:
        args.out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_dependency_order.json")

    objects = load_dependencies(args.repo)
    print(f"Loaded {len(objects)} objects from dependencies JSON.")

    edges, all_tables, write_map = build_graph(objects, args.repo)
    depth_map = topo_sort(edges, all_tables)

    result = []
    for table, d in sorted(depth_map.items(), key=lambda x: (x[1], x[0])):
        entry = {
            "table": table,
            "depth": d,
            "depends_on": sorted(edges.get(table, set())),
        }
        result.append(entry)

    with open(args.out, 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2, ensure_ascii=False)

    print(f"\nOutput: {args.out}")
    print(f"Total entries: {len(result)}")

    # Summary by depth
    depth_counts = defaultdict(int)
    for entry in result:
        depth_counts[entry["depth"]] += 1
    print(f"\nDepth distribution:")
    for d in sorted(depth_counts.keys()):
        label = "LEAF (production sources)" if d == 0 else f"depth {d}" if d > 0 else "CYCLIC/UNREACHABLE"
        print(f"  {label}: {depth_counts[d]} objects")

    # Show top 10 deepest
    print(f"\nTop 10 deepest (most downstream):")
    for entry in sorted(result, key=lambda x: -x["depth"])[:10]:
        print(f"  depth {entry['depth']}: {entry['table']} (depends on {len(entry['depends_on'])} tables)")

    # Show a few write_map examples
    print(f"\nSample SP write targets:")
    for sp, targets in list(write_map.items())[:5]:
        print(f"  {sp} -> {targets}")


if __name__ == "__main__":
    main()
