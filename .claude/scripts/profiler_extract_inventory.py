import duckdb
import os

db = os.path.expandvars(r"%USERPROFILE%\.databricks\labs\lakebridge_profilers\synapse_assessment\profiler_extract.db")
con = duckdb.connect(db, read_only=True)
tables = con.execute(
    "SELECT table_schema, table_name FROM information_schema.tables "
    "WHERE table_schema NOT IN ('information_schema','pg_catalog') "
    "ORDER BY table_schema, table_name"
).fetchall()

print(f"Tables: {len(tables)}")
print(f'{"schema.table":<72}{"rows":>10}')
print("-" * 82)
total = 0
for s, t in tables:
    n = con.execute(f'SELECT COUNT(*) FROM "{s}"."{t}"').fetchone()[0]
    total += n
    print(f'{s+"."+t:<72}{n:>10}')
print("-" * 82)
print(f'{"TOTAL":<72}{total:>10}')
