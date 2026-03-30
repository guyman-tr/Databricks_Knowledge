"""
Deep Lineage Column Propagation Library.

Shared module for tracing documented column descriptions through the full
Unity Catalog lineage tree and propagating them to all downstream objects.

Usage: imported by per-table generated scripts ({Object}_deep_propagate.py).
"""

import sys, os, json, re, argparse, textwrap
from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from collections import defaultdict
from typing import Optional

from _uc_comment_sanitize import escape_sql_comment_value

sys.stdout.reconfigure(line_buffering=True)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

DATABRICKS_HOST = "adb-5142916747090026.6.azuredatabricks.net"
DATABRICKS_HTTP_PATH = "/sql/1.0/warehouses/208214768b0e0308"
DEFAULT_BATCH_SIZE = 30
CONFIG_PATH = os.path.normpath(os.path.join(
    os.path.dirname(__file__), "..", "..", "..", ".specify", "Configs", "dwh-semantic-doc-config.json"
))

# ---------------------------------------------------------------------------
# T003: Data structures — LineageTree, DownstreamNode, ColumnMatch
# ---------------------------------------------------------------------------

@dataclass
class ColumnMatch:
    source_column: str
    target_column: str
    match_type: str = "identical"   # "identical" | "renamed"
    rename_chain: list = field(default_factory=list)
    description: str = ""
    tier: str = ""

@dataclass
class DownstreamNode:
    catalog: str
    schema: str
    table: str
    full_name: str
    object_type: str = "TABLE"
    hop_distance: int = 1
    discovered_via: str = "lineage"
    columns: list = field(default_factory=list)  # list of ColumnMatch dicts

    def add_column(self, cm: ColumnMatch):
        self.columns.append(asdict(cm))

@dataclass
class LineageTree:
    source: dict = field(default_factory=dict)
    discovered_at: str = ""
    discovery_methods: list = field(default_factory=list)
    total_downstream_objects: int = 0
    total_column_matches: int = 0
    total_renames: int = 0
    nodes: list = field(default_factory=list)  # list of DownstreamNode dicts

    def save(self, path: str):
        with open(path, "w", encoding="utf-8") as f:
            json.dump(asdict(self), f, indent=2, ensure_ascii=False)
        print(f"  Lineage tree saved: {path}")

    @staticmethod
    def load(path: str) -> "LineageTree":
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        tree = LineageTree(**{k: v for k, v in data.items() if k != "nodes"})
        tree.nodes = data.get("nodes", [])
        return tree

# ---------------------------------------------------------------------------
# T004: ProgressLog, BatchStatus
# ---------------------------------------------------------------------------

@dataclass
class BatchStatus:
    batch_id: int
    objects: list = field(default_factory=list)
    status: str = "pending"
    statements_succeeded: int = 0
    statements_failed: int = 0
    completed_at: str = ""
    errors: list = field(default_factory=list)

@dataclass
class ProgressLog:
    source: str = ""
    started_at: str = ""
    total_batches: int = 0
    completed_batches: int = 0
    batches: list = field(default_factory=list)  # list of BatchStatus dicts

    def save(self, path: str):
        with open(path, "w", encoding="utf-8") as f:
            json.dump(asdict(self), f, indent=2, ensure_ascii=False)

    @staticmethod
    def load_or_create(path: str, source: str = "") -> "ProgressLog":
        if os.path.isfile(path):
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            log = ProgressLog(**{k: v for k, v in data.items() if k != "batches"})
            log.batches = data.get("batches", [])
            return log
        return ProgressLog(
            source=source,
            started_at=datetime.now(timezone.utc).isoformat(),
        )

    def is_completed(self, batch_id: int) -> bool:
        for b in self.batches:
            if b.get("batch_id") == batch_id and b.get("status") == "completed":
                return True
        return False

# ---------------------------------------------------------------------------
# T005: Blacklist loader
# ---------------------------------------------------------------------------

def load_blacklist(config_path: str = CONFIG_PATH) -> set:
    """Returns a case-insensitive set of blacklisted column names."""
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            config = json.load(f)
        items = config.get("propagation", {}).get("blacklist", [])
        return {item["column_name"].lower() for item in items}
    except Exception as e:
        print(f"  WARNING: Could not load blacklist from {config_path}: {e}")
        return set()

def load_blacklist_full(config_path: str = CONFIG_PATH) -> list:
    """Returns full blacklist entries (for broadcast)."""
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            config = json.load(f)
        return config.get("propagation", {}).get("blacklist", [])
    except Exception:
        return []

# ---------------------------------------------------------------------------
# T006: Source description loader
# ---------------------------------------------------------------------------

_ALTER_COMMENT_RE = re.compile(
    r"ALTER\s+(?:TABLE|VIEW)\s+(\S+)\s+ALTER\s+COLUMN\s+(\S+)\s+COMMENT\s+'((?:[^']|'')*)'",
    re.IGNORECASE
)
_COMMENT_ON_RE = re.compile(
    r"COMMENT\s+ON\s+COLUMN\s+(\S+)\.(\S+)\s+IS\s+'((?:[^']|'')*)'",
    re.IGNORECASE
)

def load_source_descriptions(alter_sql_path: str) -> dict:
    """
    Parse an .alter.sql file and return {column_name_lower: description}.
    Handles both ALTER TABLE ... ALTER COLUMN ... COMMENT and COMMENT ON COLUMN.
    """
    descriptions = {}
    if not os.path.isfile(alter_sql_path):
        print(f"  WARNING: No alter.sql found at {alter_sql_path}")
        return descriptions

    with open(alter_sql_path, "r", encoding="utf-8") as f:
        content = f.read()

    for m in _ALTER_COMMENT_RE.finditer(content):
        col = m.group(2).strip("`").strip('"')
        desc = m.group(3).replace("''", "'")
        descriptions[col.lower()] = desc

    for m in _COMMENT_ON_RE.finditer(content):
        col = m.group(2).strip("`").strip('"')
        desc = m.group(3).replace("''", "'")
        descriptions[col.lower()] = desc

    print(f"  Loaded {len(descriptions)} column descriptions from {os.path.basename(alter_sql_path)}")
    return descriptions

