"""
Batch UC Resolution + ALTER Generation Library.

Schema-agnostic pipeline utility: resolves UC targets from information_schema,
detects PII masking patterns, backfills wikis, and generates .alter.sql files.

Lives alongside _deep_propagate_lib.py and _broadcast_propagate.py.

Usage (called by generate-alter-dwh command):
    python _batch_generate_lib.py <schema_name> [--force] [--dry-run]

Examples:
    python _batch_generate_lib.py DWH_dbo
    python _batch_generate_lib.py Dealing_dbo --force
    python _batch_generate_lib.py BI_DB_dbo --dry-run
    python _batch_generate_lib.py BI_DB_dbo --offline   # stubs for _Not_Migrated functions

Function `.lineage.md` backfill (one-time / optional): repo `tools/bootstrap_function_wiki_artifacts.py`.
"""

import os, re, json, argparse, sys
from datetime import datetime
from dataclasses import dataclass, field, asdict
from typing import Optional

from _uc_comment_sanitize import sanitize_uc_sql_comment_text

sys.stdout.reconfigure(line_buffering=True)

WIKI_BASE = os.path.dirname(os.path.abspath(__file__))
TIMESTAMP = datetime.now().strftime("%Y-%m-%d")

# Server prefix mapping: Synapse schema name → UC table name prefix
# The Generic Pipeline names UC tables as: gold_{server}_{schema}_{table}
SERVER_PREFIX = "sql_dp_prod_we"

SKIP_COLUMN_NAMES = {'element', '#', 'stars', 'tier', 'tag', 'type', 'nullable', 'description', ''}

PII_PATTERNS = [
    'email', 'phone', 'mobile', 'address', 'ssn', 'taxid',
    'birthdate', 'dateofbirth', 'ipaddress', 'firstname',
    'lastname', 'fullname', 'passport', 'nationalid',
    'bankaccount', 'iban', 'creditcard'
]

DOMAIN_KEYWORDS = {
    'billing': ['billing', 'deposit', 'redeem', 'withdraw', 'cashout', 'payment', 'funding'],
    'trading': ['position', 'instrument', 'trading', 'mirror', 'guru', 'split', 'click', 'trade'],
    'customer': ['customer', 'player', 'account', 'verification', 'screening', 'worldcheck'],
    'compliance': ['regulation', 'mifid', 'risk', 'aml', 'kyc'],
    'marketing': ['affiliate', 'campaign', 'channel', 'funnel', 'label'],
    'finance': ['currency', 'exchange', 'equity', 'pnl', 'snapshot', 'revenue', 'cost'],
    'dealing': ['dealing', 'hedge', 'bny', 'citadel', 'apex', 'cep', 'pnl'],
}


# ---------------------------------------------------------------------------
# Data structures
# ---------------------------------------------------------------------------

@dataclass
class UCTarget:
    catalog: str
    schema: str
    table: str
    classification: str  # Standard / PII Masked / PII Only / Non-standard
    secondary_catalog: str = ""
    secondary_schema: str = ""
    secondary_table: str = ""
    masked_columns: str = ""

    @property
    def full_name(self):
        return f"{self.catalog}.{self.schema}.{self.table}"

    @property
    def schema_table(self):
        return f"{self.schema}.{self.table}"

    @property
    def secondary_full_name(self):
        if self.secondary_catalog:
            return f"{self.secondary_catalog}.{self.secondary_schema}.{self.secondary_table}"
        return ""


@dataclass
class GenerationResult:
    object_name: str
    status: str  # generated / resolved_this_run / no_uc_table / parse_failure / already_resolved
    uc_target: str = ""
    classification: str = ""
    column_count: int = 0
    detail: str = ""


# ---------------------------------------------------------------------------
# UC Bulk Resolution
# ---------------------------------------------------------------------------

def build_uc_prefix(schema_name: str) -> str:
    """Derive the UC table name prefix for a given Synapse schema.

    DWH_dbo   → gold_sql_dp_prod_we_dwh_dbo_
    Dealing_dbo → gold_sql_dp_prod_we_dealing_dbo_
    BI_DB_dbo → gold_sql_dp_prod_we_bi_db_dbo_
    """
    schema_lower = schema_name.lower().replace('.', '_')
    return f"gold_{SERVER_PREFIX}_{schema_lower}_"


