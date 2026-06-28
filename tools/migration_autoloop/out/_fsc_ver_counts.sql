SELECT 'current' AS ver, COUNT(*) AS rows, COUNT(DISTINCT DateRangeID) AS ranges FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer
UNION ALL SELECT '93', COUNT(*), COUNT(DISTINCT DateRangeID) FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer VERSION AS OF 93
UNION ALL SELECT '92', COUNT(*), COUNT(DISTINCT DateRangeID) FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer VERSION AS OF 92
UNION ALL SELECT '91', COUNT(*), COUNT(DISTINCT DateRangeID) FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer VERSION AS OF 91
ORDER BY ver