# ---------------------------------------------------------------------------
# Databricks connection helper
# ---------------------------------------------------------------------------

_connection = None

def get_connection():
    global _connection
    if _connection is None:
        from databricks import sql
        print(f"  Connecting to Databricks ({DATABRICKS_HOST})...")
        _connection = sql.connect(
            server_hostname=DATABRICKS_HOST,
            http_path=DATABRICKS_HTTP_PATH,
            auth_type="databricks-oauth"
        )
        print("  Connected.")
    return _connection

def close_connection():
    global _connection
    if _connection is not None:
        _connection.close()
        _connection = None

# ---------------------------------------------------------------------------
# T014: Rename detection heuristic (Phase 4)
# ---------------------------------------------------------------------------

_VALID_SQL_IDENT = re.compile(r'^[a-zA-Z_][a-zA-Z0-9_]*$')

def is_plausible_rename(source_col: str, target_col: str) -> bool:
    """
    Determine if a source→target column mapping is a plausible rename
    (as opposed to a computed transformation like `YEAR(col)` or `col * 100`).
    Per research.md R2.
    """
    if source_col.lower() == target_col.lower():
        return False  # not a rename — identical

    if not _VALID_SQL_IDENT.match(target_col):
        return False

    if any(op in target_col for op in ['+', '-', '*', '/', '%']):
        return False

    # Length ratio < 3x
    ratio = max(len(source_col), len(target_col)) / max(min(len(source_col), len(target_col)), 1)
    if ratio > 3.0:
        return False

    return True


def format_rename_description(original_desc: str, source_col: str,
                               source_table: str, rename_chain: list) -> str:
    """
    Format a description for a renamed column.
    Fits within UC's 1024-char limit.
    """
    chain_str = " → ".join(rename_chain)
    prefix = f"Same as {source_col}"
    suffix = f"(Propagated from {source_table}, rename chain: {chain_str})"

    available = 1024 - len(prefix) - len(suffix) - 6  # 6 for ": " and ". "
    if len(original_desc) > available:
        desc_truncated = original_desc[:available - 3] + "..."
    else:
        desc_truncated = original_desc

    result = f"{prefix}: {desc_truncated}. {suffix}"
    return result[:1024]

# ---------------------------------------------------------------------------
# T007: query_column_lineage — UC lineage-based discovery
# ---------------------------------------------------------------------------

def query_column_lineage(source_table_full_name: str, blacklist: set, cursor) -> list:
    """
    Query system.access.column_lineage for all direct downstream targets
    of a given source table. Returns list of dicts:
    {target_table, target_column, source_column, target_type}
    """
    query = textwrap.dedent(f"""\
        SELECT DISTINCT
            target_table_full_name,
            target_column_name,
            source_column_name,
            target_type
        FROM system.access.column_lineage
        WHERE source_table_full_name = '{source_table_full_name}'
          AND target_table_full_name IS NOT NULL
          AND target_column_name IS NOT NULL
          AND source_column_name IS NOT NULL
          AND target_table_full_name != source_table_full_name
          AND event_time > current_timestamp() - INTERVAL 7 DAYS
        LIMIT 5000
    """)

    try:
        cursor.execute(query)
        rows = cursor.fetchall()
    except Exception as e:
        print(f"  WARNING: column_lineage query failed: {e}")
        return []

    results = []
    for row in rows:
        target_table = row[0]
        target_col = row[1]
        source_col = row[2]
        target_type = row[3] if len(row) > 3 else "TABLE"

        if source_col.lower() in blacklist:
            continue

        results.append({
            "target_table": target_table,
            "target_column": target_col,
            "source_column": source_col,
            "target_type": target_type or "TABLE",
        })

    return results

# ---------------------------------------------------------------------------
# T008: query_name_pattern — name-pattern discovery (supplement)
# ---------------------------------------------------------------------------

def query_name_pattern(source_table_synapse_name: str, source_columns: dict,
                       blacklist: set, cursor) -> list:
    """
    Port of Phase 11's name-pattern discovery:
    1. Name-pattern search on information_schema.tables
    2. Column cross-match (5+ shared business columns)
    Returns list of {full_name, object_type, discovered_via} dicts.
    """
    results = []
    # Extract just the table name (strip schema prefix like "BI_DB_dbo.")
    table_only = source_table_synapse_name.split(".")[-1] if "." in source_table_synapse_name else source_table_synapse_name
    name_lower = table_only.lower().replace("_", "%")

    try:
        cursor.execute(f"""\
            SELECT DISTINCT
                table_catalog, table_schema, table_name, table_type
            FROM system.information_schema.tables
            WHERE LOWER(table_name) LIKE '%{name_lower}%'
              AND table_schema != 'information_schema'
        """)
        for row in cursor.fetchall():
            if str(row[0]).startswith("__databricks_internal"):
                continue
            full_name = f"{row[0]}.{row[1]}.{row[2]}"
            results.append({
                "full_name": full_name,
                "catalog": row[0],
                "schema": row[1],
                "table": row[2],
                "object_type": "VIEW" if "VIEW" in str(row[3]).upper() else "TABLE",
                "discovered_via": "name_pattern",
            })
    except Exception as e:
        print(f"  WARNING: name-pattern search failed: {e}")

    return results

# ---------------------------------------------------------------------------
# T019: parse_alter_sql_metadata — extract UC target and Synapse source
# ---------------------------------------------------------------------------

