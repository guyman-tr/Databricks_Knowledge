-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_OptionsPlatform
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_revenue_optionsplatform
-- Col comments: 25 added, 0 preserved (existing), 1 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent — safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_revenue_optionsplatform (
  DateID COMMENT 'CONVERT(NVARCHAR(8), TradeDate, 112). Source: Sodreconciliation_apex_EXT1047_RevenueReports.TradeDate. (T2 — Function_Revenue_OptionsPlatform)',
  Date COMMENT 'CONVERT(DATE, TradeDate). Source: Sodreconciliation_apex_EXT1047_RevenueReports.TradeDate. (T2 — Function_Revenue_OptionsPlatform)',
  RealCID COMMENT 'Direct pass-through from Dim_Customer.RealCID. (T1 — Function_Revenue_OptionsPlatform)',
  ActionTypeID COMMENT 'CASE WHEN Side = ''B'' THEN 1 WHEN Side = ''S'' THEN 4 END. Source: Sodreconciliation_apex_EXT1047_RevenueReports.Side. (T2 — Function_Revenue_OptionsPlatform)',
  ActionType COMMENT 'CASE WHEN Side = ''B'' THEN ''ManualPositionOpen'' WHEN Side = ''S'' THEN ''ManualPositionClose'' END. Source: Sodreconciliation_apex_EXT1047_RevenueReports.Side. (T2 — Function_Revenue_OptionsPlatform)',
  InstrumentTypeID COMMENT 'CASE WHEN InstrumentType = ''Option'' THEN 9 WHEN InstrumentType = ''Equity'' THEN 5 END. Source: Sodreconciliation_apex_EXT1047_RevenueReports.InstrumentType. (T2 — Function_Revenue_OptionsPlatform)',
  IsSettled COMMENT '1. Source: —. (T2 — Function_Revenue_OptionsPlatform)',
  IsCopy COMMENT '0. Source: —. (T2 — Function_Revenue_OptionsPlatform)',
  Metric COMMENT '''Options_PFOF''. Source: —. (T2 — Function_Revenue_OptionsPlatform)',
  Amount COMMENT 'SUM(ABS(CustomerPFOFPayback)) WHERE ClearingAccount NOT IN (excluded house accounts) AND TradeDate BETWEEN CONVERT(DATE, CONVERT(VARCHAR(8), @sdateInt), 112) AND CONVERT(DATE, CONVERT(VARCHAR(8), @edateInt), 112) (GROUP BY trade date, customer, side, instrument type, etc.). Source: Sodreconciliation_apex_EXT1047_RevenueReports.CustomerPFOFPayback. (T2 — Function_Revenue_OptionsPlatform)',
  CountTransactions COMMENT 'COUNT(OrderID). Source: Sodreconciliation_apex_EXT1047_RevenueReports.OrderID. (T2 — Function_Revenue_OptionsPlatform)',
  IncludedInTotalRevenue COMMENT '1. Source: —. (T2 — Function_Revenue_OptionsPlatform)',
  CountAsActiveTrade COMMENT 'CASE WHEN Side = ''B'' THEN 1 ELSE 0 END. Source: Sodreconciliation_apex_EXT1047_RevenueReports.Side. (T2 — Function_Revenue_OptionsPlatform)',
  UpdateDate COMMENT 'GETDATE(). Source: —. (T2 — Function_Revenue_OptionsPlatform)',
  IsBuy COMMENT '1. Source: —. (T2 — Function_Revenue_OptionsPlatform)',
  IsLeveraged COMMENT '0. Source: —. (T2 — Function_Revenue_OptionsPlatform)',
  IsFuture COMMENT '0. Source: —. (T2 — Function_Revenue_OptionsPlatform)',
  IsCopyFund COMMENT '0. Source: —. (T2 — Function_Revenue_OptionsPlatform)',
  IsOpenedFromIBAN COMMENT '0. Source: —. (T2 — Function_Revenue_OptionsPlatform)',
  IsClosedToIBAN COMMENT '0. Source: —. (T2 — Function_Revenue_OptionsPlatform)',
  IsRecurring,
  IsAirDrop COMMENT '0. Source: —. (T2 — Function_Revenue_OptionsPlatform)',
  IsValidCustomer COMMENT 'Direct pass-through from Dim_Customer.IsValidCustomer. (T1 — Function_Revenue_OptionsPlatform)',
  IsCreditReportValidCB COMMENT 'Direct pass-through from Dim_Customer.IsCreditReportValidCB. (T1 — Function_Revenue_OptionsPlatform)',
  FirstTradeDate COMMENT 'First row per ClearingAccount (ROW_NUMBER partition). Source: Sodreconciliation_apex_EXT1047_RevenueReports.TradeDate. (T2 — Function_Revenue_OptionsPlatform)',
  FirstTradeDateID COMMENT 'CAST(FORMAT(CAST(TradeDate AS DATE),''yyyyMMdd'') AS INT) on first trade. Source: Sodreconciliation_apex_EXT1047_RevenueReports.TradeDate. (T2 — Function_Revenue_OptionsPlatform)'
)
COMMENT 'BI_DB_dbo.Function_Revenue_OptionsPlatform > Aggregates US options/equity PFOF (payment for order flow) payback from Apex reconciliation revenue reports per customer and trade date, shaped like other revenue metrics (action types, instrument type, transaction counts). Maps clearing accounts to internal customers via the US broker options bridge table and excludes designated house accounts. The Amount column is SUM(ABS(CustomerPFOFPayback)) only over rows whose TradeDate falls between the parameter dates and whose ClearingAccount is not in the excluded house list.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Revenue_OptionsPlatform > Aggregates US options/equity PFOF (payment for order flow) payback from Apex reconciliation revenue reports per customer and trade date, shaped like other revenue metrics (action types, instrument type, transaction counts). Maps clearing accounts to internal customers via the US broker options bridge table and excludes designated house accounts. The Amount column is SUM(ABS(CustomerPFOFPayback)) only over rows whose TradeDate falls between the parameter dates and whose ClearingAccount is not in the excluded house list.')
WITH SCHEMA COMPENSATION
AS WITH PREP AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY ClearingAccount ORDER BY TradeDate) AS RN
    FROM main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports
),
FIRSTTRADE AS (
    SELECT * 
    FROM PREP
    WHERE RN = 1
)
SELECT 
    CAST(DATE_FORMAT(rev.TradeDate, 'yyyyMMdd') AS INT) AS DateID,
    CAST(rev.TradeDate AS DATE) AS Date,
    dc.RealCID,
    CASE WHEN rev.Side = 'B' THEN 1 WHEN rev.Side = 'S' THEN 4 END AS ActionTypeID,
    CASE WHEN rev.Side = 'B' THEN 'ManualPositionOpen' WHEN rev.Side = 'S' THEN 'ManualPositionClose' END AS ActionType,
    CASE WHEN rev.InstrumentType = 'Option' THEN 9 WHEN rev.InstrumentType = 'Equity' THEN 5 END AS InstrumentTypeID,
    1 AS IsSettled,
    0 AS IsCopy,
    'Options_PFOF' AS Metric,
    SUM(ABS(rev.CustomerPFOFPayback)) AS Amount,
    COUNT(rev.OrderID) AS CountTransactions,
    1 AS IncludedInTotalRevenue,
    CASE WHEN rev.Side = 'B' THEN 1 ELSE 0 END AS CountAsActiveTrade,
    CURRENT_TIMESTAMP() AS UpdateDate,
    1 AS IsBuy,
    0 AS IsLeveraged,
    0 AS IsFuture,
    0 AS IsCopyFund,
    0 AS IsOpenedFromIBAN,
    0 AS IsClosedToIBAN,
    0 AS IsRecurring,
    0 AS IsAirDrop,
    dc.IsValidCustomer,
    dc.IsCreditReportValidCB,
    CAST(ft.TradeDate AS DATE) AS FirstTradeDate,
    CAST(DATE_FORMAT(CAST(ft.TradeDate AS DATE), 'yyyyMMdd') AS INT) AS FirstTradeDateID
FROM PREP rev 
LEFT JOIN FIRSTTRADE ft 
    ON rev.ClearingAccount = ft.ClearingAccount
LEFT JOIN main.general.bronze_usabroker_apex_options op 
    ON rev.ClearingAccount = op.OptionsApexID 
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
    ON op.GCID = dc.GCID
WHERE rev.ClearingAccount NOT IN (
    '4GS43999',
    '4GS00100',
    '4GS00101',
    '4GS00103',
    '4GS00104'
) -- exclude house accounts
GROUP BY 
    CAST(DATE_FORMAT(rev.TradeDate, 'yyyyMMdd') AS INT),
    CAST(rev.TradeDate AS DATE),
    dc.RealCID,
    CASE WHEN rev.Side = 'B' THEN 1 WHEN rev.Side = 'S' THEN 4 END,
    CASE WHEN rev.Side = 'B' THEN 'ManualPositionOpen' WHEN rev.Side = 'S' THEN 'ManualPositionClose' END,
    CASE WHEN rev.Side = 'B' THEN 1 ELSE 0 END,
    CASE WHEN rev.InstrumentType = 'Option' THEN 9 WHEN rev.InstrumentType = 'Equity' THEN 5 END,
    dc.IsValidCustomer,
    dc.IsCreditReportValidCB,
    CAST(ft.TradeDate AS DATE),
    CAST(DATE_FORMAT(CAST(ft.TradeDate AS DATE), 'yyyyMMdd') AS INT)

;
