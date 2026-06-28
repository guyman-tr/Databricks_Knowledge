WITH gd AS (
  SELECT DISTINCT LEFT(CAST(DateRangeID AS STRING), 8) AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer WHERE DateRangeID IS NOT NULL
),
md AS (
  SELECT DISTINCT LEFT(CAST(DateRangeID AS STRING), 8) AS d FROM dwh_daily_process.migration_tables.fact_snapshotcustomer WHERE DateRangeID IS NOT NULL
),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT RealCID) AS dcid,
    SUM(CAST(COALESCE(GCID, 0) AS DECIMAL(38,0))) AS s_gcid
  FROM dwh_daily_process.migration_tables.fact_snapshotcustomer
  WHERE LEFT(CAST(DateRangeID AS STRING), 8) = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT RealCID) AS dcid,
    SUM(CAST(COALESCE(GCID, 0) AS DECIMAL(38,0))) AS s_gcid
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer
  WHERE LEFT(CAST(DateRangeID AS STRING), 8) = (SELECT cd FROM common)
)
SELECT (SELECT cd FROM common) AS common_date,
  mig.rows_cnt AS mig_rows, gold.rows_cnt AS gold_rows,
  mig.dcid AS mig_cid, gold.dcid AS gold_cid,
  mig.s_gcid AS mig_gcid_sum, gold.s_gcid AS gold_gcid_sum
FROM mig CROSS JOIN gold
