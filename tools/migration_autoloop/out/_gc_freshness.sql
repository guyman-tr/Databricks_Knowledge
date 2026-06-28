SELECT 'gold_gc' AS obj, MAX(DateID) AS max_dateid, COUNT(*) AS total_rows
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers
UNION ALL
SELECT 'mig_gc', MAX(DateID), COUNT(*)
FROM dwh_daily_process.migration_tables.Fact_Guru_Copiers
UNION ALL
SELECT 'gold_fsc', CAST(MAX(LEFT(CAST(DateRangeID AS STRING),8)) AS INT), COUNT(*)
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer
UNION ALL
SELECT 'mig_fsc', CAST(MAX(LEFT(CAST(DateRangeID AS STRING),8)) AS INT), COUNT(*)
FROM dwh_daily_process.migration_tables.fact_snapshotcustomer
