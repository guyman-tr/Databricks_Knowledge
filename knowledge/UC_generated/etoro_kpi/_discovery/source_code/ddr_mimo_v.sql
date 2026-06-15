-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.ddr_mimo_v
-- Captured: 2026-05-19T15:11:25Z
-- ==========================================================================

SELECT
  map.DateID,
  map.`Date`,
  dd.WeekNumberYear,
  dd.CalendarYearMonth,
  dd.CalendarQuarter,
  dd.CalendarYear,
  STRING(map.RealCID) AS RealCID,
  map.MIMOAction,
  map.OrigIdentifier,
  map.TransactionID,
  map.AmountUSD,
  map.AmountOrigCurrency,
  map.FundingTypeID,
  map.CurrencyID,
  map.Currency,
  map.IsPlatformFTD,
  map.IsInternalTransfer,
  map.IsRedeem,
  map.IsTradeFromIBAN,
  map.MIMOPlatform,
  map.IsGlobalFTD,
  map.IsCryptoToFiat,
  map.IsRecurring,
  map.IsIBANQuickTransfer
FROM
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms map
    INNER JOIN main.bi_output.bi_output_vg_date dd
      ON map.DateID = dd.DateID
