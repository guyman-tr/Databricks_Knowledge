SELECT 'gold_view' AS side, MAX(etr_ymd) AS max_ymd, COUNT(*) AS total_rows
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid
UNION ALL
SELECT 'mig_view', MAX(etr_ymd), COUNT(*)
FROM dwh_daily_process.migration_tables.v_fact_snapshotequity_fromdateid
UNION ALL
SELECT 'mig_fact', CAST(NULL AS STRING), COUNT(*)
FROM dwh_daily_process.migration_tables.fact_snapshotequity