_UC_TARGET_RE = re.compile(r'^--\s*UC\s+Target:\s*(.+)$', re.MULTILINE)
_SYNAPSE_SOURCE_RE = re.compile(r'^--\s*Synapse\s+Source:\s*(.+)$', re.MULTILINE)
_ALTER_SCRIPT_RE = re.compile(r'^--\s*Databricks\s+ALTER\s+Script:\s*(.+)$', re.MULTILINE)

def parse_alter_sql_metadata(alter_sql_path: str) -> dict:
    """
    Parse the header of an .alter.sql file to extract UC target and Synapse source.
    Returns {"uc_target": "main.dwh.dim_position", "synapse_source": "DWH_dbo.Dim_Position"}.
    Falls back to '-- Databricks ALTER Script: <synapse_name>' if Synapse Source is missing.
    """
    result = {"uc_target": "", "synapse_source": ""}
    if not os.path.isfile(alter_sql_path):
        return result

    with open(alter_sql_path, "r", encoding="utf-8") as f:
        header = f.read(2048)

    m = _UC_TARGET_RE.search(header)
    if m:
        result["uc_target"] = m.group(1).strip()

    m = _SYNAPSE_SOURCE_RE.search(header)
    if m:
        result["synapse_source"] = m.group(1).strip()
    else:
        m = _ALTER_SCRIPT_RE.search(header)
        if m:
            result["synapse_source"] = m.group(1).strip()

    return result


# ---------------------------------------------------------------------------
# T020: bulk_resolve_uc_names — batch lookup for multiple Synapse tables
# ---------------------------------------------------------------------------

def bulk_resolve_uc_names(synapse_names: list, cursor) -> dict:
    """
    Resolve a list of Synapse table names to their UC three-level names.
    Queries the Generic Pipeline mapping view once, then resolves via
    information_schema. Returns {synapse_name_lower: uc_full_name}.
    """
    uc_mapping = _map_synapse_to_uc(synapse_names, cursor)

    if not uc_mapping:
        return {}

    resolved = {}
    uc_table_names = list(set(uc_mapping.values()))

    for batch_start in range(0, len(uc_table_names), 20):
        batch = uc_table_names[batch_start:batch_start + 20]
        or_clauses = " OR ".join(f"LOWER(table_name) = '{t}'" for t in batch)

        try:
            cursor.execute(f"""\
                SELECT table_catalog, table_schema, table_name
                FROM system.information_schema.tables
                WHERE ({or_clauses})
                  AND table_schema != 'information_schema'
            """)
            uc_lookup = {}
            for row in cursor.fetchall():
                if str(row[0]).startswith("__databricks_internal"):
                    continue
                uc_lookup[str(row[2]).lower()] = f"{row[0]}.{row[1]}.{row[2]}"

            for syn_name, uc_table in uc_mapping.items():
                if uc_table in uc_lookup and syn_name not in resolved:
                    resolved[syn_name] = uc_lookup[uc_table]

        except Exception as e:
            print(f"  WARNING: UC resolution failed for batch: {e}")

    return resolved


# ---------------------------------------------------------------------------
# Synapse dependency discovery — bridges the "Synapse black hole"
# ---------------------------------------------------------------------------

DEPENDENCY_ORDER_PATH = os.path.normpath(os.path.join(
    os.path.dirname(__file__), "_dependency_order.json"
))
MAPPING_VIEW = "main.general.bronze_opsdb_dbo_vw_unitycatalog_mapping_tables"

