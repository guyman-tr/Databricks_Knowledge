-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_vg_daily_commission
-- Captured: 2026-06-19T14:30:46Z
-- ==========================================================================

with daily_commission as 
(
  select dcr.*
  from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport dcr 
), instrument_metadata as 
(
  select InstrumentID, InstrumentDisplayName, IsFuture, Symbol
  from main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di 
), sqf_instruments as 
(
  SELECT DISTINCT etig.InstrumentID 
	FROM main.trading.bronze_etoro_trade_instrumentgroups etig
	WHERE etig.GroupID = 59
), 245_instruments_prep as 
(
  select imd.InstrumentID, imd.Symbol, imd.ISINCode
  from main.trading.bronze_etoro_trade_instrumentmetadata imd
  join main.trading.bronze_etoro_trade_providertoinstrument pti on imd.InstrumentID = pti.InstrumentID
  where ExchangeID = 33 -- RTH
    and Tradable = 1
    and VisibleInternallyOnly = 0
), 245_instruments as 
(
  select imd.*
  from main.trading.bronze_etoro_trade_instrumentmetadata imd
  join main.trading.bronze_etoro_trade_providertoinstrument pti on imd.InstrumentID = pti.InstrumentID
  join 245_instruments_prep rth on rth.isincode = imd.ISINCode
  where imd.Tradable = 1
    and pti.VisibleInternallyOnly = 0
    and imd.ExchangeID in (4,5)
)
select dc.RealCID
	 , dc.InstrumentID
	 , dc.Instrument
	 , dc.InstrumentTypeID
	 , dc.InstrumentType
	 , dc.FullDate
	 , dc.DateID
	 , dc.Commissions
	 , dc.FullCommissions
	 , dc.VolumeOnOpen
	 , dc.VolumeOnClose
	 , dc.RollOverFee
	 , dc.IsSettled
	 , dc.IsMirror
	 , dc.CommissionOnOpen
	 , dc.CommissionOnCloseAdjustment
	 , dc.FullCommissionOnOpen
	 , dc.FullCommissionOnCloseAdjustment
	 , dc.CommissionOnClose
	 , dc.FullCommissionOnClose
	 , dc.IsBuy
	 , dc.IsLeverage
	 , dc.IsAirDrop
	 , dc.SettlementTypeID
	 , dc.TicketFee
	 , dc.TicketFeeByPercent
	 , dc.AdminFee
	 , dc.SpotAdjustFee
	 , dc.InvestedAmountOpen
	 , dc.CountUU
	 , dc.IsMarginTrade  
  , fu.instrumentdisplayname
  , fu.symbol
  , case when fu.isfuture = 1 then 1 else 0 end as IsFuture
  , case when si.InstrumentID is not null then 1 else 0 end as IsSQF
  , case when tff.InstrumentID is not null then 1 else 0 end as Is_245
  , case when exchange in ('Nasdaq','NYSE', 'Regular Trading Hours - RTH') then 1 else 0 end as IsUSStock
from daily_commission dc 
join instrument_metadata fu 
  on dc.InstrumentID = fu.InstrumentID 
left join sqf_instruments si 
  on dc.InstrumentID = si.InstrumentID 
left join 245_instruments tff 
  on dc.InstrumentID = tff.InstrumentID
