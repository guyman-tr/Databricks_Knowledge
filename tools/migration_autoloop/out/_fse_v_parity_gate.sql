WITH target AS (SELECT '20260622' AS d),
mig AS (
  SELECT COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(TotalPositionsAmount, 0) AS DECIMAL(38,10))) AS s1,
    SUM(CAST(COALESCE(TotalMirrorPositionsAmount, 0) AS DECIMAL(38,10))) AS s2,
    SUM(CAST(COALESCE(TotalStockPositionAmount, 0) AS DECIMAL(38,10))) AS s3
  FROM dwh_daily_process.migration_tables.v_fact_snapshotequity_fromdateid
  WHERE etr_ymd = '2026-06-22'
),
gold AS (
  SELECT COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(TotalPositionsAmount, 0) AS DECIMAL(38,10))) AS s1,
    SUM(CAST(COALESCE(TotalMirrorPositionsAmount, 0) AS DECIMAL(38,10))) AS s2,
    SUM(CAST(COALESCE(TotalStockPositionAmount, 0) AS DECIMAL(38,10))) AS s3
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid
  WHERE etr_ymd = '2026-06-22'
)
SELECT mig.rows_cnt AS mig_rows, gold.rows_cnt AS gold_rows,
  mig.s1 AS mig_s1, gold.s1 AS gold_s1,
  mig.s2 AS mig_s2, gold.s2 AS gold_s2,
  mig.s3 AS mig_s3, gold.s3 AS gold_s3
FROM mig CROSS JOIN gold
