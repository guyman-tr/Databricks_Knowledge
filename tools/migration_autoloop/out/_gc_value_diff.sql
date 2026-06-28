WITH g AS (
  SELECT CID, Cash, Investment, PnL, CopyFundAUM
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers WHERE DateID = 20260622
),
m AS (
  SELECT CID, Cash, Investment, PnL, CopyFundAUM
  FROM dwh_daily_process.migration_tables.Fact_Guru_Copiers WHERE DateID = 20260622
)
SELECT m.CID, m.Cash AS m_cash, g.Cash AS g_cash,
  m.PnL AS m_pnl, g.PnL AS g_pnl, m.CopyFundAUM AS m_aum, g.CopyFundAUM AS g_aum
FROM m JOIN g USING (CID)
WHERE NOT (m.Cash <=> g.Cash AND m.Investment <=> g.Investment AND m.PnL <=> g.PnL AND m.CopyFundAUM <=> g.CopyFundAUM)
ORDER BY ABS(CAST(m.Cash AS DOUBLE) - CAST(g.Cash AS DOUBLE)) DESC
LIMIT 20
