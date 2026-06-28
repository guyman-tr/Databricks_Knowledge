INSERT INTO dwh_daily_process.migration_tables.fact_snapshotequity (
  CID, DateRangeID, TotalPositionsAmount, TotalCash, InProcessCashouts,
  TotalMirrorPositionsAmount, TotalMirrorCash, TotalStockOrders, TotalMirrorStockOrders,
  RealizedEquity, Credit, AUM, BonusCredit, CreditID, UpdateDate,
  TotalStockPositionAmount, TotalMirrorStockPositionAmount,
  TotalCryptoPositionAmount, TotalMirrorCryptoPositionAmount,
  TotalRealStocks, TotalRealCrypto, TotalRealCryptoLoan, TotalCashCalculation,
  TotalCryptoPositionAmount_TRS, TotalMirrorCryptoPositionAmount_TRS, Total_TRSCrypto,
  TotalMirrorRealFuturesPositionAmount, TotalRealFutures, TotalFuturesProviderMargin,
  TotalFuturesLockedCash, TotalStocksMargin, TotalStockMarginLoanValue
)
SELECT
  g.CID, g.DateRangeID, g.TotalPositionsAmount, g.TotalCash, g.InProcessCashouts,
  g.TotalMirrorPositionsAmount, g.TotalMirrorCash, g.TotalStockOrders, g.TotalMirrorStockOrders,
  g.RealizedEquity, g.Credit, g.AUM, g.BonusCredit, g.CreditID, g.UpdateDate,
  g.TotalStockPositionAmount, g.TotalMirrorStockPositionAmount,
  g.TotalCryptoPositionAmount, g.TotalMirrorCryptoPositionAmount,
  g.TotalRealStocks, g.TotalRealCrypto, g.TotalRealCryptoLoan, g.TotalCashCalculation,
  g.TotalCryptoPositionAmount_TRS, g.TotalMirrorCryptoPositionAmount_TRS, g.Total_TRSCrypto,
  CAST(0 AS DECIMAL(38,10)), CAST(0 AS DECIMAL(38,10)), CAST(0 AS DECIMAL(38,10)),
  CAST(0 AS DECIMAL(38,10)), CAST(0 AS DECIMAL(38,10)), CAST(0 AS DECIMAL(38,10))
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid g
WHERE g.etr_ymd = '2026-06-22'
