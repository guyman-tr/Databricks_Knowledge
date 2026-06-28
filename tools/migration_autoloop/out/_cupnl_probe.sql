WITH gd AS (SELECT DISTINCT DateModified AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl WHERE DateModified IS NOT NULL),
md AS (SELECT DISTINCT DateModified AS d FROM dwh_daily_process.migration_tables.fact_customerunrealized_pnl WHERE DateModified IS NOT NULL),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT CID) AS cids,
    SUM(CAST(COALESCE(PositionPnL, 0) AS DECIMAL(38,4))) AS s_pnl,
    SUM(CAST(COALESCE(NOP, 0) AS DECIMAL(38,4))) AS s_nop,
    SUM(CAST(COALESCE(Notional, 0) AS DECIMAL(38,4))) AS s_not
  FROM dwh_daily_process.migration_tables.fact_customerunrealized_pnl
  WHERE DateModified = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT CID) AS cids,
    SUM(CAST(COALESCE(PositionPnL, 0) AS DECIMAL(38,4))) AS s_pnl,
    SUM(CAST(COALESCE(NOP, 0) AS DECIMAL(38,4))) AS s_nop,
    SUM(CAST(COALESCE(Notional, 0) AS DECIMAL(38,4))) AS s_not
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl
  WHERE DateModified = (SELECT cd FROM common)
)
SELECT (SELECT cd FROM common) AS common_date,
  mig.rows_cnt AS mig_rows, gold.rows_cnt AS gold_rows,
  mig.cids AS mig_cids, gold.cids AS gold_cids,
  mig.s_pnl AS mig_pnl, gold.s_pnl AS gold_pnl,
  mig.s_nop AS mig_nop, gold.s_nop AS gold_nop,
  mig.s_not AS mig_notional, gold.s_not AS gold_notional
FROM mig CROSS JOIN gold
