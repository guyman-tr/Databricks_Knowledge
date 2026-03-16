"""Query UC column frequency distribution for deep-lineage-propagation spec."""
from databricks import sql
import csv, os

conn = sql.connect(
    server_hostname="adb-5142916747090026.6.azuredatabricks.net",
    http_path="/sql/1.0/warehouses/208214768b0e0308",
    auth_type="databricks-oauth"
)
cursor = conn.cursor()
cursor.execute("""
SELECT
  column_name,
  COUNT(*) AS occurrence_count,
  COUNT(DISTINCT table_catalog || '.' || table_schema || '.' || table_name) AS distinct_tables
FROM system.information_schema.columns
WHERE table_schema != 'information_schema'
  AND data_type NOT IN ('MAP', 'ARRAY', 'STRUCT', 'VARIANT')
  AND NOT data_type LIKE 'MAP%'
  AND NOT data_type LIKE 'ARRAY%'
  AND NOT data_type LIKE 'STRUCT%'
GROUP BY column_name
ORDER BY occurrence_count DESC
""")
rows = cursor.fetchall()
cursor.close()
conn.close()

out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "column_frequency.csv")
with open(out_path, "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["column_name", "occurrence_count", "distinct_tables"])
    for r in rows:
        w.writerow(r)

print(f"Total distinct column names: {len(rows)}")
print(f"\nTop 50 most common columns:")
print(f"{'Column':<45} {'Occurrences':>12} {'Distinct Tables':>16}")
print("-" * 75)
for r in rows[:50]:
    print(f"{r[0]:<45} {r[1]:>12,} {r[2]:>16,}")

print(f"\n--- Distribution ---")
tiers = [
    (1000, "1000+"),
    (500, "500-999"),
    (100, "100-499"),
    (50, "50-99"),
    (10, "10-49"),
    (5, "5-9"),
    (1, "1-4"),
]
for threshold, label in tiers:
    count = sum(1 for r in rows if r[1] >= threshold)
    print(f"  Columns appearing in {label} objects: {count}")

print(f"\nSaved full results to: {out_path}")