def resolve_uc_targets_bulk(cursor, schema_name: str) -> dict:
    """Query information_schema.tables once and build a lookup dict.

    Returns: {object_name_lower: UCTarget}
    """
    prefix = build_uc_prefix(schema_name)
    query = f"""
        SELECT table_catalog, table_schema, table_name
        FROM system.information_schema.tables
        WHERE table_catalog = 'main'
          AND table_name LIKE '{prefix}%'
        ORDER BY table_schema, table_name
    """
    cursor.execute(query)
    rows = cursor.fetchall()

    raw = {}
    for catalog, schema, table_name in rows:
        raw.setdefault(table_name, []).append((catalog, schema, table_name))

    lookup = {}
    processed_bases = set()

    for table_name, entries in raw.items():
        base_name = table_name
        is_masked = table_name.endswith("_masked")
        if is_masked:
            base_name = table_name[:-7]  # strip _masked

        if base_name in processed_bases:
            continue

        object_key = base_name[len(prefix):]

        masked_entries = raw.get(base_name + "_masked", [])
        unmasked_entries = raw.get(base_name, [])

        dwh_masked = [e for e in masked_entries if e[1] == 'dwh']
        pii_unmasked = [e for e in unmasked_entries if e[1] == 'pii_data']

        if dwh_masked and pii_unmasked:
            m = dwh_masked[0]
            p = pii_unmasked[0]
            lookup[object_key] = UCTarget(
                catalog=m[0], schema=m[1], table=m[2],
                classification="PII Masked",
                secondary_catalog=p[0], secondary_schema=p[1], secondary_table=p[2],
            )
            processed_bases.add(base_name)
            continue

        if is_masked:
            continue

        if len(entries) == 1:
            e = entries[0]
            cls = "Standard" if e[1] == 'dwh' else "Non-standard"
            lookup[object_key] = UCTarget(
                catalog=e[0], schema=e[1], table=e[2],
                classification=cls,
            )
        else:
            dwh_entries = [e for e in entries if e[1] == 'dwh']
            if dwh_entries:
                e = dwh_entries[0]
                lookup[object_key] = UCTarget(
                    catalog=e[0], schema=e[1], table=e[2],
                    classification="Standard",
                )
            else:
                e = entries[0]
                lookup[object_key] = UCTarget(
                    catalog=e[0], schema=e[1], table=e[2],
                    classification="Non-standard",
                )

        processed_bases.add(base_name)

    return lookup


def resolve_masked_columns(cursor, schema_name: str) -> dict:
    """Query Generic Pipeline config for ColumnsToMask.

    Returns: {table_name_lower: "col1,col2,..."}
    """
    try:
        query = """
            SELECT TableName, ColumnsToMask
            FROM main.pii_data_stg.bronze_qa_generic_dbo_v_generic_inc_process_config_delta_override
            WHERE ColumnsToMask IS NOT NULL AND ColumnsToMask != ''
        """
        cursor.execute(query)
        rows = cursor.fetchall()
        return {row[0].lower(): row[1] for row in rows}
    except Exception as e:
        print(f"  WARNING: Could not query ColumnsToMask: {e}")
        return {}


# ---------------------------------------------------------------------------
# Wiki Parsing
# ---------------------------------------------------------------------------

def parse_wiki_header(content: str) -> dict:
    props = {}
    for m in re.finditer(r'\|\s*\*\*([^*]+)\*\*\s*\|\s*([^|]*)\|', content):
        props[m.group(1).strip()] = m.group(2).strip()
    return props


def parse_section1(content: str) -> str:
    m = re.search(r'## 1\.\s*(?:Business Meaning|Overview)\s*\n(.*?)(?=\n## \d|\n---|\Z)', content, re.DOTALL)
    if m:
        text = m.group(1).strip()
        text = re.sub(r'\n+', ' ', text)
        text = re.sub(r'\s+', ' ', text)
        return text[:1024]
    return ""


