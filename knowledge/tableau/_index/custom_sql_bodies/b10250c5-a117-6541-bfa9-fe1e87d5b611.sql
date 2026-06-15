select * except (InstrumentType)
from
(
select *
,case when rank_instrument='ETF_others' then 'ETF'
when rank_instrument='Indices_others' then 'Indices'
when rank_instrument='Stocks_others' then 'Stocks'
when rank_instrument='Crypto Currencies_others' then 'Crypto Currencies'
when rank_instrument='Currencies_others' then 'Currencies'
when rank_instrument='Commodities_others' then 'Commodities'
else InstrumentType end as InstrumentType_dash
,0 as pnl_etoro_0

from
(
select base.*, inst.InstrumentID,inst.InstrumentType, coalesce(inst.InstrumentDisplayName,base.rank_instrument) as InstrumentDisplayName_dash
from
(
select *from risk.risk_output_rm_tables_diffusion_etoro_pnl_instruments_2_etoro_pnl_clients
 union all
select * from risk.risk_output_rm_tables_diffusion_etoro_pnl_others_2_etoro_pnl_clients
)base
left join risk.risk_output_rm_tables_diffusion_main_instrument_details inst
on base.rank_instrument=inst.Name

)final_temp
)final_table