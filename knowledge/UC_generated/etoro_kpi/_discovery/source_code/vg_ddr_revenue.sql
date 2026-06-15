-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.vg_ddr_revenue
-- Captured: 2026-05-19T15:19:32Z
-- ==========================================================================

SELECT 
    dfr.DateID,
    dfr.Date,
    dfr.RealCID,
    dfr.ActionTypeID,
    dfr.ActionType,
    dfr.InstrumentTypeID,
    dfr.IsSettled,
    dfr.IsCopy,
    dfr.Metric,
    dfr.Amount,
    dfr.CountTransactions,
    dfr.IncludedInTotalRevenue,
    dfr.CountAsActiveTrade,
    dfr.UpdateDate,
    dfr.IsBuy,
    dfr.IsLeveraged,
    dfr.IsFuture,
    dfr.IsCopyFund,
    dfr.IsOpenedFromIBAN,
    dfr.IsClosedToIBAN,
    dfr.IsRecurring,
    dfr.IsAirDrop,
    dfr.IsSQF,
    dfr.RevenueMetricID,
    dfr.RevenueMetricCategoryID,
    dfr.IsMarginTrade,
    dfr.IsC2P,
    drm.RevenueMetricCategory,
    vit.InstrumentType,
    CASE 
        WHEN dfr.IsFuture = 1 OR vit.InstrumentTypeID IN (1, 2, 4) THEN 1 
        ELSE 0 
    END AS IsICC
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions dfr
JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics drm
    ON dfr.RevenueMetricID = drm.RevenueMetricID
JOIN main.bi_output.bi_ouput_v_dim_instrumenttype vit 
    ON dfr.InstrumentTypeID = vit.InstrumentTypeID
