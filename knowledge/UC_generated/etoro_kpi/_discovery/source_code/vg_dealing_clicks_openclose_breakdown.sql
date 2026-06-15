-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.vg_dealing_clicks_openclose_breakdown
-- Captured: 2026-05-19T15:19:45Z
-- ==========================================================================

select
  cbd.Date,
  cbd.DateID,
  cbd.SellCurrency,
  cbd.Club,
  cbd.CID,
  cbd.IsBuy,
  cbd.HeldOnReportDate,
  cbd.HedgeServerID,
  cbd.InstrumentID,
  cbd.InstrumentDisplayName,
  cbd.InstrumentName,
  cbd.InstrumentTypeID,
  cbd.InstrumentType,
  cbd.IsCopy,
  cbd.IsCFD,
  cbd.Symbol,
  cbd.Leverage,
  cbd.Exchange,
  cbd.CountryID,
  cbd.Country,
  cbd.Region,
  cbd.RegulationID,
  cbd.Regulation,
  cbd.IsIslamic,
  cbd.Size_of_Tickets,
  cbd.OpenOrClose,
  cbd.OpenOrCloseID,
  cbd.Click,
  cbd.Volume,
  cbd.Units,
  cbd.FullCommission,
  cbd.InitialAmountUSDOnOpen,
  cbd.UpdateDate,
  cbd.IsPI,
  cbd.IsTicketFee,
  -1 * cbd.TicketFee as TicketFee,
  cbd.IsAirDrop,
  cbd.IsFuture,
  cbd.etr_y,
  cbd.etr_ym,
  cbd.etr_ymd,
  cbd.HaseMoneyAccount,
  cbd.IsIBANClick,
  cbd.IsFTDClick,
  cbd.IsLowTouch,
  di.Multiplier,
  cfd.Manager
from
  main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown cbd
    join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
      on cbd.InstrumentID = di.InstrumentID
    join main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked cfd
      on cbd.CID = cfd.CID
