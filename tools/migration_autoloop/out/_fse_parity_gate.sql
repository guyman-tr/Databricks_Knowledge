WITH target AS (
  SELECT DATE_FORMAT(DATEADD(DAY, -1, CURRENT_DATE()), 'yyyyMMdd') AS d
),
mig AS (
  SELECT COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(TotalPositionsAmount, 0) AS DECIMAL(38,10))) AS s1,
    SUM(CAST(COALESCE(TotalMirrorPositionsAmount, 0) AS DECIMAL(38,10))) AS s2,
    SUM(CAST(COALESCE(TotalStockPositionAmount, 0) AS DECIMAL(38,10))) AS s3
  FROM dwh_daily_process.migration_tables.fact_snapshotequity
  WHERE LEFT(CAST(DateRangeID AS STRING), 8) = (SELECT d FROM target)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(TotalPositionsAmount, 0) AS DECIMAL(38,10))) AS s1,
    SUM(CAST(COALESCE(TotalMirrorPositionsAmount, 0) AS DECIMAL(38,10))) AS s2,
    SUM(CAST(COALESCE(TotalStockPositionAmount, 0) AS DECIMAL(38,10))) AS s3
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid
  WHERE LEFT(CAST(DateRangeID AS STRING), 8) = (SELECT d FROM target)
),
x AS (
  SELECT mig.rows_cnt AS mr, gold.rows_cnt AS gr,
    COALESCE(mig.s1, 0) AS ms1, COALESCE(gold.s1, 0) AS gs1,
    COALESCE(mig.s2, 0) AS ms2, COALESCE(gold.s2, 0) AS gs2,
    COALESCE(mig.s3, 0) AS ms3, COALESCE(gold.s3, 0) AS gs3
  FROM mig CROSS JOIN gold
)
SELECT CASE
  WHEN mr = gr AND ms1 = gs1 AND ms2 = gs2 AND ms3 = gs3
    THEN CONCAT('PARITY_PASS date=', (SELECT d FROM target))
  ELSE raise_error(
    CONCAT('PARITY_FAIL date=', (SELECT d FROM target),
           ' mr=', CAST(mr AS STRING), ' gr=', CAST(gr AS STRING),
           ' ms1=', CAST(ms1 AS STRING), ' gs1=', CAST(gs1 AS STRING),
           ' ms2=', CAST(ms2 AS STRING), ' gs2=', CAST(gs2 AS STRING),
           ' ms3=', CAST(ms3 AS STRING), ' gs3=', CAST(gs3 AS STRING))
  )
END AS parity_status
FROM x
