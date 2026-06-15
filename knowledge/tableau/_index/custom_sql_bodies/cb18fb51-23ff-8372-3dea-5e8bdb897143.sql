(select scenario,value
,case when rank_instrument <> InstrumentType then rank_instrument else concat(rank_instrument,'_others') end as rank_instrument
,PnL_client_1 as pnl_client,scenario_1_shock_value as shock_value,Report_time as Report_time_clients
,InstrumentType
,coalesce (InstrumentDisplayName,concat(rank_instrument,'_others')) InstrumentDisplayName
,NOPHedged,etoro_pnl,Report_time_etoro_data,scenario_market,risk, NOP as NOP_clients
, coalesce (NOP-NOPHedged,0) as NOP_Unhedged
from
(

select final_base.*

, case when  InstrumentType in('Indices','Stocks','Crypto Currencies','ETF','Commodities') and value ='high'
and rank_instrument not in ('VIX.FUT/USD','XAU/USD','SQQQ/USD') then 'bullish'
when InstrumentType in ('Currencies') and value='low' then 'bullish'
when rank_instrument in('VIX.FUT/USD','XAU/USD','SQQQ/USD') and value='low' then'bullish'
when  InstrumentType in('Indices','Stocks','Crypto Currencies','ETF','Commodities') and value ='low'
and rank_instrument not in ('VIX.FUT/USD','XAU/USD','SQQQ/USD') then 'bearish'
when InstrumentType in ('Currencies') and value='high' then 'bearish'
when rank_instrument in ('VIX.FUT/USD','XAU/USD','SQQQ/USD') and value='high' then'bearish'
else 'not defined' end as scenario_market

,round( coalesce(PnL_client_1,0)- coalesce (etoro_pnl,0),2) as risk

from
(
select base_clients.*
,coalesce(dp.InstrumentType,base_clients.rank_instrument) as InstrumentType
,InstrumentDisplayName
,NOPHedged,etoro_pnl,Report_time_etoro_data
from
(
select 'credit' as scenario,'high' as value,* from risk.risk_output_rm_tables_stress_test_credit_instrument_high_value
union all
select 'credit' as scenario,'low' as value,* from risk.risk_output_rm_tables_stress_test_credit_instrument_low_value
union all
select 'diffusion' as scenario,'high' as value,* from risk.risk_output_rm_tables_stress_test_diffusion_instrument_high_value
union all
select 'diffusion' as scenario,'low' as value,* from risk.risk_output_rm_tables_stress_test_diffusion_instrument_low_value
union all
select 'credit' as scenario,'high' as value,* from risk.risk_output_rm_tables_stress_test_credit_others_high_value
union all
select 'credit' as scenario,'low' as value,* from risk.risk_output_rm_tables_stress_test_credit_others_low_value
union all
select 'diffusion' as scenario,'high' as value,* from risk.risk_output_rm_tables_stress_test_diffusion_others_high_value
union all
select 'diffusion' as scenario,'low' as value,* from risk.risk_output_rm_tables_stress_test_diffusion_others_low_value
)base_clients

left join 
(select Name, InstrumentType,InstrumentDisplayName from dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument) as dp
on base_clients.rank_instrument=dp.Name

left join
(

select value,rank_instrument,NOPHedged,etoro_pnl, Report_time as Report_time_etoro_data
from
(
select 'high' as value,* from risk.risk_output_rm_tables_stress_test_etoro_pnl_instrument_high_value
union all
select 'low' as value,* from risk.risk_output_rm_tables_stress_test_etoro_pnl_instrument_low_value
union all
select 'high' as value,* from risk.risk_output_rm_tables_stress_test_etoro_pnl_others_high_value
union all
select 'low' as value,* from risk.risk_output_rm_tables_stress_test_etoro_pnl_others_low_value
)etoro_pnl

)etoro_pnl1
on base_clients.rank_instrument=etoro_pnl1.rank_instrument and base_clients.value=etoro_pnl1.value

)final_base
)final
)

union all -- adding scenario market: all up and all down

(select scenario,value
,case when rank_instrument <> InstrumentType then rank_instrument else concat(rank_instrument,'_others') end as rank_instrument
,PnL_client_1 as pnl_client,scenario_1_shock_value as shock_value,Report_time as Report_time_clients
,InstrumentType
,coalesce (InstrumentDisplayName,concat(rank_instrument,'_others')) InstrumentDisplayName
,NOPHedged,etoro_pnl,Report_time_etoro_data,scenario_market,risk, NOP as NOP_clients
, coalesce (NOP-NOPHedged,0) as NOP_Unhedged
from
(

select final_base.*

, case when value ='high' and rank_instrument not in ('VIX.FUT/USD','XAU/USD','SQQQ/USD')  then 'all up'
when  value ='low' and rank_instrument  in ('VIX.FUT/USD','XAU/USD','SQQQ/USD')  then 'all up'
when  value ='low'  and rank_instrument not in ('VIX.FUT/USD','XAU/USD','SQQQ/USD') then 'all down'
when  value ='high' and rank_instrument  in ('VIX.FUT/USD','XAU/USD','SQQQ/USD')  then 'all down'
else 'not defined' end as scenario_market

,round( coalesce(PnL_client_1,0)- coalesce (etoro_pnl,0),2) as risk

from
(
select base_clients.*
,coalesce(dp.InstrumentType,base_clients.rank_instrument) as InstrumentType
,InstrumentDisplayName
,NOPHedged,etoro_pnl,Report_time_etoro_data
from
(
select 'credit' as scenario,'high' as value,* from risk.risk_output_rm_tables_stress_test_credit_instrument_high_value
union all
select 'credit' as scenario,'low' as value,* from risk.risk_output_rm_tables_stress_test_credit_instrument_low_value
union all
select 'diffusion' as scenario,'high' as value,* from risk.risk_output_rm_tables_stress_test_diffusion_instrument_high_value
union all
select 'diffusion' as scenario,'low' as value,* from risk.risk_output_rm_tables_stress_test_diffusion_instrument_low_value
union all
select 'credit' as scenario,'high' as value,* from risk.risk_output_rm_tables_stress_test_credit_others_high_value
union all
select 'credit' as scenario,'low' as value,* from risk.risk_output_rm_tables_stress_test_credit_others_low_value
union all
select 'diffusion' as scenario,'high' as value,* from risk.risk_output_rm_tables_stress_test_diffusion_others_high_value
union all
select 'diffusion' as scenario,'low' as value,* from risk.risk_output_rm_tables_stress_test_diffusion_others_low_value
)base_clients

left join 
(select Name, InstrumentType,InstrumentDisplayName from dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument) as dp
on base_clients.rank_instrument=dp.Name

left join
(

select value,rank_instrument,NOPHedged,etoro_pnl, Report_time as Report_time_etoro_data
from
(
select 'high' as value,* from risk.risk_output_rm_tables_stress_test_etoro_pnl_instrument_high_value
union all
select 'low' as value,* from risk.risk_output_rm_tables_stress_test_etoro_pnl_instrument_low_value
union all
select 'high' as value,* from risk.risk_output_rm_tables_stress_test_etoro_pnl_others_high_value
union all
select 'low' as value,* from risk.risk_output_rm_tables_stress_test_etoro_pnl_others_low_value
)etoro_pnl

)etoro_pnl1
on base_clients.rank_instrument=etoro_pnl1.rank_instrument and base_clients.value=etoro_pnl1.value

)final_base
)final
)