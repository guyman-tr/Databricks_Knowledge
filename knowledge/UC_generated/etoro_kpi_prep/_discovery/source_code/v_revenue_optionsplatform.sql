-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_revenue_optionsplatform
-- Captured: 2026-05-19T12:22:54Z
-- ==========================================================================

WITH PREP AS (
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