def _load_synapse_downstream(source_synapse_name: str, max_hops: int = 2) -> list:
    """
    Read _dependency_order.json and BFS to find all Synapse tables that
    (transitively) depend on the source table. Returns list of Synapse
    table names (e.g., ["BI_DB_dbo.BI_DB_Blocked_Customers", ...]).
    """
    if not os.path.isfile(DEPENDENCY_ORDER_PATH):
        print(f"  WARNING: {DEPENDENCY_ORDER_PATH} not found — skipping Synapse dependency discovery")
        return []

    with open(DEPENDENCY_ORDER_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    # Build reverse graph: child → set of objects that depend on child
    reverse = {}
    for obj in data:
        tbl = obj["table"].lower()
        for dep in obj.get("depends_on", []):
            dl = dep.lower()
            if dl not in reverse:
                reverse[dl] = set()
            reverse[dl].add(tbl)

    seed = source_synapse_name.lower()
    visited = {seed}
    queue = [seed]
    result = []

    for hop in range(1, max_hops + 1):
        next_q = []
        for current in queue:
            for child in reverse.get(current, set()):
                if child not in visited:
                    visited.add(child)
                    next_q.append(child)
                    result.append(child)
        queue = next_q
        if not queue:
            break

    return result


def _map_synapse_to_uc(synapse_names: list, cursor) -> dict:
    """
    Map Synapse table names to UC three-level names via the Generic Pipeline
    mapping view. Returns {synapse_name_lower: uc_full_name}.
    """
    if not synapse_names:
        return {}

    # Extract just the table names (without schema prefix) for the mapping view
    table_names = set()
    for sn in synapse_names:
        parts = sn.split(".")
        table_name = parts[-1] if len(parts) > 1 else parts[0]
        table_names.add(table_name.lower())

    if not table_names:
        return {}

    # Batch query the mapping view
    in_clause = ", ".join(f"'{t}'" for t in table_names)
    query = f"""\
        SELECT LOWER(TableName), UnityCatalogTableName, SchemaName
        FROM {MAPPING_VIEW}
        WHERE LOWER(TableName) IN ({in_clause})
    """

    mapping = {}
    try:
        cursor.execute(query)
        for row in cursor.fetchall():
            table_name_lower = row[0]
            uc_path = row[1]  # e.g. "Gold/sql_dp_prod_we/BI_DB_dbo/BI_DB_CIDFirstDates/"
            schema_name = row[2] if len(row) > 2 else ""

            if not uc_path:
                continue

            # Derive UC table name from path: Gold/sql_dp_prod_we/BI_DB_dbo/Table →
            # gold_sql_dp_prod_we_bi_db_dbo_table
            uc_table = uc_path.strip("/").replace("/", "_").lower()

            # Skip _masked variants for now (the non-masked is the primary)
            if uc_table.endswith("_masked"):
                continue

            # Try to find the actual UC three-level name
            synapse_key = f"{schema_name.lower()}.{table_name_lower}" if schema_name else table_name_lower
            mapping[synapse_key] = uc_table

    except Exception as e:
        print(f"  WARNING: Mapping view query failed: {e}")

    return mapping


def query_synapse_dependencies(source_synapse_name: str, cursor,
                                max_hops: int = 2) -> list:
    """
    Find Synapse downstream tables via _dependency_order.json, map them to UC
    names via the Generic Pipeline mapping view, and return as discovery results.
    """
    print(f"  Querying Synapse dependency graph (max {max_hops} hops)...")
    synapse_downstream = _load_synapse_downstream(source_synapse_name, max_hops)

    if not synapse_downstream:
        print(f"    No Synapse downstream found")
        return []

    print(f"    {len(synapse_downstream)} Synapse downstream tables found")

    # Map to UC names
    uc_mapping = _map_synapse_to_uc(synapse_downstream, cursor)
    print(f"    {len(uc_mapping)} mapped to UC via Generic Pipeline")

    if not uc_mapping:
        return []

    # Now find the actual UC three-level names by searching information_schema
    results = []
    # Build a batch LIKE query for all mapped UC table names
    uc_table_names = list(set(uc_mapping.values()))

    # Process in batches of 20 to avoid overly long queries
    for batch_start in range(0, len(uc_table_names), 20):
        batch = uc_table_names[batch_start:batch_start + 20]
        or_clauses = " OR ".join(f"LOWER(table_name) = '{t}'" for t in batch)

        try:
            cursor.execute(f"""\
                SELECT table_catalog, table_schema, table_name, table_type
                FROM system.information_schema.tables
                WHERE ({or_clauses})
                  AND table_schema != 'information_schema'
            """)
            for row in cursor.fetchall():
                if str(row[0]).startswith("__databricks_internal"):
                    continue
                full_name = f"{row[0]}.{row[1]}.{row[2]}"
                results.append({
                    "full_name": full_name,
                    "catalog": row[0],
                    "schema": row[1],
                    "table": row[2],
                    "object_type": "VIEW" if "VIEW" in str(row[3]).upper() else "TABLE",
                    "discovered_via": "synapse_dependency",
                })
        except Exception as e:
            print(f"    WARNING: UC lookup failed for batch: {e}")

    print(f"    {len(results)} UC objects resolved")
    return results

# ---------------------------------------------------------------------------
# T009: discover_tree — BFS traversal with cycle detection
# ---------------------------------------------------------------------------

def discover_tree(source_uc_name: str, source_synapse_name: str,
                  source_descriptions: dict, blacklist: set,
                  output_path: str,
                  include_uc_lineage: bool = False) -> LineageTree:
    """
    Discover downstream UC objects for a Synapse-sourced table.

    Discovery order (by reliability for DWH tables):
      1. Synapse dependency graph (_dependency_order.json) — PRIMARY for DWH
      2. Name-pattern search (information_schema.tables) — supplement
      3. UC column lineage (system.access.column_lineage) — opt-in only

    UC column lineage is off by default because DWH tables arrive via
    Generic Pipeline bulk copy, which does not generate UC lineage entries.
    The lineage query is also extremely slow for heavily-referenced tables.

    Writes .lineage-tree.json to disk.
    """
    conn = get_connection()
    cursor = conn.cursor()

    parts = source_uc_name.split(".")
    if len(parts) == 2:
        parts = ["main"] + parts
    tree = LineageTree(
        source={"catalog": parts[0], "schema": parts[1], "table": parts[2],
                "full_name": ".".join(parts)},
        discovered_at=datetime.now(timezone.utc).isoformat(),
        discovery_methods=[],
    )

    full_source = ".".join(parts)
    visited = {full_source.lower()}
    node_map = {}

    print(f"\n  Discovery from {source_uc_name}...")
    print(f"  Source descriptions: {len(source_descriptions)} columns")
    print(f"  UC lineage: {'ENABLED' if include_uc_lineage else 'DISABLED (DWH default)'}")

    # --- Method 1: Synapse dependency graph (PRIMARY for DWH) ---
    print(f"\n  [1/3] Synapse dependency graph...")
    sd_results = query_synapse_dependencies(source_synapse_name, cursor, max_hops=2)
    sd_added = 0
    for sd in sd_results:
        sd_lower = sd["full_name"].lower()
        if sd_lower not in visited and sd_lower not in node_map:
            node_map[sd_lower] = {
                "catalog": sd.get("catalog", ""),
                "schema": sd.get("schema", ""),
                "table": sd.get("table", ""),
                "full_name": sd["full_name"],
                "object_type": sd.get("object_type", "TABLE"),
                "hop_distance": 2,
                "discovered_via": "synapse_dependency",
                "columns": [],
            }
            sd_added += 1

    if sd_added > 0:
        tree.discovery_methods.append("synapse_dependency")
    print(f"    {sd_added} objects from Synapse dependency graph")

    # --- Method 2: Name-pattern search (supplement) ---
    print(f"  [2/3] Name-pattern search...")
    np_results = query_name_pattern(source_synapse_name, source_descriptions,
                                     blacklist, cursor)
    np_added = 0
    for np_item in np_results:
        np_lower = np_item["full_name"].lower()
        if np_lower not in visited and np_lower not in node_map:
            node_map[np_lower] = {
                "catalog": np_item.get("catalog", ""),
                "schema": np_item.get("schema", ""),
                "table": np_item.get("table", ""),
                "full_name": np_item["full_name"],
                "object_type": np_item.get("object_type", "TABLE"),
                "hop_distance": 1,
                "discovered_via": np_item.get("discovered_via", "name_pattern"),
                "columns": [],
            }
            np_added += 1

    if np_added > 0:
        tree.discovery_methods.append("name_pattern")
    print(f"    {np_added} objects from name-pattern search")

    # --- Method 3: UC column lineage (opt-in) ---
    if include_uc_lineage:
        print(f"  [3/3] UC column lineage (BFS)...")
        queue = [(full_source, 0)]
        lineage_found = False

        while queue:
            current_table, current_hop = queue.pop(0)
            downstream = query_column_lineage(current_table, blacklist, cursor)
            if downstream:
                lineage_found = True

            by_target = defaultdict(list)
            for d in downstream:
                by_target[d["target_table"]].append(d)

            for target_name, mappings in by_target.items():
                target_lower = target_name.lower()
                if target_lower.startswith("__databricks_internal"):
                    continue

                if target_lower not in node_map:
                    t_parts = target_name.split(".")
                    if len(t_parts) != 3:
                        continue
                    node_map[target_lower] = {
                        "catalog": t_parts[0], "schema": t_parts[1], "table": t_parts[2],
                        "full_name": target_name,
                        "object_type": mappings[0].get("target_type", "TABLE"),
                        "hop_distance": current_hop + 1,
                        "discovered_via": "lineage",
                        "columns": [],
                    }

                node = node_map[target_lower]
                for m in mappings:
                    src_col_lower = m["source_column"].lower()
                    tgt_col_lower = m["target_column"].lower()

                    if src_col_lower in source_descriptions:
                        if src_col_lower == tgt_col_lower:
                            node["columns"].append(asdict(ColumnMatch(
                                source_column=m["source_column"],
                                target_column=m["target_column"],
                                match_type="identical",
                                description=source_descriptions[src_col_lower],
                            )))
                        elif is_plausible_rename(m["source_column"], m["target_column"]):
                            chain = [m["source_column"], m["target_column"]]
                            rename_desc = format_rename_description(
                                source_descriptions[src_col_lower],
                                m["source_column"],
                                source_uc_name,
                                chain,
                            )
                            node["columns"].append(asdict(ColumnMatch(
                                source_column=m["source_column"],
                                target_column=m["target_column"],
                                match_type="renamed",
                                rename_chain=chain,
                                description=rename_desc,
                            )))

                if target_lower not in visited:
                    visited.add(target_lower)
                    queue.append((target_name, current_hop + 1))

        if lineage_found:
            tree.discovery_methods.append("lineage")
        lineage_new = sum(1 for n in node_map.values() if n["discovered_via"] == "lineage")
        print(f"    {lineage_new} objects from UC lineage")
    else:
        print(f"  [3/3] UC column lineage: SKIPPED")

    # --- Column matching for all discovered nodes ---
    print(f"\n  Matching columns for {len(node_map)} downstream objects...")
    for key, node in node_map.items():
        if not node["columns"]:
            matched = match_columns(node["full_name"], source_descriptions, blacklist, cursor)
            node["columns"] = [asdict(cm) for cm in matched]

    # Build final tree — filter first, then calculate stats
    tree.nodes = [n for n in node_map.values() if len(n["columns"]) > 0]
    tree.total_downstream_objects = len(tree.nodes)
    tree.total_column_matches = sum(
        len([c for c in n["columns"] if c["match_type"] == "identical"])
        for n in tree.nodes
    )
    tree.total_renames = sum(
        len([c for c in n["columns"] if c["match_type"] == "renamed"])
        for n in tree.nodes
    )

    tree.save(output_path)
    cursor.close()

    print(f"\n  Discovery complete:")
    print(f"    Downstream objects: {tree.total_downstream_objects}")
    print(f"    Column matches:    {tree.total_column_matches}")
    print(f"    Renames:           {tree.total_renames}")
    print(f"    Methods:           {tree.discovery_methods}")

    return tree

# ---------------------------------------------------------------------------
# T010: match_columns — DESCRIBE + match against source descriptions
# ---------------------------------------------------------------------------

def match_columns(full_name: str, source_descriptions: dict,
                  blacklist: set, cursor) -> list:
    """
    DESCRIBE a downstream object, match columns against source descriptions.
    Returns list of ColumnMatch objects.
    """
    matches = []
    try:
        cursor.execute(f"DESCRIBE TABLE {full_name}")
        rows = cursor.fetchall()
    except Exception as e:
        print(f"    SKIP {full_name}: {e}")
        return matches

    for row in rows:
        col_name = row[0]
        if not col_name or col_name.startswith("#"):
            continue
        col_lower = col_name.lower()

        if col_lower in blacklist:
            continue

        if col_lower in source_descriptions:
            matches.append(ColumnMatch(
                source_column=col_name,
                target_column=col_name,
                match_type="identical",
                description=source_descriptions[col_lower],
            ))

    return matches

# ---------------------------------------------------------------------------
# T011: execute_batches — batched ALTER execution with resume
# ---------------------------------------------------------------------------

def execute_batches(tree_path: str, progress_path: str,
                    batch_size: int = DEFAULT_BATCH_SIZE,
                    schema_filter: Optional[set] = None) -> tuple:
    """
    Read lineage tree, execute ALTER statements in batches.
    Returns (all_statements, progress_log).
    """
    tree = LineageTree.load(tree_path)
    progress = ProgressLog.load_or_create(progress_path, tree.source.get("full_name", ""))

    conn = get_connection()
    cursor = conn.cursor()

    nodes = tree.nodes
    if schema_filter:
        nodes = [n for n in nodes if f"{n.get('catalog','')}.{n.get('schema','')}" in schema_filter]
        print(f"  Schema filter applied: {len(nodes)}/{tree.total_downstream_objects} objects match")
    batches = [nodes[i:i + batch_size] for i in range(0, len(nodes), batch_size)]
    progress.total_batches = len(batches)

    all_statements = []
    total_succeeded = 0
    total_failed = 0

    print(f"\n  Executing {len(batches)} batches ({len(nodes)} objects, batch_size={batch_size})...")

    for batch_idx, batch_nodes in enumerate(batches):
        if progress.is_completed(batch_idx):
            print(f"    Batch {batch_idx + 1}/{len(batches)}: SKIPPED (already completed)")
            continue

        batch_status = {
            "batch_id": batch_idx,
            "objects": [n["full_name"] for n in batch_nodes],
            "status": "in_progress",
            "statements_succeeded": 0,
            "statements_failed": 0,
            "completed_at": "",
            "errors": [],
        }

        # Update or append batch status
        existing = [i for i, b in enumerate(progress.batches) if b.get("batch_id") == batch_idx]
        if existing:
            progress.batches[existing[0]] = batch_status
        else:
            progress.batches.append(batch_status)
        progress.save(progress_path)

        succeeded = 0
        failed = 0

        for node in batch_nodes:
            full_name = node["full_name"]
            obj_type = node.get("object_type", "TABLE")

            for col_data in node.get("columns", []):
                target_col = col_data["target_column"]
                desc = escape_sql_comment_value(col_data["description"])

                if "VIEW" in obj_type.upper():
                    stmt = f"COMMENT ON COLUMN {full_name}.`{target_col}` IS '{desc}'"
                else:
                    stmt = f"ALTER TABLE {full_name} ALTER COLUMN `{target_col}` COMMENT '{desc}'"

                all_statements.append(stmt)

                try:
                    cursor.execute(stmt)
                    succeeded += 1
                except Exception as e:
                    failed += 1
                    err_msg = str(e)[:200]
                    reason = "unknown"
                    if "TABLE_OR_VIEW_NOT_FOUND" in err_msg or "SCHEMA_NOT_FOUND" in err_msg:
                        reason = "dropped_object"
                    elif "PERMISSION_DENIED" in err_msg or "Access denied" in err_msg.lower():
                        reason = "permission_denied"
                    elif "COLUMN_NOT_FOUND" in err_msg:
                        reason = "column_not_found"
                    batch_status["errors"].append({
                        "object": full_name, "column": target_col,
                        "error": err_msg, "reason": reason
                    })

        batch_status["status"] = "completed"
        batch_status["statements_succeeded"] = succeeded
        batch_status["statements_failed"] = failed
        batch_status["completed_at"] = datetime.now(timezone.utc).isoformat()
        total_succeeded += succeeded
        total_failed += failed

        progress.completed_batches += 1
        progress.save(progress_path)

        print(f"    Batch {batch_idx + 1}/{len(batches)}: {succeeded} succeeded, {failed} failed")

    cursor.close()

    print(f"\n  Execution complete:")
    print(f"    Total statements: {len(all_statements)}")
    print(f"    Succeeded: {total_succeeded}")
    print(f"    Failed: {total_failed}")

    return all_statements, progress

# ---------------------------------------------------------------------------
# T012: generate_downstream_alter_sql
# ---------------------------------------------------------------------------

def generate_downstream_alter_sql(tree_path: str, output_path: str,
                                   source_synapse_name: str):
    """Write the .downstream.alter.sql file from the lineage tree."""
    tree = LineageTree.load(tree_path)
    source_uc = tree.source.get("full_name", "")

    lines = []
    lines.append("-- =============================================================================")
    lines.append(f"-- Databricks Deep Lineage Column Comment Propagation: {source_synapse_name}")
    lines.append(f"-- Generated: {datetime.now().strftime('%Y-%m-%d')} | dwh-semantic-doc pipeline (deep lineage)")
    lines.append(f"--")
    lines.append(f"-- Source (UC): {source_uc}")
    lines.append(f"-- Source (Synapse): {source_synapse_name}")
    lines.append(f"--")

    tables = [n for n in tree.nodes if "VIEW" not in n.get("object_type", "").upper()]
    views = [n for n in tree.nodes if "VIEW" in n.get("object_type", "").upper()]

    if tables:
        lines.append(f"-- Target tables ({len(tables)}):")
        for t in tables:
            col_count = len(t.get("columns", []))
            lines.append(f"--   {t['full_name']}  ({t.get('object_type', 'TABLE')}, {col_count} cols)")
    if views:
        lines.append(f"-- Target views ({len(views)}):")
        for v in views:
            col_count = len(v.get("columns", []))
            lines.append(f"--   {v['full_name']}  ({v.get('object_type', 'VIEW')}, {col_count} cols)")

    lines.append("-- =============================================================================")
    lines.append("")

    stmt_count = 0
    for node in tree.nodes:
        full_name = node["full_name"]
        obj_type = node.get("object_type", "TABLE")
        columns = node.get("columns", [])
        if not columns:
            continue

        lines.append(f"-- {full_name} ({obj_type}, {len(columns)} columns)")
        for col_data in columns:
            target_col = col_data["target_column"]
            desc = escape_sql_comment_value(col_data["description"])
            if "VIEW" in obj_type.upper():
                lines.append(f"COMMENT ON COLUMN {full_name}.`{target_col}` IS '{desc}';")
            else:
                lines.append(f"ALTER TABLE {full_name} ALTER COLUMN `{target_col}` COMMENT '{desc}';")
            stmt_count += 1
        lines.append("")

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"  Wrote {stmt_count} statements to {os.path.basename(output_path)}")