def parse_section4_columns(content: str) -> list:
    cols = []
    m = re.search(
        r'## (?:\d+\.\s*)?(?:Column Details|Elements|Output Columns|Column Descriptions|Key Columns?(?:\s*(?:&|and)\s*Elements)?|Key Column Enhancement|Columns)',
        content,
    )
    if not m:
        return cols
    section_text = content[m.end():]
    end_m = re.search(r'\n## \d|(?<=\n)---', section_text)
    if end_m:
        section_text = section_text[:end_m.start()]

    header_detected = False
    col_name_idx = None
    desc_idx = None

    for line in section_text.strip().split('\n'):
        line = line.strip()
        if not line or not line.startswith('|'):
            continue
        parts = [p.strip() for p in line.split('|')]
        parts = [p for p in parts if p]
        if len(parts) < 3:
            continue

        if re.match(r'^[-:=\s]+$', parts[0]):
            continue

        if not header_detected:
            header_lower = [p.lower() for p in parts]
            if any(h in header_lower for h in ['column', 'element', 'name']):
                for i, h in enumerate(header_lower):
                    if h in ('column', 'element', 'name'):
                        col_name_idx = i
                        break
                desc_idx = len(parts) - 1
                for i, h in enumerate(header_lower):
                    if h in ('description', 'desc'):
                        desc_idx = i
                        break
                header_detected = True
                continue

        if col_name_idx is None:
            col_name_idx = 1 if len(parts) >= 4 else 0
            desc_idx = len(parts) - 1

        if col_name_idx >= len(parts):
            continue
        col_name = parts[col_name_idx].strip('`').strip()
        if col_name.lower() in SKIP_COLUMN_NAMES or re.match(r'^[-:=]+$', col_name):
            continue
        col_desc = parts[desc_idx].strip() if desc_idx < len(parts) else ""
        cols.append((col_name, col_desc))
    return cols


def is_pending(uc_val: str) -> bool:
    if not uc_val or not uc_val.strip():
        return True
    low = uc_val.lower()
    return '_pending' in low or 'resolved during' in low


def is_uc_knowledge_only(uc_val: str) -> bool:
    """True when the wiki explicitly marks no UC gold export (functions, etc.).

    These objects must NOT take the 'already_resolved' fast-path: previously
    `_Not_Migrated` was treated as resolved and skipped, so no `.alter.sql` was
    ever written. See deploy-index / generate-alter specs.
    """
    if not uc_val or not uc_val.strip():
        return False
    low = uc_val.lower().replace(' ', '')
    if '_not_migrated' in low or 'notmigrated' in low:
        return True
    if 'nounc' in low or 'no_uctable' in low:
        return True
    return False


# ---------------------------------------------------------------------------
# Wiki Backfill
# ---------------------------------------------------------------------------

def backfill_wiki(filepath: str, target: UCTarget):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    content = re.sub(
        r'(\|\s*\*\*UC Target\*\*\s*\|)\s*[^|]*\|',
        f'\\1 `{target.schema_table}` |',
        content
    )

    if target.classification == "PII Masked" and target.secondary_full_name:
        sec_st = f"{target.secondary_schema}.{target.secondary_table}"
        if "UC Target (PII)" not in content:
            content = re.sub(
                r'(\|\s*\*\*UC Target\*\*\s*\|[^|]*\|)',
                f'\\1\n| **UC Target (PII)** | `{sec_st}` |\n| **UC Masked Columns** | {target.masked_columns} |',
                content
            )

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)


# ---------------------------------------------------------------------------
# ALTER Script Generation
# ---------------------------------------------------------------------------

def escape_sql(s: str) -> str:
    return sanitize_uc_sql_comment_text(s or "").replace("'", "''")


def infer_domain(name: str) -> str:
    n = name.lower()
    for domain, keywords in DOMAIN_KEYWORDS.items():
        if any(k in n for k in keywords):
            return domain
    return 'general'


