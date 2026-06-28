WITH gd AS (SELECT DISTINCT DateID AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers WHERE DateID IS NOT NULL),
md AS (SELECT DISTINCT DateID AS d FROM dwh_daily_process.migration_tables.Fact_Guru_Copiers WHERE DateID IS NOT NULL),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT CID) AS cids,
    SUM(CAST(COALESCE(Cash,0) AS DECIMAL(38,4))) AS s_cash,
    SUM(CAST(COALESCE(Investment,0) AS DECIMAL(38,4))) AS s_inv,
    SUM(CAST(COALESCE(PnL,0) AS DECIMAL(38,4))) AS s_pnl,
    SUM(CAST(COALESCE(CopyFundAUM,0) AS DECIMAL(38,4))) AS s_aum
  FROM dwh_daily_process.migration_tables.Fact_Guru_Copiers
  WHERE DateID = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT CID) AS cids,
    SUM(CAST(COALESCE(Cash,0) AS DECIMAL(38,4))) AS s_cash,
    SUM(CAST(COALESCE(Investment,0) AS DECIMAL(38,4))) AS s_inv,
    SUM(CAST(COALESCE(PnL,0) AS DECIMAL(38,4))) AS s_pnl,
    SUM(CAST(COALESCE(CopyFundAUM,0) AS DECIMAL(38,4))) AS s_aum
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers
  WHERE DateID = (SELECT cd FROM common)
)
SELECT (SELECT cd FROM common) AS common_date,
  mig.rows_cnt AS mig_rows, gold.rows_cnt AS gold_rows,
  mig.cids AS mig_cids, gold.cids AS gold_cids,
  mig.s_cash AS mig_cash, gold.s_cash AS gold_cash,
  mig.s_inv AS mig_inv, gold.s_inv AS gold_inv,
  mig.s_pnl AS mig_pnl, gold.s_pnl AS gold_pnl,
  mig.s_aum AS mig_aum, gold.s_aum AS gold_aum
FROM mig CROSS JOIN gold