def generate_merged_downstream_alter_sql(
    nodes: list,
    output_path: str,
    sources_meta: list,
    title: str = "MERGED multi-root deep lineage",
):
    """
    Write a single SQL file from a **merged** list of node dicts (same shape as tree.nodes).

    Use after merging multiple discover_tree() runs so COMMENT text is emitted with the same
    escape_sql_comment_value() path as generate_downstream_alter_sql (UC sanitization / CP1255 repair).

    sources_meta: list of dicts with keys like source_synapse, source_uc, alter_path (for header only).
    """
    lines = []
    lines.append("-- =============================================================================")
    lines.append(f"-- Databricks Deep Lineage Column Comment Propagation: {title}")
    lines.append(f"-- Generated: {datetime.now().strftime('%Y-%m-%d')} | regenerate_downstream_column_comments")
    lines.append("--")
    lines.append("-- Sources (merged):")
    for i, sm in enumerate(sources_meta, 1):
        ss = sm.get("source_synapse", "?")
        uc = sm.get("source_uc", "")
        ap = sm.get("alter_path", "")
        lines.append(f"--   [{i}] Synapse: {ss}")
        if uc:
            lines.append(f"--       UC: {uc}")
        if ap:
            lines.append(f"--       alter: {ap}")
    lines.append("--")

    sorted_nodes = sorted(nodes, key=lambda n: (n.get("full_name", ""),))
    tables = [n for n in sorted_nodes if "VIEW" not in n.get("object_type", "").upper()]
    views = [n for n in sorted_nodes if "VIEW" in n.get("object_type", "").upper()]

    if tables:
        lines.append(f"-- Target tables ({len(tables)}):")
        for t in tables:
            col_count = len(t.get("columns", []))
            lines.append(f"--   {t['full_name']}  ({t.get('object_type', 'TABLE')}, {col_count} cols)")
    if views:
        lines.append(f"-- Target views ({len(views)}):")
        for v in views:
            col_count = len(v.get("columns", []))
            lines.append(f"--   {v['full_name']}  ({v.get('object_type', 'VIEW')}, {col_count} cols)")

    lines.append("-- =============================================================================")
    lines.append("")

    stmt_count = 0
    for node in sorted_nodes:
        full_name = node["full_name"]
        obj_type = node.get("object_type", "TABLE")
        columns = node.get("columns", [])
        if not columns:
            continue

        lines.append(f"-- {full_name} ({obj_type}, {len(columns)} columns)")
        for col_data in columns:
            target_col = col_data["target_column"]
            desc = escape_sql_comment_value(col_data["description"])
            if "VIEW" in obj_type.upper():
                lines.append(f"COMMENT ON COLUMN {full_name}.`{target_col}` IS '{desc}';")
            else:
                lines.append(f"ALTER TABLE {full_name} ALTER COLUMN `{target_col}` COMMENT '{desc}';")
            stmt_count += 1
        lines.append("")

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"  Merged file: {stmt_count} statements -> {os.path.basename(output_path)}")


