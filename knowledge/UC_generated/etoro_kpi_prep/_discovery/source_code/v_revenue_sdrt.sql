-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_revenue_sdrt
-- Captured: 2026-05-19T12:23:13Z
-- ==========================================================================

SELECT
    fca.RealCID,
    fca.GCID,
    fca.DateID,
    fca.Occurred,
    -1 * fca.Amount AS SDRT,
    fca.InstrumentID,
    fca.PositionID,
    fca.IsBuy,
    fca.IsSettled,
    fca.SettlementTypeID,
    CASE WHEN fca.SettlementTypeID = 5 THEN 1 ELSE 0 END AS IsMarginTrade,
    CASE WHEN fca.MirrorID <> 0 THEN 1 ELSE 0 END AS IsCopy,
    di.InstrumentTypeID,
    fca.IsValidCustomer
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution fca
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
    ON fca.InstrumentID = di.InstrumentID
WHERE fca.ActionTypeID = 35
    AND fca.IsFeeDividend = 3