def generate_alter_section(uc_fqn: str, object_name: str, table_comment: str,
                           columns: list, props: dict, masked_cols_set: set,
                           is_secondary: bool = False, schema_name: str = "") -> list:
    """Generate ALTER statements for one UC target. Returns list of SQL lines."""
    lines = []

    if is_secondary:
        lines.append(f"-- === Secondary UC Target (PII unmasked) ===")
        lines.append(f"-- Column comments are identical — meaning is the same regardless of masking.")
        lines.append("")

    synapse_dist = props.get('Synapse Distribution', 'N/A')
    synapse_idx = props.get('Synapse Index', 'N/A')
    refresh = props.get('Refresh', 'N/A')

    full_comment = table_comment
    if synapse_dist and synapse_dist != 'N/A':
        full_comment += f" Synapse: {synapse_dist}"
        if synapse_idx and synapse_idx != 'N/A':
            full_comment += f", {synapse_idx}."
    if len(full_comment) > 1024:
        full_comment = full_comment[:1021] + "..."

    lines.append(f"ALTER TABLE {uc_fqn} SET TBLPROPERTIES (")
    lines.append(f"    'comment' = '{escape_sql(full_comment)}'")
    lines.append(f");")
    lines.append("")

    obj_type = "dimension" if object_name.lower().startswith("dim_") else \
               "fact" if object_name.lower().startswith("fact_") else "table"
    domain = infer_domain(object_name)
    refresh_tag = "daily" if "daily" in refresh.lower() or "1440" in refresh else "unknown"

    src_schema = schema_name or props.get('Schema', 'DWH_dbo')
    lines.append(f"ALTER TABLE {uc_fqn} SET TAGS (")
    lines.append(f"    'domain' = '{domain}',")
    lines.append(f"    'object_type' = '{obj_type}',")
    lines.append(f"    'source_schema' = '{src_schema}',")
    lines.append(f"    'refresh_frequency' = '{refresh_tag}',")
    lines.append(f"    'source_system' = 'Synapse',")
    lines.append(f"    'synapse_distribution' = '{escape_sql(synapse_dist)}',")
    lines.append(f"    'synapse_index' = '{escape_sql(synapse_idx)}',")
    lines.append(f"    'pipeline' = 'dwh-semantic-doc',")
    lines.append(f"    'pipeline_version' = '15-phase'")
    lines.append(f");")
    lines.append("")

    lines.append(f"-- ---- Column Comments ----")
    for col_name, col_desc in columns:
        if col_name and col_desc:
            desc = col_desc[:1024] if len(col_desc) > 1024 else col_desc
            lines.append(f"ALTER TABLE {uc_fqn} ALTER COLUMN `{col_name}` COMMENT '{escape_sql(desc)}';")
    lines.append("")

    lines.append(f"-- ---- Column PII Tags ----")
    for col_name, _ in columns:
        if col_name:
            pii_val = "direct" if col_name.lower() in masked_cols_set else "none"
            if pii_val == "none":
                for pattern in PII_PATTERNS:
                    if pattern in col_name.lower():
                        pii_val = "direct"
                        break
            lines.append(f"ALTER TABLE {uc_fqn} ALTER COLUMN `{col_name}` SET TAGS ('pii' = '{pii_val}');")

    return lines


def generate_alter_sql(object_name: str, target: UCTarget,
                       resolution_method: str, table_comment: str,
                       columns: list, props: dict, schema_name: str = "") -> str:
    masked_cols_set = set()
    if target.masked_columns:
        masked_cols_set = {c.strip().lower() for c in target.masked_columns.split(',')}

    lines = []
    lines.append(f"-- =============================================================================")
    src_schema = schema_name or props.get('Schema', 'DWH_dbo')
    lines.append(f"-- Databricks ALTER Script: {src_schema}.{object_name}")
    lines.append(f"-- Generated: {TIMESTAMP} | 15-phase pipeline")
    lines.append(f"-- Target: Unity Catalog table comment + column comments (1024 char limit)")
    lines.append(f"-- UC Target: {target.full_name}")
    lines.append(f"-- Resolved via: {resolution_method}")
    lines.append(f"-- Classification: {target.classification}")
    if target.secondary_full_name:
        lines.append(f"-- Secondary UC Target: {target.secondary_full_name}  (PII unmasked)")
        lines.append(f"-- Masked Columns: {target.masked_columns}")
    lines.append(f"-- =============================================================================")
    lines.append("")

    lines.extend(generate_alter_section(
        target.full_name, object_name, table_comment, columns, props, masked_cols_set,
        schema_name=schema_name
    ))

    if target.secondary_full_name:
        lines.append("")
        lines.extend(generate_alter_section(
            target.secondary_full_name, object_name, table_comment,
            columns, props, masked_cols_set, is_secondary=True, schema_name=schema_name
        ))

    return '\n'.join(lines) + '\n'