# ---------------------------------------------------------------------------
# T018: generate_scope_report
# ---------------------------------------------------------------------------

def generate_scope_report(tree_path: str, output_path: str,
                           source_descriptions: dict, blacklist: set,
                           batch_size: int = DEFAULT_BATCH_SIZE):
    """
    Generate a human-readable scope report from the lineage tree.
    Shows blast radius before execution.
    """
    tree = LineageTree.load(tree_path)
    source_name = tree.source.get("full_name", "unknown")

    lines = []
    lines.append(f"# Propagation Scope Report: {tree.source.get('table', '')}")
    lines.append("")
    lines.append(f"**Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M')} | Deep lineage discovery")
    lines.append("")

    # Source summary
    lines.append("## Source Table")
    lines.append("")
    lines.append(f"| Property | Value |")
    lines.append(f"|----------|-------|")
    lines.append(f"| UC Name | `{source_name}` |")
    lines.append(f"| Columns with descriptions | {len(source_descriptions)} |")
    lines.append(f"| Discovery methods | {', '.join(tree.discovery_methods)} |")
    lines.append(f"| Discovered at | {tree.discovered_at} |")
    lines.append("")

    # Downstream objects by type
    type_groups = defaultdict(list)
    for node in tree.nodes:
        type_groups[node.get("object_type", "TABLE")].append(node)

    lines.append("## Downstream Objects")
    lines.append("")
    lines.append(f"**Total**: {tree.total_downstream_objects} objects")
    lines.append("")
    lines.append("| Object | Type | Hop | Via | Identical | Renamed | Total |")
    lines.append("|--------|------|-----|-----|-----------|---------|-------|")

    for node in sorted(tree.nodes, key=lambda n: (n.get("hop_distance", 0), n.get("full_name", ""))):
        identical = len([c for c in node.get("columns", []) if c["match_type"] == "identical"])
        renamed = len([c for c in node.get("columns", []) if c["match_type"] == "renamed"])
        total = identical + renamed
        lines.append(
            f"| `{node['full_name']}` | {node.get('object_type', 'TABLE')} "
            f"| {node.get('hop_distance', 1)} | {node.get('discovered_via', '?')} "
            f"| {identical} | {renamed} | {total} |"
        )
    lines.append("")

    # Renamed columns
    all_renames = []
    for node in tree.nodes:
        for col in node.get("columns", []):
            if col["match_type"] == "renamed":
                all_renames.append((col["source_column"], col["target_column"],
                                     node["full_name"], " → ".join(col.get("rename_chain", []))))

    if all_renames:
        lines.append("## Renamed Columns")
        lines.append("")
        lines.append("| Source Column | Target Column | In Object | Chain |")
        lines.append("|--------------|---------------|-----------|-------|")
        for src, tgt, obj, chain in all_renames:
            lines.append(f"| `{src}` | `{tgt}` | `{obj}` | {chain} |")
        lines.append("")

    # Blacklisted columns
    if blacklist:
        lines.append("## Blacklisted Columns (Excluded)")
        lines.append("")
        lines.append(f"{len(blacklist)} columns excluded from per-table propagation: "
                     f"`{'`, `'.join(sorted(blacklist))}`")
        lines.append("")
        lines.append("*These are handled separately by `_broadcast_propagate.py`.*")
        lines.append("")

    # Estimated statements
    total_stmts = sum(len(n.get("columns", [])) for n in tree.nodes)
    batch_count = max(1, (tree.total_downstream_objects + batch_size - 1) // batch_size)

    lines.append("## Execution Plan")
    lines.append("")
    lines.append(f"| Metric | Value |")
    lines.append(f"|--------|-------|")
    lines.append(f"| Total ALTER statements | {total_stmts} |")
    lines.append(f"| Identical column matches | {tree.total_column_matches} |")
    lines.append(f"| Rename matches | {tree.total_renames} |")
    lines.append(f"| Batch size | {batch_size} objects |")
    lines.append(f"| Number of batches | {batch_count} |")
    lines.append("")

    # Batch breakdown
    for i in range(batch_count):
        start_idx = i * batch_size
        end_idx = min(start_idx + batch_size, tree.total_downstream_objects)
        batch_nodes = tree.nodes[start_idx:end_idx]
        batch_stmts = sum(len(n.get("columns", [])) for n in batch_nodes)
        obj_names = ", ".join(f"`{n['table']}`" for n in batch_nodes)
        lines.append(f"- **Batch {i + 1}**: {end_idx - start_idx} objects, "
                     f"{batch_stmts} statements — {obj_names}")

    lines.append("")

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"  Scope report saved: {os.path.basename(output_path)}")
    print(f"    {tree.total_downstream_objects} objects, {total_stmts} statements, "
          f"{batch_count} batch(es)")

    return total_stmts

