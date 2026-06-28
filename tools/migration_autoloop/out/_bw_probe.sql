WITH gd AS (SELECT DISTINCT ModificationDateID AS d FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw WHERE ModificationDateID IS NOT NULL),
md AS (SELECT DISTINCT ModificationDateID AS d FROM dwh_daily_process.migration_tables.fact_billingwithdraw WHERE ModificationDateID IS NOT NULL),
common AS (SELECT MAX(gd.d) AS cd FROM gd JOIN md ON gd.d = md.d),
mig AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT WithdrawPaymentID) AS dw,
    SUM(CAST(COALESCE(Amount_Withdraw, 0) AS DECIMAL(38,4))) AS s_amt,
    SUM(CAST(COALESCE(Commission, 0) AS DECIMAL(38,4))) AS s_comm
  FROM dwh_daily_process.migration_tables.fact_billingwithdraw
  WHERE ModificationDateID = (SELECT cd FROM common)
),
gold AS (
  SELECT COUNT(*) AS rows_cnt, COUNT(DISTINCT WithdrawPaymentID) AS dw,
    SUM(CAST(COALESCE(Amount_Withdraw, 0) AS DECIMAL(38,4))) AS s_amt,
    SUM(CAST(COALESCE(Commission, 0) AS DECIMAL(38,4))) AS s_comm
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw
  WHERE ModificationDateID = (SELECT cd FROM common)
)
SELECT (SELECT cd FROM common) AS common_date,
  mig.rows_cnt AS mig_rows, gold.rows_cnt AS gold_rows,
  mig.dw AS mig_wpid, gold.dw AS gold_wpid,
  mig.s_amt AS mig_amount, gold.s_amt AS gold_amount,
  mig.s_comm AS mig_commission, gold.s_comm AS gold_commission
FROM mig CROSS JOIN gold
