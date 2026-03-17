"""
Refresh the static Generic Pipeline mapping backup.

Usage:
  1. Query Databricks via MCP or notebook:
     SELECT * FROM main.general.bronze_opsdb_dbo_vw_unitycatalog_mapping_tables
     ORDER BY DatabaseName, SchemaName, TableName
     (paginate: LIMIT 500 OFFSET 0, LIMIT 500 OFFSET 500, etc.)

  2. Save all batch outputs as pipe-delimited markdown tables in BATCH_FILES below.

  3. Run: python _refresh_mapping.py

The view's column headers are shifted by 1 from position 11 onward due to a
phantom status column. This parser uses position-based extraction with verified
correct semantic mappings.
"""
import json
import sys
import os

BATCH_FILES = sys.argv[1:] if len(sys.argv) > 1 else []
OUTPUT = os.path.join(os.path.dirname(__file__), "_generic_pipeline_mapping.json")

if not BATCH_FILES:
    print("Usage: python _refresh_mapping.py <batch1.txt> <batch2.txt> ...")
    print("Each file should contain a pipe-delimited markdown table from SELECT *")
    sys.exit(1)

def parse_pipe_row(line):
    line = line.strip()
    if line.startswith("|"):
        line = line[1:]
    if line.endswith("|"):
        line = line[:-1]
    return [v.strip() for v in line.split("|")]

POSITION_MAP = {
    "generic_id": 0,
    "database_name": 1,
    "schema_name": 2,
    "table_name": 3,
    "inc_column_name": 4,
    "object_type": 6,
    "db_type": 7,
    "status": 11,
    "frequency_minutes": 12,
    "file_type": 16,
    "copy_strategy": 17,
    "log_id": 18,
    "file_location": 19,
    "server_name": 20,
    "source_type": 27,
    "datalake_container": 30,
    "datalake_path": 31,
    "business_group": 32,
    "uc_table": 33,
}

all_rows = []
for batch_file in BATCH_FILES:
    with open(batch_file, "r", encoding="utf-8") as f:
        lines = f.readlines()
    for line in lines[2:]:
        line = line.strip()
        if not line or line.startswith("*"):
            continue
        vals = parse_pipe_row(line)
        if len(vals) < 34:
            continue
        row = {}
        for name, pos in POSITION_MAP.items():
            row[name] = vals[pos] if pos < len(vals) else ""
        all_rows.append(row)

print(f"Parsed {len(all_rows)} rows from {len(BATCH_FILES)} files")

EXPORT_FIELDS = [
    "generic_id", "database_name", "schema_name", "table_name",
    "server_name", "copy_strategy", "frequency_minutes", "file_type",
    "file_location", "datalake_path", "business_group", "uc_table", "source_type",
]

mapping = [{k: r[k] for k in EXPORT_FIELDS} for r in all_rows]

from datetime import date
output = {
    "_metadata": {
        "source": "main.general.bronze_opsdb_dbo_vw_unitycatalog_mapping_tables",
        "description": "Static backup of Generic Pipeline mapping. Fallback for Phase 13 when Databricks MCP is unavailable.",
        "row_count": len(mapping),
        "exported_at": str(date.today()),
        "refresh_instruction": "python _refresh_mapping.py batch1.txt batch2.txt ...",
        "column_note": "View header names are shifted by 1 from position 11 onward. Parser uses position-based extraction with corrected semantics."
    },
    "mappings": mapping
}

with open(OUTPUT, "w", encoding="utf-8") as f:
    json.dump(output, f, indent=2)

print(f"Wrote {len(mapping)} mappings to {OUTPUT}")
