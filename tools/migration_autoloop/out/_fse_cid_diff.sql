WITH g AS (
  SELECT CID FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid
  WHERE etr_ymd = '2026-06-22'
),
m AS (
  SELECT CID FROM dwh_daily_process.migration_tables.fact_snapshotequity
  WHERE LEFT(CAST(DateRangeID AS STRING), 8) = '20260622'
)
SELECT
  (SELECT COUNT(*) FROM g) AS gold_cids,
  (SELECT COUNT(*) FROM m) AS mig_cids,
  (SELECT COUNT(*) FROM g LEFT ANTI JOIN m USING (CID)) AS gold_only,
  (SELECT COUNT(*) FROM m LEFT ANTI JOIN g USING (CID)) AS mig_only