# ---------------------------------------------------------------------------
# T013: generate_script — per-table script generator
# ---------------------------------------------------------------------------

def generate_script(source_uc_name: str, source_synapse_name: str,
                    object_dir: str, object_name: str) -> str:
    """
    Generate a per-table _deep_propagate.py script.
    Returns the path to the generated script.
    """
    script_path = os.path.join(object_dir, f"{object_name}_deep_propagate.py")

    lib_rel = os.path.relpath(
        os.path.dirname(__file__), object_dir
    ).replace("\\", "/")

    content = textwrap.dedent(f'''\
        """Deep lineage propagation for {source_synapse_name}."""
        import sys, os
        sys.stdout.reconfigure(line_buffering=True)
        sys.path.insert(0, os.path.normpath(os.path.join(os.path.dirname(__file__), "{lib_rel}")))
        import _deep_propagate_lib as lib

        SOURCE_UC = "{source_uc_name}"
        SOURCE_SYNAPSE = "{source_synapse_name}"
        OBJECT_DIR = os.path.dirname(os.path.abspath(__file__))
        OBJECT_NAME = "{object_name}"

        TREE_PATH = os.path.join(OBJECT_DIR, f"{{OBJECT_NAME}}.lineage-tree.json")
        PROGRESS_PATH = os.path.join(OBJECT_DIR, f"{{OBJECT_NAME}}.propagation-progress.json")
        ALTER_SQL_PATH = os.path.join(OBJECT_DIR, f"{{OBJECT_NAME}}.alter.sql")
        DOWNSTREAM_PATH = os.path.join(OBJECT_DIR, f"{{OBJECT_NAME}}.downstream.alter.sql")
        SCOPE_PATH = os.path.join(OBJECT_DIR, f"{{OBJECT_NAME}}.propagation-scope.md")

        def main():
            import argparse
            parser = argparse.ArgumentParser(description=f"Deep propagation: {{SOURCE_SYNAPSE}}")
            parser.add_argument("command", choices=["discover", "execute", "both"],
                                help="discover=build lineage tree, execute=run ALTER statements, both=full run")
            parser.add_argument("--batch-size", type=int, default=lib.DEFAULT_BATCH_SIZE)
            parser.add_argument("--schema-filter", type=str, default=None,
                                help="Comma-separated schema list to limit execution (e.g., main.bi_output,main.etoro_kpi)")
            parser.add_argument("--include-uc-lineage", action="store_true",
                                help="Also query system.access.column_lineage (slow, usually not needed for DWH)")
            args = parser.parse_args()

            blacklist = lib.load_blacklist()
            print(f"Blacklist: {{len(blacklist)}} columns")

            source_descs = lib.load_source_descriptions(ALTER_SQL_PATH)
            if not source_descs:
                print("ERROR: No source descriptions found. Run the main documentation pipeline first.")
                sys.exit(1)

            if args.command in ("discover", "both"):
                print(f"\\n=== DISCOVER: {{SOURCE_SYNAPSE}} ===")
                lib.discover_tree(SOURCE_UC, SOURCE_SYNAPSE, source_descs, blacklist, TREE_PATH,
                                  include_uc_lineage=args.include_uc_lineage)
                lib.generate_scope_report(TREE_PATH, SCOPE_PATH, source_descs, blacklist, args.batch_size)

            if args.command in ("execute", "both"):
                print(f"\\n=== EXECUTE: {{SOURCE_SYNAPSE}} ===")
                if not os.path.isfile(TREE_PATH):
                    print("ERROR: No lineage tree found. Run 'discover' first.")
                    sys.exit(1)
                sf = set(args.schema_filter.split(",")) if args.schema_filter else None
                lib.execute_batches(TREE_PATH, PROGRESS_PATH, args.batch_size, sf)
                lib.generate_downstream_alter_sql(TREE_PATH, DOWNSTREAM_PATH, SOURCE_SYNAPSE)

            lib.close_connection()
            print("\\nDone.")

        if __name__ == "__main__":
            main()
    ''')

    with open(script_path, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"  Generated: {script_path}")
    return script_path