def write_knowledge_only_stub(
    schema_name: str,
    object_name: str,
    alter_dir: str,
    uc_marker: str,
    table_comment: str,
) -> None:
    """Comment-only `.alter.sql` for objects with no UC gold mapping (BI_DB TVFs, etc.)."""
    safe_comment = (table_comment or "").replace("'", "''")[:900]
    lines = [
        "-- =============================================================================",
        f"-- Databricks ALTER Script: {schema_name}.{object_name}",
        f"-- UC Target: {uc_marker.strip()}",
        "-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF",
        "-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.",
        "-- When a UC mapping exists, replace this file via generate-alter-dwh.",
        "-- =============================================================================",
        "",
        "-- Business summary (from wiki §1, truncated):",
        f"-- {safe_comment}" if safe_comment else "-- (no Section 1 text parsed)",
        "",
    ]
    alter_path = os.path.join(alter_dir, f"{object_name}.alter.sql")
    with open(alter_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')


# ---------------------------------------------------------------------------
# Batch Processing — main entry point
# ---------------------------------------------------------------------------

def process_schema(schema_name: str, cursor=None, uc_cache: dict = None,
                   force: bool = False, dry_run: bool = False) -> dict:
    """Process all wiki objects in a schema.

    Args:
        schema_name: e.g., "DWH_dbo", "Dealing_dbo"
        cursor: Databricks SQL cursor (from databricks-sql-connector).
                If None, runs in offline mode (skips _Pending objects).
        uc_cache: Pre-built {object_name_lower: UCTarget} dict from MCP queries.
                  When provided, skips bulk resolution (used by agent mode).
        force: If True, regenerate ALTER scripts even for already-resolved objects.
        dry_run: If True, print what would happen but don't write files.

    Returns:
        dict with results: {resolved, already_resolved, no_uc_table, parse_failure, views}
    """
    schema_dir = os.path.join(WIKI_BASE, schema_name)
    tables_dir = os.path.join(schema_dir, "Tables")

    if not os.path.isdir(tables_dir):
        print(f"ERROR: {tables_dir} does not exist.")
        return {}

    # Step 1: Bulk UC resolution
    uc_lookup = {}
    masked_cols_map = {}
    if uc_cache:
        uc_lookup = uc_cache
        print(f"[1/4] Using pre-built UC cache ({len(uc_lookup)} entries).")
        print(f"[2/4] PII columns pre-loaded.")
    elif cursor:
        print(f"[1/4] Bulk UC resolution for {schema_name}...")
        uc_lookup = resolve_uc_targets_bulk(cursor, schema_name)
        print(f"  Found {len(uc_lookup)} UC tables.")

        print(f"[2/4] Loading masked columns...")
        masked_cols_map = resolve_masked_columns(cursor, schema_name)
        for key, target in uc_lookup.items():
            if target.classification == "PII Masked":
                for tname, cols in masked_cols_map.items():
                    if key in tname.lower() or tname.lower() in key:
                        target.masked_columns = cols
                        break
        print(f"  PII tables: {sum(1 for t in uc_lookup.values() if t.classification == 'PII Masked')}")
    else:
        print(f"[1/4] Databricks offline — skipping bulk UC resolution.")
        print(f"[2/4] Skipped (offline).")

    # Step 2: Scan wiki files from Tables/, Views/, and Functions/ directories
    views_dir = os.path.join(schema_dir, "Views")
    functions_dir = os.path.join(schema_dir, "Functions")
    scan_dirs = [("Tables", tables_dir)]
    if os.path.isdir(views_dir):
        scan_dirs.append(("Views", views_dir))
    if os.path.isdir(functions_dir):
        scan_dirs.append(("Functions", functions_dir))

    wiki_entries = []
    seen_objects = set()
    for dir_label, dir_path in scan_dirs:
        for f in sorted(os.listdir(dir_path)):
            if f.endswith('.md') and not f.startswith('_') \
               and '.review-needed' not in f and '.lineage' not in f and '.deploy' not in f:
                obj = f.replace('.md', '')
                if obj.lower() not in seen_objects:
                    wiki_entries.append((obj, os.path.join(dir_path, f), dir_label))
                    seen_objects.add(obj.lower())

    wiki_entries.sort(key=lambda x: x[0])
    print(f"[3/4] Processing {len(wiki_entries)} wiki files ({', '.join(f'{d[0]}:{sum(1 for e in wiki_entries if e[2]==d[0])}' for d in scan_dirs)})...")

    results = {
        "resolved_this_run": [], "already_resolved": [], "no_uc_table": [],
        "parse_failure": [], "views_no_uc": [], "functions_no_uc": [],
        "knowledge_only_stub": [],
    }

    for object_name, wiki_path, dir_label in wiki_entries:

        with open(wiki_path, 'r', encoding='utf-8') as f:
            content = f.read()

        props = parse_wiki_header(content)

        uc_target_val = props.get('UC Target', '')

        if dir_label == "Tables":
            alter_dir = tables_dir
        elif dir_label == "Views":
            alter_dir = views_dir
        else:
            alter_dir = functions_dir

        # Synapse-only functions (and similar): emit stub UNLESS the UC cache
        # now has a real entry (object may have been exported since last run).
        if is_uc_knowledge_only(uc_target_val):
            lookup_key_check = object_name.lower()
            if uc_lookup and lookup_key_check in uc_lookup:
                pass  # UC cache overrides — fall through to real ALTER generation
            else:
                stub_path = os.path.join(alter_dir, f"{object_name}.alter.sql")
                if os.path.isfile(stub_path) and not force:
                    results["already_resolved"].append(GenerationResult(
                        object_name=object_name, status="already_resolved",
                        uc_target=uc_target_val.strip('`').strip(),
                        detail="knowledge-only stub present",
                    ))
                    continue
                table_comment = parse_section1(content)
                if not dry_run:
                    write_knowledge_only_stub(
                        schema_name, object_name, alter_dir, uc_target_val, table_comment
                    )
                results["knowledge_only_stub"].append(object_name)
                continue

        needs_resolution = is_pending(uc_target_val) or is_uc_knowledge_only(uc_target_val)
        already_had = not needs_resolution

        if already_had and not force:
            results["already_resolved"].append(GenerationResult(
                object_name=object_name, status="already_resolved",
                uc_target=uc_target_val.strip('`').strip(),
            ))
            continue

        # Resolve UC target — strip schema prefix from filename if present
        lookup_key = object_name.lower()
        schema_prefix = schema_name.lower() + "."
        if lookup_key.startswith(schema_prefix):
            lookup_key = lookup_key[len(schema_prefix):]
        target = uc_lookup.get(lookup_key)

        if not target and already_had:
            uc_parts = uc_target_val.strip('`').strip()
            if '.' in uc_parts:
                parts_list = uc_parts.split('.')
                if len(parts_list) == 2:
                    target = UCTarget("main", parts_list[0], parts_list[1], "Standard")
                elif len(parts_list) >= 3:
                    target = UCTarget(parts_list[0], parts_list[1], parts_list[2], "Standard")

        if not target:
            results["no_uc_table"].append(object_name)
            if dir_label == "Views":
                results["views_no_uc"].append(object_name)
            elif dir_label == "Functions":
                results["functions_no_uc"].append(object_name)
            continue

        # Parse wiki content
        table_comment = parse_section1(content)
        columns = parse_section4_columns(content)

        if not columns:
            results["parse_failure"].append(GenerationResult(
                object_name=object_name, status="parse_failure",
                detail="No columns found in Section 4"
            ))
            continue

        if dry_run:
            print(f"  [DRY RUN] {object_name} -> {target.full_name} ({target.classification}, {len(columns)} cols)")
            results["resolved_this_run"].append(GenerationResult(
                object_name=object_name, status="resolved",
                uc_target=target.full_name, classification=target.classification,
                column_count=len(columns)
            ))
            continue

        # Backfill wiki
        if needs_resolution:
            backfill_wiki(wiki_path, target)

        # Generate ALTER
        resolution = "information_schema bulk query" if cursor else "Wiki property table"
        alter_sql = generate_alter_sql(object_name, target, resolution,
                                        table_comment, columns, props,
                                        schema_name=schema_name)
        alter_path = os.path.join(alter_dir, f"{object_name}.alter.sql")
        with open(alter_path, 'w', encoding='utf-8') as f:
            f.write(alter_sql)

        status = "resolved_this_run" if not already_had else "already_resolved"
        bucket = results["resolved_this_run"] if not already_had else results["already_resolved"]
        bucket.append(GenerationResult(
            object_name=object_name, status=status,
            uc_target=target.full_name, classification=target.classification,
            column_count=len(columns)
        ))

    # Step 3: Print summary
    print(f"\n[4/4] Summary")
    print(f"{'='*60}")
    print(f"{schema_name} ALTER Generation — {TIMESTAMP}")
    print(f"{'='*60}")
    print(f"Resolved this run:      {len(results['resolved_this_run'])}")
    print(f"Already resolved:       {len(results['already_resolved'])}")
    print(f"No UC table exists:     {len(results['no_uc_table'])}")
    if results['views_no_uc']:
        print(f"  (of which views:      {len(results['views_no_uc'])})")
    if results['functions_no_uc']:
        print(f"  (of which functions:  {len(results['functions_no_uc'])})")
    if results.get('knowledge_only_stub'):
        print(f"Knowledge-only stubs:   {len(results['knowledge_only_stub'])}")
    print(f"Parse failures:         {len(results['parse_failure'])}")
    total = (len(results['resolved_this_run']) + len(results['already_resolved']))
    print(f"Total ALTER scripts:    {total}")
    print()

    if results['resolved_this_run']:
        print("--- Resolved This Run ---")
        for r in results['resolved_this_run']:
            print(f"  {r.object_name}: {r.uc_target} ({r.classification}, {r.column_count} cols)")
        print()

    if results['no_uc_table']:
        print("--- No UC Table Exists ---")
        for name in results['no_uc_table']:
            print(f"  {name}")
        print()

    if results['parse_failure']:
        print("--- Parse Failures ---")
        for r in results['parse_failure']:
            print(f"  {r.object_name}: {r.detail}")

    return results


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Batch UC Resolution + ALTER Generation")
    parser.add_argument("schema_name", help="Synapse schema (e.g., DWH_dbo, Dealing_dbo)")
    parser.add_argument("--force", action="store_true", help="Regenerate all ALTER scripts")
    parser.add_argument("--dry-run", action="store_true", help="Print plan without writing files")
    parser.add_argument("--offline", action="store_true", help="Skip Databricks queries")
    args = parser.parse_args()

    cursor = None
    if not args.offline:
        try:
            from databricks import sql as dbsql
            DATABRICKS_HOST = "adb-5142916747090026.6.azuredatabricks.net"
            DATABRICKS_HTTP_PATH = "/sql/1.0/warehouses/208214768b0e0308"
            TOKEN = os.environ.get("DATABRICKS_TOKEN", "")
            conn = dbsql.connect(
                server_hostname=DATABRICKS_HOST,
                http_path=DATABRICKS_HTTP_PATH,
                access_token=TOKEN if TOKEN else None,
            )
            cursor = conn.cursor()
            print(f"Databricks connected.")
        except Exception as e:
            print(f"WARNING: Databricks unavailable ({e}). Running offline.")
            cursor = None

    results = process_schema(args.schema_name, cursor=cursor,
                              force=args.force, dry_run=args.dry_run)

    if cursor:
        cursor.close()

    total_generated = (
        len(results.get('resolved_this_run', []))
        + len(results.get('already_resolved', []))
        + len(results.get('knowledge_only_stub', []))
    )
    sys.exit(0 if total_generated > 0 else 1)


if __name__ == "__main__":
    main()
