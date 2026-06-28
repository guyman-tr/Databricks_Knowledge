WITH g AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT CID) AS cids,
    SUM(CAST(COALESCE(AUM,0) AS DECIMAL(38,4))) AS s_aum,
    SUM(CAST(COALESCE(RealizedEquity,0) AS DECIMAL(38,4))) AS s_req,
    SUM(CAST(COALESCE(TotalCash,0) AS DECIMAL(38,4))) AS s_cash
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid
  WHERE etr_ymd = '2026-05-22'
),
m AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT CID) AS cids,
    SUM(CAST(COALESCE(AUM,0) AS DECIMAL(38,4))) AS s_aum,
    SUM(CAST(COALESCE(RealizedEquity,0) AS DECIMAL(38,4))) AS s_req,
    SUM(CAST(COALESCE(TotalCash,0) AS DECIMAL(38,4))) AS s_cash
  FROM dwh_daily_process.migration_tables.v_fact_snapshotequity_fromdateid
  WHERE etr_ymd = '2026-05-22'
)
SELECT '2026-05-22' AS common_ymd,
  m.rows_cnt AS mig_rows, g.rows_cnt AS gold_rows,
  m.cids AS mig_cids, g.cids AS gold_cids,
  m.s_aum AS mig_aum, g.s_aum AS gold_aum,
  m.s_req AS mig_realizedequity, g.s_req AS gold_realizedequity,
  m.s_cash AS mig_totalcash, g.s_cash AS gold_totalcash
FROM m CROSS JOIN g
