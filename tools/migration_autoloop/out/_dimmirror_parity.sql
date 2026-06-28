WITH mig AS (
  SELECT COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,4))) AS s_amt,
    SUM(CAST(COALESCE(RealizedEquity, 0) AS DECIMAL(38,4))) AS s_req,
    SUM(CAST(COALESCE(InitialInvestment, 0) AS DECIMAL(38,4))) AS s_inv
  FROM dwh_daily_process.migration_tables.dim_mirror
),
gold AS (
  SELECT COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(Amount, 0) AS DECIMAL(38,4))) AS s_amt,
    SUM(CAST(COALESCE(RealizedEquity, 0) AS DECIMAL(38,4))) AS s_req,
    SUM(CAST(COALESCE(InitialInvestment, 0) AS DECIMAL(38,4))) AS s_inv
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
)
SELECT
  mig.rows_cnt AS mig_rows, gold.rows_cnt AS gold_rows,
  mig.s_amt AS mig_amount, gold.s_amt AS gold_amount,
  mig.s_req AS mig_realizedequity, gold.s_req AS gold_realizedequity,
  mig.s_inv AS mig_initialinvestment, gold.s_inv AS gold_initialinvestment
FROM mig CROSS JOIN gold
