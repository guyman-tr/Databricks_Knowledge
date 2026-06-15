-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_dealing.newhedgedash_email_csv
-- Captured: 2026-05-19T12:47:28Z
-- ==========================================================================

SELECT
    Date,
    HS,
    LiquidityAccountID,
    LiquidityAccountName,
    INS,
    InstrumentType,
    Symbol,
    Clients_Units_Buy,
    Clients_Units_Sell,
    Clients_Units,
    eToro_Units,
    Diff_Units,
    Clients_NOPUSD_Buy,
    Clients_NOPUSD_Sell,
    Clients_NOPUSD,
    eToro_NOPUSD,
    Uncovered_NOP,
    ISINCode,
    Ask,
    Bid,
    UpdateDate
FROM bi_dealing.bi_output_dealing_nhd_dashboard
WHERE Date = (SELECT MAX(Date) FROM bi_dealing.bi_output_dealing_nhd_dashboard) limit(100)
