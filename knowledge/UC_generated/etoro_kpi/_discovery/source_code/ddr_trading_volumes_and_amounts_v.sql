-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.ddr_trading_volumes_and_amounts_v
-- Captured: 2026-05-19T15:11:58Z
-- ==========================================================================

SELECT
  dd.DateID,
  tva.`Date` AS `Date`,
  dd.CalendarYearMonth,
  dd.CalendarQuarter,
  dd.CalendarYear,
  STRING(tva.RealCID) AS RealCID,
  tva.InstrumentTypeID,
  ins.InstrumentType,
  tva.IsSettled,
  tva.IsCopy,
  tva.IsBuy,
  tva.IsLeverage,
  tva.IsFuture,
  tva.IsCopyFund,
  tva.IsOpenedFromIBAN,
  tva.IsClosedToIBAN,
  tva.IsRecurring,
  tva.IsAirDrop,
  tva.VolumeOpen,
  tva.VolumeClose,
  tva.InvestedAmountOpen,
  tva.InvestedAmountClosed,
  tva.TotalVolume,
  tva.NetInvestedAmount,
  tva.CountOpenTransactions,
  tva.CountCloseTransactions,
  tva.CountTotalTransactions,
  tva.UpdateDate,
  tva.IsSQF,
  tva.IsMarginTrade,
  tva.IsC2P
FROM
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts tva
    INNER JOIN main.bi_output.bi_output_vg_date dd
      ON tva.DateID = dd.DateID
    LEFT JOIN main.bi_output.bi_ouput_v_dim_instrumenttype ins
      ON tva.InstrumentTypeID = ins.InstrumentTypeID
