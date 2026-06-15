-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.ddr_revenue_v
-- Captured: 2026-05-19T15:11:47Z
-- ==========================================================================

SELECT
  dd.DateID,
  rga.Date AS `Date`,
  dd.CalendarYearMonth,
  dd.CalendarQuarter,
  dd.CalendarYear,
  STRING(rga.RealCID) AS RealCID,
  rga.ActionTypeID,
  rga.ActionType,
  rga.InstrumentTypeID,
  ins.InstrumentType,
  rga.IsSettled,
  rga.IsCopy,
  rga.Metric,
  rga.CountAsActiveTrade,
  rga.IncludedInTotalRevenue,
  rmtr.RevenueMetricCategory,
  rga.RevenueMetricCategoryID,
  rga.IsBuy,
  rga.IsLeveraged,
  rga.IsFuture,
  rga.IsCopyFund,
  rga.IsOpenedFromIBAN,
  rga.IsClosedToIBAN,
  rga.IsRecurring,
  rga.IsAirDrop,
  rga.IsSQF,
  rga.IsMarginTrade,
  rga.IsC2P,
  SUM(rga.CountTransactions) AS CountTransactions,
  SUM(rga.Amount) AS RevenueAmount
FROM
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions rga
    INNER JOIN main.bi_output.bi_output_vg_date dd
      ON rga.DateID = dd.DateID
    LEFT JOIN main.bi_output.bi_ouput_v_dim_instrumenttype ins
      ON rga.InstrumentTypeID = ins.InstrumentTypeID
    LEFT JOIN main.bi_output.bi_output_customer_ddr_revenue_metrics rmtr
      ON rga.Metric = rmtr.Metric
GROUP BY
  rga.Date,
  dd.DateID,
  dd.CalendarYearMonth,
  dd.CalendarQuarter,
  dd.CalendarYear,
  STRING(rga.RealCID),
  rga.ActionTypeID,
  rga.ActionType,
  rga.InstrumentTypeID,
  ins.InstrumentType,
  rga.IsSettled,
  rga.IsCopy,
  rga.Metric,
  rga.CountAsActiveTrade,
  rga.IncludedInTotalRevenue,
  rmtr.RevenueMetricCategory,
  rga.RevenueMetricCategoryID,
  rga.IsBuy,
  rga.IsLeveraged,
  rga.IsFuture,
  rga.IsCopyFund,
  rga.IsOpenedFromIBAN,
  rga.IsClosedToIBAN,
  rga.IsRecurring,
  rga.IsAirDrop,
  rga.IsSQF,
  rga.IsMarginTrade,
  rga.IsC2P
