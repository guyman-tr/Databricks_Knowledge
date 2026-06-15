-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.ddr_pnl_v
-- Captured: 2026-05-19T15:11:36Z
-- ==========================================================================

SELECT
  dd.DateID,
  pnl.`Date` AS `Date`,
  dd.CalendarYearMonth,
  dd.CalendarQuarter,
  dd.CalendarYear,
  STRING(pnl.RealCID) AS RealCID,
  pnl.InstrumentTypeID,
  ins.InstrumentType,
  pnl.IsCopy,
  pnl.IsSettled,
  pnl.IsFuture,
  pnl.IsLeveraged,
  pnl.IsBuy,
  pnl.IsCopyFund,
  pnl.IsSQF,
  pnl.UnrealizedPnLChange,
  pnl.NetProfit,
  pnl.CountPositions,
  pnl.UpdateDate
FROM
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl pnl
    INNER JOIN main.bi_output.bi_output_vg_date dd
      ON pnl.DateID = dd.DateID
    LEFT JOIN main.bi_output.bi_ouput_v_dim_instrumenttype ins
      ON pnl.InstrumentTypeID = ins.InstrumentTypeID
