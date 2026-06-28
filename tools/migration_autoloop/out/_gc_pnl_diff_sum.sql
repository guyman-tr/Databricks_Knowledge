WITH g AS (
  SELECT CID, PnL, CopyFundAUM FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers WHERE DateID = 20260622
),
m AS (
  SELECT CID, PnL, CopyFundAUM FROM dwh_daily_process.migration_tables.Fact_Guru_Copiers WHERE DateID = 20260622
)
SELECT
  SUM(CAST(m.PnL AS DECIMAL(38,4)) - CAST(g.PnL AS DECIMAL(38,4))) AS pnl_diff_sum,
  COUNT(*) AS mismatch_rows
FROM m JOIN g USING (CID)
WHERE m.PnL <> g.PnL OR m.CopyFundAUM <> g.CopyFundAUM
