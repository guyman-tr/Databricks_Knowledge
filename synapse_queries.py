"""Example: query Synapse metadata using the reusable utility."""
from synapse_connect import connect, run_query, print_table


def describe_object(conn, table_name, schema="DWH_dbo"):
    """Get full metadata for a Synapse table: columns, distribution, row count."""
    print(f"\n{'='*60}")
    print(f"  {schema}.{table_name}")
    print(f"{'='*60}\n")

    cols, rows = run_query(conn, """
        SELECT COLUMN_NAME, DATA_TYPE,
               CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE,
               IS_NULLABLE, ORDINAL_POSITION
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = ? AND TABLE_SCHEMA = ?
        ORDER BY ORDINAL_POSITION
    """, [table_name, schema])
    print(f"--- Columns ({len(rows)}) ---")
    print_table(cols, rows)

    cols, rows = run_query(conn, """
        SELECT t.name AS table_name,
               td.distribution_policy_desc AS distribution_type,
               c.name AS distribution_column,
               i.type_desc AS index_type
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        LEFT JOIN sys.pdw_table_distribution_properties td ON t.object_id = td.object_id
        LEFT JOIN sys.pdw_column_distribution_properties cd
            ON t.object_id = cd.object_id AND cd.distribution_ordinal = 1
        LEFT JOIN sys.columns c ON cd.object_id = c.object_id AND cd.column_id = c.column_id
        LEFT JOIN sys.indexes i ON t.object_id = i.object_id AND i.index_id <= 1
        WHERE t.name = ? AND s.name = ?
    """, [table_name, schema])
    print("--- Distribution & Index ---")
    print_table(cols, rows)

    try:
        cols, rows = run_query(conn, """
            SELECT SUM(row_count) AS approx_rows
            FROM sys.dm_pdw_nodes_db_partition_stats ps
            JOIN sys.pdw_nodes_tables nt
                ON ps.object_id = nt.object_id AND ps.distribution_id = nt.distribution_id
            JOIN sys.pdw_table_mappings tm ON nt.name = tm.physical_name
            JOIN sys.tables t ON tm.object_id = t.object_id
            JOIN sys.schemas sc ON t.schema_id = sc.schema_id
            WHERE t.name = ? AND sc.name = ? AND ps.index_id < 2
        """, [table_name, schema])
        print("--- Row Count ---")
        print_table(cols, rows)
    except Exception as e:
        print(f"Row count unavailable: {e}\n")


if __name__ == "__main__":
    conn = connect()
    for obj in ["Dim_Customer", "Fact_BillingDeposit", "Dim_Country"]:
        describe_object(conn, obj)
    conn.close()
    print("Done.")
