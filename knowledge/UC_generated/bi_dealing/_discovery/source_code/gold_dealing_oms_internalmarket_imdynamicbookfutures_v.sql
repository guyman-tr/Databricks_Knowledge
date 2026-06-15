-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_dealing.gold_dealing_oms_internalmarket_imdynamicbookfutures_v
-- Captured: 2026-05-19T12:46:23Z
-- ==========================================================================

with parameters as
(select * 
from 
main.bi_dealing.gold_dealing_oms_internalmarket_parameters
), valid_parameters --valid instruments are ones where the parameters table contain an OMS account as well as an eToro account
(
select InstrumentID, count(DISTINCT AccountType) count_sources
from parameters
where AccountType in ("oms", "etoro")
group by InstrumentID
having count_sources = 2
), valid_instruments
as
(
select aa.* from parameters aa
join valid_parameters bb using (InstrumentID)
),
oms as (
select
mp.InstrumentID, 
la.AccountType,
(Ask+Bid)/2 as Mid_o
from main.dealing.bronze_dealingstreaming_marketrates_dealing_market_feed_rates mp
join  valid_instruments la
on 
mp.LiquidityAccountID = la.LiquidityAccountID and 
mp.InstrumentID = la.InstrumentID and 
mp.receivedtime between date_add(MINUTE, -la.window_size_minutes, current_timestamp()) and current_timestamp() 
where 
mp.etr_ymdh between concat(current_date(), '-', HOUR(date_add(MINUTE, -60, current_timestamp()))) -- CAPPED aT 60 MINUTE LOOKBACK
and concat(current_date(), '-', HOUR(current_timestamp()))
) , pivoted 
as
(
SELECT * FROM (
   SELECT InstrumentID, AccountType, Mid_o FROM oms
 ) PIVOT (
   avg(Mid_o)
   FOR AccountType IN ("oms", "etoro")
 )
), final
as
(
select InstrumentID, 
cast ((aa.etoro - aa.oms)*(10 ^ di.Precision) as int ) Mid2MidDiff_Tick, current_timestamp() as UpdateTime
from pivoted aa
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di  USING (InstrumentID)
) --THE CODE BELOW IS ALL ORIGINAL CODE
SELECT InstrumentID
,'IMDynamicBook' as Model
,'askLegs' as ModelParameter
, cast(10 as string)  AS Value 
,UpdateTime
,1 as ModelVersion
,'/api/db/table/Automaton' as URL
,'askLegs' as OmsParam
,date(UpdateTime) etr_ymd
FROM final
union all
SELECT InstrumentID
,'IMDynamicBook' as Model
,'bidLegs' as ModelParameter
,cast( 10 as string)AS Value 
,UpdateTime
,1 as ModelVersion
,'/api/db/table/Automaton' as URL
,'bidLegs' as OmsParam
,date(UpdateTime) etr_ymd
FROM final
union all
SELECT InstrumentID
,'IMDynamicBook' as Model
,'depthReplication.nbLimits' as ModelParameter
,cast(10 as string) AS Value 
,UpdateTime
,1 as ModelVersion
,'/api/db/table/Automaton' as URL
,'depthReplication.nbLimits' as OmsParam
,date(UpdateTime) etr_ymd
FROM final
union all
SELECT InstrumentID
,'IMDynamicBook' as Model
,'depthReplication.period' as ModelParameter
,cast(300 as string)AS Value 
,UpdateTime
,1 as ModelVersion
,'/api/db/table/Automaton' as URL
,'depthReplication.period' as OmsParam
,date(UpdateTime) etr_ymd
FROM final
union all
SELECT InstrumentID
,'IMDynamicBook' as Model
,'depthReplication.bidPriceOffset' as ModelParameter
,cast(transform(sequence(1, 10), x ->-cast(Mid2MidDiff_Tick as int) )as string) AS Value 
,UpdateTime
,1 as ModelVersion
,'/api/db/table/Automaton' URL
,'depthReplication.bidPriceOffset' as OmsParam
,date(UpdateTime) etr_ymd
FROM final
union all 
SELECT InstrumentID
,'IMDynamicBook' as Model
,'depthReplication.askPriceOffset' as ModelParameter
,cast(transform(sequence(1, 10), x ->cast(Mid2MidDiff_Tick as int) )as string)AS Value 
,UpdateTime
,1 as ModelVersion
,'/api/db/table/Automaton' as URL
,'depthReplication.askPriceOffset' as OmsParam
,date(UpdateTime) etr_ymd
FROM final
union all 
SELECT InstrumentID
,'IMDynamicBook' as Model
,'depthReplication.bidQtyRatioInPct' as ModelParameter
,cast(transform(sequence(1, 10), x -> 100)as string) AS Value 
,UpdateTime
,1 as ModelVersion
,'/api/db/table/Automaton' as URL
,'depthReplication.bidQtyRatioInPct' as OmsParam
,date(UpdateTime) etr_ymd
FROM final
union all 
SELECT InstrumentID
,'IMDynamicBook' as Model
,'depthReplication.askQtyRatioInPct'  as ModelParameter
,cast(transform(sequence(1, 10), x ->100 )as string)AS Value 
,UpdateTime
,1 as ModelVersion
,'/api/db/table/Automaton' as URL
,'depthReplication.askQtyRatioInPct' as OmsParam
,date(UpdateTime) etr_ymd
FROM final
