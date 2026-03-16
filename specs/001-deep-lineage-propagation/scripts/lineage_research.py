"""
Explore system.access.column_lineage table on Databricks SQL warehouse.
Runs queries sequentially and prints all results with headers.
"""

from databricks import sql


def main():
    conn = sql.connect(
        server_hostname="adb-5142916747090026.6.azuredatabricks.net",
        http_path="/sql/1.0/warehouses/208214768b0e0308",
        auth_type="databricks-oauth",
    )

    queries = [
        (
            "1. DESCRIBE TABLE system.access.column_lineage",
            "DESCRIBE TABLE system.access.column_lineage",
        ),
        (
            "2. SELECT * FROM system.access.column_lineage LIMIT 5",
            "SELECT * FROM system.access.column_lineage LIMIT 5",
        ),
        (
            "3. SELECT COUNT(*) as total_rows FROM system.access.column_lineage",
            "SELECT COUNT(*) as total_rows FROM system.access.column_lineage",
        ),
        (
            "4. SELECT DISTINCT source_column_name, target_column_name (renamed columns)",
            "SELECT DISTINCT source_column_name, target_column_name FROM system.access.column_lineage WHERE source_column_name != target_column_name LIMIT 20",
        ),
    ]

    for header, query in queries:
        print("\n" + "=" * 80)
        print(header)
        print("=" * 80)
        print(f"Query: {query}\n")
        try:
            cursor = conn.cursor()
            cursor.execute(query)
            rows = cursor.fetchall()
            columns = [desc[0] for desc in cursor.description] if cursor.description else []
            if columns:
                col_widths = [max(len(str(c)), 12) for c in columns]
                header_row = " | ".join(str(c).ljust(w) for c, w in zip(columns, col_widths))
                print(header_row)
                print("-" * len(header_row))
                for row in rows:
                    print(" | ".join(str(v).ljust(w) if v is not None else "NULL".ljust(w) for v, w in zip(row, col_widths)))
            else:
                for row in rows:
                    print(row)
            print(f"\nRows returned: {len(rows)}")
            cursor.close()
        except Exception as e:
            print(f"ERROR: {e}")
            continue

    conn.close()
    print("\n" + "=" * 80)
    print("Done.")
    print("=" * 80)


if __name__ == "__main__":
    main()
