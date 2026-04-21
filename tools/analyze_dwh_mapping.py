import json

with open(r'C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\_generic_pipeline_mapping.json', encoding='utf-8') as f:
    raw = json.load(f)

data = raw['mappings']

# Get all DWH_dbo entries
dwh = [e for e in data if e.get('schema_name') == 'DWH_dbo' and e.get('database_name') == 'sql_dp_prod_we']

# Separate: view-named vs table-named
view_prefixes = ('v_', 'vw_', 'vu_')
view_mapped = [e for e in dwh if e['table_name'].lower().startswith(view_prefixes)]
table_mapped = [e for e in dwh if not e['table_name'].lower().startswith(view_prefixes)]

print(f'Total DWH_dbo entries in pipeline: {len(dwh)}')
print(f'  View-named (V_/VW_/VU_ prefix): {len(view_mapped)}')
print(f'  Table-named (no V_ prefix): {len(table_mapped)}')

# For each view in the pipeline, find the corresponding BASE TABLE name (strip V_ prefix)
print()
print('=== VIEW-named pipeline entries -> BASE TABLE they represent ===')
view_to_base = {}
for e in sorted(view_mapped, key=lambda x: x['table_name']):
    name = e['table_name']
    # Strip leading V_ / VW_ / VU_ to get base table name
    if name.lower().startswith('vw_'):
        base = name[3:]
    elif name.lower().startswith('vu_'):
        base = name[3:]
    elif name.lower().startswith('v_'):
        base = name[2:]
    else:
        base = name
    view_to_base[name] = base
    print(f'  {name:55s} -> base: {base}  | uc: {e["uc_table"]}')

# Now check: for each view entry, is there also a TABLE entry for the base name?
table_names_in_pipeline = {e['table_name'].lower() for e in table_mapped}
print()
print('=== Views whose BASE TABLE is NOT separately in the pipeline (table gets no direct UC entry) ===')
orphaned_tables = []
for vname, bname in view_to_base.items():
    if bname.lower() not in table_names_in_pipeline:
        orphaned_tables.append((vname, bname))
        print(f'  Pipeline has VIEW: {vname:50s}  but NOT table: {bname}')

print(f'\nTotal: {len(orphaned_tables)} base tables have no direct UC pipeline entry (only their VIEW is replicated)')

print()
print('=== Table-named entries (these tables DIRECTLY appear in UC) ===')
for e in sorted(table_mapped, key=lambda x: x['table_name']):
    print(f'  {e["table_name"]:55s} -> {e["uc_table"]}')
