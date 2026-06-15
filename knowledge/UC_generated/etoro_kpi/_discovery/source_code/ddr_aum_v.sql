-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.ddr_aum_v
-- Captured: 2026-05-19T15:09:52Z
-- ==========================================================================

SELECT
  CAST(aum.RealCID AS STRING) AS RealCID,
  dd.DateID,
  aum.RealizedEquityTP AS RealizedEquityTradingPlatform,
  aum.TotalPositionPNL,
  aum.TotalInvestedAmount,
  aum.TotalEquityTP AS EquityTradingPlatform,
  aum.CashInCopy,
  aum.InvestedAmountCopy,
  aum.EquityCopy,
  aum.EquityStocksManual,
  aum.InvestedAmountStocksManual,
  aum.InvestedAmountCryptoManual,
  aum.CreditTP AS BalanceTradingPlatfrom,
  aum.IBANBalance AS BalanceIBAN,
  aum.RealizedEquityGlobal,
  aum.EquityGlobal,
  aum.CreditGlobal,
  aum.OptionsTotalEquity,
  dd.WeekNumberYear,
  dd.CalendarYearMonth,
  dd.CalendarQuarter,
  dd.CalendarYear,
  dd.IsLastDayWeek,
  dd.IsLastDayMonth,
  dd.IsLastDayQuarter,
  dd.IsLastDayYear,
  aum.`Date` AS SnapshotDate,
  aum.TotalLiabilityTP,
  aum.InProcessCashout,
  aum.NOP,
  aum.NOPCrypto,
  aum.NOPCryptoCFD,
  aum.NOPStocks,
  aum.NOPStocksCFD,
  aum.TotalRealCryptoLoan,
  aum.Bonus,
  aum.CopyInvestedAmount,
  aum.CopyStockOrders,
  aum.CopyPositionPnL,
  aum.StockInvestedAmount,
  aum.StockOrders,
  aum.StocksPositionPnL,
  aum.MirrorStockInvestedAmount,
  aum.MirrorStocksPositionPnL,
  aum.CryptoManualPositionPnL,
  aum.EquityCryptoManual,
  aum.TotalRealCrypto,
  aum.TotalRealStocks,
  aum.CreditTP AS CreditTP,
  aum.ActualNWA,
  aum.TotalLiabilityGlobal,
  aum.UpdateDate
FROM
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum aum
    INNER JOIN main.bi_output.bi_output_vg_date dd
      ON aum.DateID = dd.DateID
