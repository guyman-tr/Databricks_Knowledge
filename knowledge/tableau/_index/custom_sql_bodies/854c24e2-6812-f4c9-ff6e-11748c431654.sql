select
case when ind_alert_base_max=1 and current_day_week=6 and  current_hour_gmt*1E2 + current_minute_gmt  between 600 and 2259 then 1 else 0 end as ind_alert
from
(
select final8.ind_alert_base_max
,DAYOFWEEK(CURRENT_DATE) as current_day_week --6 is Friday 
, hour(current_timestamp) as  current_hour_gmt
,minute(current_timestamp) as  current_minute_gmt
,current_timestamp as current_time_gmt

from
(

select max(ind_alert_base_) as ind_alert_base_max
from
(
(select 
InstrumentID_rpt,rank_instrument_rpt,InstrumentType_dash,NOP
, `RiskAppetite fear 99.5` as `RiskAppetite fear 99.5_` 
,`RiskAppetite fear 100`as `RiskAppetite fear 100_`
,`upside fear 99.5_perc`as `upside fear 99.5_perc_`
,`downside fear 99.5_perc`as `downside fear 99.5_perc_`
,`upside fear 100_perc`as `upside fear 100_perc_`
,`downside fear 100_perc`as `downside fear 100_perc_`
,`hc credit upside fear 99.5`as `hc credit upside fear 99.5_`
,`hc credit downside fear 99.5`as `hc credit downside fear 99.5_`
,`hc credit upside fear 100`as `hc credit upside fear 100_`
,`hc credit downside fear 100`as `hc credit downside fear 100_`
,NOP_Hedged
,`status upside fear 99.5`as `status upside fear 99.5_`
,`USD option pnl upside fear 99.5`as `USD option pnl upside fear 99.5_`
,`status downside fear 99.5`as `status downside fear 99.5_`
,`USD option pnl downside fear 99.5`as `USD option pnl downside fear 99.5_`
,`status upside fear 100`as `status upside fear 100_`
,`USD option pnl upside fear 100`as `USD option pnl upside fear 100_`
,`status downside fear 100`as `status downside fear 100_`
,`USD option pnl downside fear 100`as `USD option pnl downside fear 100_`
,`ind_alert_base`as `ind_alert_base_`


from
(
select final3.*
,case when  `status upside fear 99.5`= 'BREACH' and InstrumentID in (17,18,19,22)  then 1
when `status downside fear 99.5` = 'BREACH' and InstrumentID in (17,18,19,22)  then 1
when `status upside fear 100` = 'BREACH' and InstrumentID in (17,18,19,22)  then 1
when `status downside fear 100` = 'BREACH' and InstrumentID in (17,18,19,22)  then 1
else 0 end as ind_alert_base

, InstrumentID as InstrumentID_rpt
, rank_instrument as rank_instrument_rpt
from
(
select final2.*
,case when `hc credit upside fear 99.5` > `RiskAppetite fear 99.5` then 'BREACH'
when `hc credit upside fear 99.5` <= `RiskAppetite fear 99.5` then 'ok' end as `status upside fear 99.5`

,case when `hc credit upside fear 99.5` > `RiskAppetite fear 99.5` then `hc credit upside fear 99.5` - `RiskAppetite fear 99.5`
when `hc credit upside fear 99.5` <= `RiskAppetite fear 99.5` then 0 end as `USD option pnl upside fear 99.5`

,case when `hc credit downside fear 99.5` > `RiskAppetite fear 99.5` then 'BREACH'
when `hc credit downside fear 99.5` <= `RiskAppetite fear 99.5` then 'ok' end as `status downside fear 99.5`

,case when `hc credit downside fear 99.5` > `RiskAppetite fear 99.5` then `hc credit downside fear 99.5` - `RiskAppetite fear 99.5`
when `hc credit downside fear 99.5` <= `RiskAppetite fear 99.5` then 0 end as `USD option pnl downside fear 99.5`

,case when `hc credit upside fear 100` > `RiskAppetite fear 100` then 'BREACH'
when `hc credit upside fear 100` <= `RiskAppetite fear 100` then 'ok' end as `status upside fear 100`

,case when `hc credit upside fear 100` > `RiskAppetite fear 100` then `hc credit upside fear 100` - `RiskAppetite fear 100`
when `hc credit upside fear 100` <= `RiskAppetite fear 100` then 0 end as `USD option pnl upside fear 100`

,case when `hc credit downside fear 100` > `RiskAppetite fear 100` then 'BREACH'
when `hc credit downside fear 100` <= `RiskAppetite fear 100` then 'ok' end as `status downside fear 100`

,case when `hc credit downside fear 100` > `RiskAppetite fear 100` then `hc credit downside fear 100` - `RiskAppetite fear 100`
when `hc credit downside fear 100` <= `RiskAppetite fear 100` then 0 end as `USD option pnl downside fear 100`

,nop.NOP
,NOP_Hedged

from 
(
select scenario, rank_instrument, InstrumentID, InstrumentDisplayName_dash,InstrumentType_dash
,Avg_Zero_week,Avg_Comm_week,Appetite_Risk
,Appetite_Risk as `RiskAppetite fear 99.5`
,Appetite_Risk*2 as `RiskAppetite fear 100`
,case when InstrumentID = 17 then 0.07
 when InstrumentID = 18 then 0.02
 when InstrumentID = 19 then 0.03
 when InstrumentID = 22 then 0.07
 when InstrumentID = 27 then 0.01
 when InstrumentID = 28 then 0.01
 when InstrumentID = 29 then 0.01
 when InstrumentID = 30 then 0.02
 when InstrumentID = 31 then 0.02
 when InstrumentID = 32 then 0.02
end as `upside fear 99.5_perc` ---add group

,case when InstrumentID = 17 then -0.08
 when InstrumentID = 18 then -0.01
 when InstrumentID = 19 then -0.01
 when InstrumentID = 22 then -0.08
 when InstrumentID = 27 then -0.04
 when InstrumentID = 28 then -0.03
 when InstrumentID = 29 then -0.03
 when InstrumentID = 30 then -0.06
 when InstrumentID = 31 then -0.04
 when InstrumentID = 32 then -0.04
end as `downside fear 99.5_perc` ---add group

,case when InstrumentID in (17) then hc_7
 when InstrumentID = 18 then hc_2
 when InstrumentID = 19 then hc_3
 when InstrumentID = 22 then hc_7
 when InstrumentID = 27 then hc_1
 when InstrumentID = 28 then hc_1
 when InstrumentID = 29 then hc_1
 when InstrumentID = 30 then hc_2
 when InstrumentID = 31 then hc_2
 when InstrumentID = 32 then hc_2
end as `hc credit upside fear 99.5` ---add group

,case when InstrumentID in (17) then hc_24
 when InstrumentID = 18 then hc_17
 when InstrumentID = 19 then hc_17
 when InstrumentID = 22 then hc_24
 when InstrumentID = 27 then hc_20
 when InstrumentID = 28 then hc_19
 when InstrumentID = 29 then hc_19
 when InstrumentID = 30 then hc_22
 when InstrumentID = 31 then hc_20
 when InstrumentID = 32 then hc_20 
end as `hc credit downside fear 99.5` ---add group


,case when InstrumentID = 17 then 0.09
 when InstrumentID = 18 then 0.03
 when InstrumentID = 19 then 0.06
 when InstrumentID = 22 then 0.08
 when InstrumentID = 27 then 0.02
 when InstrumentID = 28 then 0.02
 when InstrumentID = 29 then 0.02
 when InstrumentID = 30 then 0.03
 when InstrumentID = 31 then 0.04
 when InstrumentID = 32 then 0.03
 end as `upside fear 100_perc` ---add group

,case when InstrumentID = 17 then -0.10
 when InstrumentID = 18 then -0.02
 when InstrumentID = 19 then -0.02
 when InstrumentID = 22 then -0.15
 when InstrumentID = 27 then -0.05
 when InstrumentID = 28 then -0.05
 when InstrumentID = 29 then -0.05
 when InstrumentID = 30 then -0.09
 when InstrumentID = 31 then -0.06
 when InstrumentID = 32 then -0.07
 end as `downside fear 100_perc` ---add group

,case when InstrumentID =17  then hc_9
 when InstrumentID = 18 then hc_3
 when InstrumentID = 19 then hc_6
 when InstrumentID = 22 then hc_8
 when InstrumentID = 27 then hc_2
 when InstrumentID = 28 then hc_2
 when InstrumentID = 29 then hc_2
 when InstrumentID = 30 then hc_3
 when InstrumentID = 31 then hc_4
 when InstrumentID = 32 then hc_3
 end as `hc credit upside fear 100` ---add group

,case when InstrumentID =17 then hc_26
 when InstrumentID = 18 then hc_18
 when InstrumentID = 19 then hc_18
 when InstrumentID = 22 then hc_27
 when InstrumentID = 27 then hc_21
 when InstrumentID = 28 then hc_21
 when InstrumentID = 29 then hc_21
 when InstrumentID = 30 then hc_25
 when InstrumentID = 31 then hc_22
 when InstrumentID = 32 then hc_23
 end as `hc credit downside fear 100` ---add group

,NOP_Hedged

from
(

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
,0 as hc_0
--,app.Avg_Zero_week,app.Avg_Comm_week,app.Appetite_Risk

from
(
select base.*, inst.InstrumentID,inst.InstrumentType, coalesce(inst.InstrumentDisplayName,base.rank_instrument) as InstrumentDisplayName_dash
from
(
select hc.*
,coalesce(PnL_client_1,0)-coalesce(PnL_etoro_1,0) as hc_1
,coalesce(PnL_client_2,0)-coalesce(PnL_etoro_2,0) as hc_2
,coalesce(PnL_client_3,0)-coalesce(PnL_etoro_3,0) as hc_3
,coalesce(PnL_client_4,0)-coalesce(PnL_etoro_4,0) as hc_4
,coalesce(PnL_client_5,0)-coalesce(PnL_etoro_5,0) as hc_5
,coalesce(PnL_client_6,0)-coalesce(PnL_etoro_6,0) as hc_6
,coalesce(PnL_client_7,0)-coalesce(PnL_etoro_7,0) as hc_7
,coalesce(PnL_client_8,0)-coalesce(PnL_etoro_8,0) as hc_8
,coalesce(PnL_client_9,0)-coalesce(PnL_etoro_9,0) as hc_9
,coalesce(PnL_client_10,0)-coalesce(PnL_etoro_10,0) as hc_10
,coalesce(PnL_client_11,0)-coalesce(PnL_etoro_11,0) as hc_11
,coalesce(PnL_client_12,0)-coalesce(PnL_etoro_12,0) as hc_12
,coalesce(PnL_client_13,0)-coalesce(PnL_etoro_13,0) as hc_13
,coalesce(PnL_client_14,0)-coalesce(PnL_etoro_14,0) as hc_14
,coalesce(PnL_client_15,0)-coalesce(PnL_etoro_15,0) as hc_15
,coalesce(PnL_client_16,0)-coalesce(PnL_etoro_16,0) as hc_16
,coalesce(PnL_client_17,0)-coalesce(PnL_etoro_17,0) as hc_17
,coalesce(PnL_client_18,0)-coalesce(PnL_etoro_18,0) as hc_18
,coalesce(PnL_client_19,0)-coalesce(PnL_etoro_19,0) as hc_19
,coalesce(PnL_client_20,0)-coalesce(PnL_etoro_20,0) as hc_20
,coalesce(PnL_client_21,0)-coalesce(PnL_etoro_21,0) as hc_21
,coalesce(PnL_client_22,0)-coalesce(PnL_etoro_22,0) as hc_22
,coalesce(PnL_client_23,0)-coalesce(PnL_etoro_23,0) as hc_23
,coalesce(PnL_client_24,0)-coalesce(PnL_etoro_24,0) as hc_24
,coalesce(PnL_client_25,0)-coalesce(PnL_etoro_25,0) as hc_25
,coalesce(PnL_client_26,0)-coalesce(PnL_etoro_26,0) as hc_26
,coalesce(PnL_client_27,0)-coalesce(PnL_etoro_27,0) as hc_27
,coalesce(PnL_client_28,0)-coalesce(PnL_etoro_28,0) as hc_28
,coalesce(PnL_client_29,0)-coalesce(PnL_etoro_29,0) as hc_29
,coalesce(PnL_client_30,0)-coalesce(PnL_etoro_30,0) as hc_30
,coalesce(PnL_client_31,0)-coalesce(PnL_etoro_31,0) as hc_31
,coalesce(PnL_client_32,0)-coalesce(PnL_etoro_32,0) as hc_32
,NOP_Hedged
from
(

select clients1.*,PnL_etoro_1,PnL_etoro_2,PnL_etoro_3,PnL_etoro_4,PnL_etoro_5,PnL_etoro_6,PnL_etoro_7,PnL_etoro_8,PnL_etoro_9,PnL_etoro_10
,PnL_etoro_11,PnL_etoro_12,PnL_etoro_13,PnL_etoro_14,PnL_etoro_15,PnL_etoro_16,PnL_etoro_17,PnL_etoro_18,PnL_etoro_19,PnL_etoro_20,PnL_etoro_21
,PnL_etoro_22,PnL_etoro_23,PnL_etoro_24,PnL_etoro_25,PnL_etoro_26,PnL_etoro_27,PnL_etoro_28,PnL_etoro_29,PnL_etoro_30,PnL_etoro_31,PnL_etoro_32
,NOP_Hedged
from
(
select clients.scenario,clients.rank_instrument,sum(clients.PnL_client_1)PnL_client_1,sum(clients.PnL_client_2)PnL_client_2,sum(clients.PnL_client_3)PnL_client_3
,sum(clients.PnL_client_4)PnL_client_4,sum(clients.PnL_client_5)PnL_client_5,sum(clients.PnL_client_6)PnL_client_6,sum(clients.PnL_client_7)PnL_client_7
,sum(clients.PnL_client_8)PnL_client_8,sum(clients.PnL_client_9)PnL_client_9,sum(clients.PnL_client_10)PnL_client_10,sum(clients.PnL_client_11)PnL_client_11
,sum(clients.PnL_client_12)PnL_client_12,sum(clients.PnL_client_13)PnL_client_13,sum(clients.PnL_client_14)PnL_client_14,sum(clients.PnL_client_15)PnL_client_15
,sum(clients.PnL_client_16)PnL_client_16,sum(clients.PnL_client_17)PnL_client_17,sum(clients.PnL_client_18)PnL_client_18,sum(clients.PnL_client_19)PnL_client_19
,sum(clients.PnL_client_20)PnL_client_20,sum(clients.PnL_client_21)PnL_client_21,sum(clients.PnL_client_22)PnL_client_22,sum(clients.PnL_client_23)PnL_client_23
,sum(clients.PnL_client_24)PnL_client_24,sum(clients.PnL_client_25)PnL_client_25,sum(clients.PnL_client_26)PnL_client_26,sum(clients.PnL_client_27)PnL_client_27
,sum(clients.PnL_client_28)PnL_client_28,sum(clients.PnL_client_29)PnL_client_29,sum(clients.PnL_client_30)PnL_client_30,sum(clients.PnL_client_31)PnL_client_31
,sum(clients.PnL_client_32)PnL_client_32
from

(
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID,  'diffusion' as scenario, 'long' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_diffusion_client_pnl_cfd_instruments_2_long_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID,'diffusion' as scenario, 'short' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_diffusion_client_pnl_cfd_instruments_2_short_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID, 'diffusion' as scenario, 'long' as direction,'real' as cfd_real from risk.risk_output_rm_tables_diffusion_client_pnl_real_instruments_2_long_pnl
union all
--select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID,'diffusion' as scenario, 'short' as direction,'real' as cfd_real from risk.risk_output_rm_tables_diffusion_client_pnl_real_instruments_2_short_pnl
--union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID, 'credit' as scenario, 'long' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_cfd_instruments_2_long_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID,'credit' as scenario, 'short' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_cfd_instruments_2_short_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID, 'credit' as scenario, 'long' as direction,'real' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_real_instruments_2_long_pnl
--union all
--select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID,'credit' as scenario, 'short' as direction,'real' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_real_instruments_2_short_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID, 'credit' as scenario, 'long' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_cfd_others_2_long_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID, 'credit' as scenario, 'short' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_cfd_others_2_short_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID, 'credit' as scenario, 'long' as direction,'real' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_real_others_2_long_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID, 'diffusion' as scenario, 'long' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_diffusion_client_pnl_cfd_others_2_long_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID, 'diffusion' as scenario, 'short' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_diffusion_client_pnl_cfd_others_2_short_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID, 'diffusion' as scenario, 'long' as direction,'real' as cfd_real from risk.risk_output_rm_tables_diffusion_client_pnl_real_others_2_long_pnl
)clients
group by scenario,rank_instrument
)clients1
left join
(
select rank_instrument, sum(PnL_etoro_1)PnL_etoro_1, sum(PnL_etoro_2)PnL_etoro_2,sum(PnL_etoro_3)PnL_etoro_3,sum(PnL_etoro_4)PnL_etoro_4,sum(PnL_etoro_5)PnL_etoro_5,
sum(PnL_etoro_6)PnL_etoro_6,sum(PnL_etoro_7)PnL_etoro_7,sum(PnL_etoro_8)PnL_etoro_8,sum(PnL_etoro_9)PnL_etoro_9,sum(PnL_etoro_10)PnL_etoro_10,sum(PnL_etoro_11)PnL_etoro_11
,sum(PnL_etoro_12)PnL_etoro_12,sum(PnL_etoro_13)PnL_etoro_13,sum(PnL_etoro_14)PnL_etoro_14,sum(PnL_etoro_15)PnL_etoro_15,sum(PnL_etoro_16)PnL_etoro_16,sum(PnL_etoro_17)PnL_etoro_17
,sum(PnL_etoro_18)PnL_etoro_18,sum(PnL_etoro_19)PnL_etoro_19,sum(PnL_etoro_20)PnL_etoro_20,sum(PnL_etoro_21)PnL_etoro_21,sum(PnL_etoro_22)PnL_etoro_22,sum(PnL_etoro_23)PnL_etoro_23
,sum(PnL_etoro_24)PnL_etoro_24,sum(PnL_etoro_25)PnL_etoro_25,sum(PnL_etoro_26)PnL_etoro_26,sum(PnL_etoro_27)PnL_etoro_27,sum(PnL_etoro_28)PnL_etoro_28,sum(PnL_etoro_29)PnL_etoro_29
,sum(PnL_etoro_30)PnL_etoro_30,sum(PnL_etoro_31)PnL_etoro_31,sum(PnL_etoro_32)PnL_etoro_32
,sum(NOP_Hedged)NOP_Hedged
from
(
select rank_instrument,HedgeServerID,PnL_etoro_1,PnL_etoro_2,PnL_etoro_3,PnL_etoro_4,PnL_etoro_5,PnL_etoro_6,PnL_etoro_7,PnL_etoro_8,PnL_etoro_9,PnL_etoro_10,PnL_etoro_11,PnL_etoro_12,PnL_etoro_13,PnL_etoro_14,PnL_etoro_15,PnL_etoro_16,PnL_etoro_17,PnL_etoro_18,PnL_etoro_19,PnL_etoro_20,PnL_etoro_21,PnL_etoro_22,PnL_etoro_23,PnL_etoro_24,PnL_etoro_25,PnL_etoro_26,PnL_etoro_27,PnL_etoro_28,PnL_etoro_29,PnL_etoro_30,PnL_etoro_31,PnL_etoro_32,NOP_Hedged from risk.risk_output_rm_tables_diffusion_etoro_pnl_instruments_2_etoro_pnl_clients
 union all
select rank_instrument,HedgeServerID,PnL_etoro_1,PnL_etoro_2,PnL_etoro_3,PnL_etoro_4,PnL_etoro_5,PnL_etoro_6,PnL_etoro_7,PnL_etoro_8,PnL_etoro_9,PnL_etoro_10,PnL_etoro_11,PnL_etoro_12,PnL_etoro_13,PnL_etoro_14,PnL_etoro_15,PnL_etoro_16,PnL_etoro_17,PnL_etoro_18,PnL_etoro_19,PnL_etoro_20,PnL_etoro_21,PnL_etoro_22,PnL_etoro_23,PnL_etoro_24,PnL_etoro_25,PnL_etoro_26,PnL_etoro_27,PnL_etoro_28,PnL_etoro_29,PnL_etoro_30,PnL_etoro_31,PnL_etoro_32,NOP_Hedged from risk.risk_output_rm_tables_diffusion_etoro_pnl_others_2_etoro_pnl_clients
)etoro_temp
group by rank_instrument
)etoro
on clients1.rank_instrument=etoro.rank_instrument
)hc
)base
left join risk.risk_output_rm_tables_diffusion_main_instrument_details inst
on base.rank_instrument=inst.Name

)final_temp
)final_table
left join risk.risk_output_rm_tables_diffusion_risk_appetite app
on final_table.InstrumentDisplayName_dash=app.InstrumentDisplayName
)final1
where scenario='credit'
and
InstrumentID in (27,28,29,30,31,32,22,17,18,19) ---add group
)final2

left join

(--NOP
select rank_instrument, sum (NOP) NOP 
from

(
select rank_instrument,NOP_1,scenario_1_shock_value,NOP_2,scenario_2_shock_value,NOP_3,scenario_3_shock_value,NOP_4,scenario_4_shock_value,NOP_5,scenario_5_shock_value,NOP_6,scenario_6_shock_value,NOP_7,scenario_7_shock_value,NOP_8,scenario_8_shock_value,NOP_9,scenario_9_shock_value,NOP_10,scenario_10_shock_value,NOP_11,scenario_11_shock_value,NOP_12,scenario_12_shock_value,NOP_13,scenario_13_shock_value,NOP_14,scenario_14_shock_value,NOP_15,scenario_15_shock_value,NOP_16,scenario_16_shock_value,NOP_17,scenario_17_shock_value,NOP_18,scenario_18_shock_value,NOP_19,scenario_19_shock_value,NOP_20,scenario_20_shock_value,NOP_21,scenario_21_shock_value,NOP_22,scenario_22_shock_value,NOP_23,scenario_23_shock_value,NOP_24,scenario_24_shock_value,NOP_25,scenario_25_shock_value,NOP_26,scenario_26_shock_value,NOP_27,scenario_27_shock_value,NOP_28,scenario_28_shock_value,NOP_29,scenario_29_shock_value,NOP_30,scenario_30_shock_value,NOP_31,scenario_31_shock_value,NOP_32,scenario_32_shock_value,NOP,HedgeServerID, 'credit' as scenario, 'long' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_cfd_instruments_2_long_nop
union all
select rank_instrument,NOP_1,scenario_1_shock_value,NOP_2,scenario_2_shock_value,NOP_3,scenario_3_shock_value,NOP_4,scenario_4_shock_value,NOP_5,scenario_5_shock_value,NOP_6,scenario_6_shock_value,NOP_7,scenario_7_shock_value,NOP_8,scenario_8_shock_value,NOP_9,scenario_9_shock_value,NOP_10,scenario_10_shock_value,NOP_11,scenario_11_shock_value,NOP_12,scenario_12_shock_value,NOP_13,scenario_13_shock_value,NOP_14,scenario_14_shock_value,NOP_15,scenario_15_shock_value,NOP_16,scenario_16_shock_value,NOP_17,scenario_17_shock_value,NOP_18,scenario_18_shock_value,NOP_19,scenario_19_shock_value,NOP_20,scenario_20_shock_value,NOP_21,scenario_21_shock_value,NOP_22,scenario_22_shock_value,NOP_23,scenario_23_shock_value,NOP_24,scenario_24_shock_value,NOP_25,scenario_25_shock_value,NOP_26,scenario_26_shock_value,NOP_27,scenario_27_shock_value,NOP_28,scenario_28_shock_value,NOP_29,scenario_29_shock_value,NOP_30,scenario_30_shock_value,NOP_31,scenario_31_shock_value,NOP_32,scenario_32_shock_value,NOP,HedgeServerID,'credit' as scenario, 'short' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_cfd_instruments_2_short_nop
union all
select rank_instrument,NOP_1,scenario_1_shock_value,NOP_2,scenario_2_shock_value,NOP_3,scenario_3_shock_value,NOP_4,scenario_4_shock_value,NOP_5,scenario_5_shock_value,NOP_6,scenario_6_shock_value,NOP_7,scenario_7_shock_value,NOP_8,scenario_8_shock_value,NOP_9,scenario_9_shock_value,NOP_10,scenario_10_shock_value,NOP_11,scenario_11_shock_value,NOP_12,scenario_12_shock_value,NOP_13,scenario_13_shock_value,NOP_14,scenario_14_shock_value,NOP_15,scenario_15_shock_value,NOP_16,scenario_16_shock_value,NOP_17,scenario_17_shock_value,NOP_18,scenario_18_shock_value,NOP_19,scenario_19_shock_value,NOP_20,scenario_20_shock_value,NOP_21,scenario_21_shock_value,NOP_22,scenario_22_shock_value,NOP_23,scenario_23_shock_value,NOP_24,scenario_24_shock_value,NOP_25,scenario_25_shock_value,NOP_26,scenario_26_shock_value,NOP_27,scenario_27_shock_value,NOP_28,scenario_28_shock_value,NOP_29,scenario_29_shock_value,NOP_30,scenario_30_shock_value,NOP_31,scenario_31_shock_value,NOP_32,scenario_32_shock_value,NOP,HedgeServerID, 'credit' as scenario, 'long' as direction,'real' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_real_instruments_2_long_nop
--union all
--select rank_instrument,NOP_1,scenario_1_shock_value,NOP_2,scenario_2_shock_value,NOP_3,scenario_3_shock_value,NOP_4,scenario_4_shock_value,NOP_5,scenario_5_shock_value,NOP_6,scenario_6_shock_value,NOP_7,scenario_7_shock_value,NOP_8,scenario_8_shock_value,NOP_9,scenario_9_shock_value,NOP_10,scenario_10_shock_value,NOP_11,scenario_11_shock_value,NOP_12,scenario_12_shock_value,NOP_13,scenario_13_shock_value,NOP_14,scenario_14_shock_value,NOP_15,scenario_15_shock_value,NOP_16,scenario_16_shock_value,NOP_17,scenario_17_shock_value,NOP_18,scenario_18_shock_value,NOP_19,scenario_19_shock_value,NOP_20,scenario_20_shock_value,NOP_21,scenario_21_shock_value,NOP_22,scenario_22_shock_value,NOP_23,scenario_23_shock_value,NOP_24,scenario_24_shock_value,NOP_25,scenario_25_shock_value,NOP_26,scenario_26_shock_value,NOP_27,scenario_27_shock_value,NOP_28,scenario_28_shock_value,NOP_29,scenario_29_shock_value,NOP_30,scenario_30_shock_value,NOP_31,scenario_31_shock_value,NOP_32,scenario_32_shock_value,NOP,HedgeServerID,'credit' as scenario, 'short' as direction,'real' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_real_instruments_2_short_nop
union all
select rank_instrument,NOP_1,scenario_1_shock_value,NOP_2,scenario_2_shock_value,NOP_3,scenario_3_shock_value,NOP_4,scenario_4_shock_value,NOP_5,scenario_5_shock_value,NOP_6,scenario_6_shock_value,NOP_7,scenario_7_shock_value,NOP_8,scenario_8_shock_value,NOP_9,scenario_9_shock_value,NOP_10,scenario_10_shock_value,NOP_11,scenario_11_shock_value,NOP_12,scenario_12_shock_value,NOP_13,scenario_13_shock_value,NOP_14,scenario_14_shock_value,NOP_15,scenario_15_shock_value,NOP_16,scenario_16_shock_value,NOP_17,scenario_17_shock_value,NOP_18,scenario_18_shock_value,NOP_19,scenario_19_shock_value,NOP_20,scenario_20_shock_value,NOP_21,scenario_21_shock_value,NOP_22,scenario_22_shock_value,NOP_23,scenario_23_shock_value,NOP_24,scenario_24_shock_value,NOP_25,scenario_25_shock_value,NOP_26,scenario_26_shock_value,NOP_27,scenario_27_shock_value,NOP_28,scenario_28_shock_value,NOP_29,scenario_29_shock_value,NOP_30,scenario_30_shock_value,NOP_31,scenario_31_shock_value,NOP_32,scenario_32_shock_value,NOP,HedgeServerID, 'credit' as scenario, 'long' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_cfd_others_2_long_nop
union all
select rank_instrument,NOP_1,scenario_1_shock_value,NOP_2,scenario_2_shock_value,NOP_3,scenario_3_shock_value,NOP_4,scenario_4_shock_value,NOP_5,scenario_5_shock_value,NOP_6,scenario_6_shock_value,NOP_7,scenario_7_shock_value,NOP_8,scenario_8_shock_value,NOP_9,scenario_9_shock_value,NOP_10,scenario_10_shock_value,NOP_11,scenario_11_shock_value,NOP_12,scenario_12_shock_value,NOP_13,scenario_13_shock_value,NOP_14,scenario_14_shock_value,NOP_15,scenario_15_shock_value,NOP_16,scenario_16_shock_value,NOP_17,scenario_17_shock_value,NOP_18,scenario_18_shock_value,NOP_19,scenario_19_shock_value,NOP_20,scenario_20_shock_value,NOP_21,scenario_21_shock_value,NOP_22,scenario_22_shock_value,NOP_23,scenario_23_shock_value,NOP_24,scenario_24_shock_value,NOP_25,scenario_25_shock_value,NOP_26,scenario_26_shock_value,NOP_27,scenario_27_shock_value,NOP_28,scenario_28_shock_value,NOP_29,scenario_29_shock_value,NOP_30,scenario_30_shock_value,NOP_31,scenario_31_shock_value,NOP_32,scenario_32_shock_value,NOP,HedgeServerID, 'credit' as scenario, 'short' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_cfd_others_2_short_nop
union all
select rank_instrument,NOP_1,scenario_1_shock_value,NOP_2,scenario_2_shock_value,NOP_3,scenario_3_shock_value,NOP_4,scenario_4_shock_value,NOP_5,scenario_5_shock_value,NOP_6,scenario_6_shock_value,NOP_7,scenario_7_shock_value,NOP_8,scenario_8_shock_value,NOP_9,scenario_9_shock_value,NOP_10,scenario_10_shock_value,NOP_11,scenario_11_shock_value,NOP_12,scenario_12_shock_value,NOP_13,scenario_13_shock_value,NOP_14,scenario_14_shock_value,NOP_15,scenario_15_shock_value,NOP_16,scenario_16_shock_value,NOP_17,scenario_17_shock_value,NOP_18,scenario_18_shock_value,NOP_19,scenario_19_shock_value,NOP_20,scenario_20_shock_value,NOP_21,scenario_21_shock_value,NOP_22,scenario_22_shock_value,NOP_23,scenario_23_shock_value,NOP_24,scenario_24_shock_value,NOP_25,scenario_25_shock_value,NOP_26,scenario_26_shock_value,NOP_27,scenario_27_shock_value,NOP_28,scenario_28_shock_value,NOP_29,scenario_29_shock_value,NOP_30,scenario_30_shock_value,NOP_31,scenario_31_shock_value,NOP_32,scenario_32_shock_value,NOP,HedgeServerID, 'credit' as scenario, 'long' as direction,'real' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_real_others_2_long_nop
)
base
group by rank_instrument) nop
on final2.rank_instrument=nop.rank_instrument
)final3
)final4
)

UNION ALL
(select final6.*
,case when  `status upside fear 99.5_`= 'BREACH' and  rank_instrument_rpt='Indices_all' then 1
when `status downside fear 99.5_` = 'BREACH'and  rank_instrument_rpt='Indices_all' then 1
when `status upside fear 100_` = 'BREACH' and  rank_instrument_rpt='Indices_all' then 1
when `status downside fear 100_` = 'BREACH' and  rank_instrument_rpt='Indices_all' then 1
else 0 end as ind_alert_base_
from
(

select final5.*
,case when `hc credit upside fear 99.5_` > `RiskAppetite fear 99.5_` then 'BREACH'
when `hc credit upside fear 99.5_` <= `RiskAppetite fear 99.5_` then 'ok' end as `status upside fear 99.5_`

,case when `hc credit upside fear 99.5_` > `RiskAppetite fear 99.5_` then `hc credit upside fear 99.5_` - `RiskAppetite fear 99.5_`
when `hc credit upside fear 99.5_` <= `RiskAppetite fear 99.5_` then 0 end as `USD option pnl upside fear 99.5_`

,case when `hc credit downside fear 99.5_` > `RiskAppetite fear 99.5_` then 'BREACH'
when `hc credit downside fear 99.5_` <= `RiskAppetite fear 99.5_` then 'ok' end as `status downside fear 99.5_`

,case when `hc credit downside fear 99.5_` > `RiskAppetite fear 99.5_` then `hc credit downside fear 99.5_` - `RiskAppetite fear 99.5_`
when `hc credit downside fear 99.5_` <= `RiskAppetite fear 99.5_` then 0 end as `USD option pnl downside fear 99.5_`

,case when `hc credit upside fear 100_` > `RiskAppetite fear 100_` then 'BREACH'
when `hc credit upside fear 100_` <= `RiskAppetite fear 100_` then 'ok' end as `status upside fear 100_`

,case when `hc credit upside fear 100_` > `RiskAppetite fear 100_` then `hc credit upside fear 100_` - `RiskAppetite fear 100_`
when `hc credit upside fear 100_` <= `RiskAppetite fear 100_` then 0 end as `USD option pnl upside fear 100_`

,case when `hc credit downside fear 100_` > `RiskAppetite fear 100_` then 'BREACH'
when `hc credit downside fear 100_` <= `RiskAppetite fear 100_` then 'ok' end as `status downside fear 100_`

,case when `hc credit downside fear 100_` > `RiskAppetite fear 100_` then `hc credit downside fear 100_` - `RiskAppetite fear 100_`
when `hc credit downside fear 100_` <= `RiskAppetite fear 100_` then 0 end as `USD option pnl downside fear 100_`

from
(
select 
InstrumentID_rpt, rank_instrument_rpt, InstrumentType_dash, sum(NOP) as NOP, sum(`RiskAppetite fear 99.5`) as `RiskAppetite fear 99.5_` , sum(`RiskAppetite fear 100`) as `RiskAppetite fear 100_` 
,avg(`upside fear 99.5_perc`) as  `upside fear 99.5_perc_`,avg(`downside fear 99.5_perc`) as  `downside fear 99.5_perc_`,avg(`upside fear 100_perc`) as  `upside fear 100_perc_`,avg(`downside fear 100_perc`) as  `downside fear 100_perc_`
,sum(`hc credit upside fear 99.5`) as `hc credit upside fear 99.5_`,sum(`hc credit downside fear 99.5`) as `hc credit downside fear 99.5_`,sum(`hc credit upside fear 100`) as `hc credit upside fear 100_`,sum(`hc credit downside fear 100`) as `hc credit downside fear 100_`
,sum(NOP_Hedged)NOP_Hedged
from
(
select final3.*
,case when  `status upside fear 99.5`= 'BREACH' then 1
when `status downside fear 99.5` = 'BREACH' then 1
when `status upside fear 100` = 'BREACH' then 1
when `status downside fear 100` = 'BREACH' then 1
else 0 end as ind_alert_base
, 0 as InstrumentID_rpt
, case when InstrumentType_dash='Indices' then 'Indices_all'
when InstrumentType_dash='Commodities' then 'Commodities_all' 
else 'not defined' end as rank_instrument_rpt

from
(

select final2.*
,case when `hc credit upside fear 99.5` > `RiskAppetite fear 99.5` then 'BREACH'
when `hc credit upside fear 99.5` <= `RiskAppetite fear 99.5` then 'ok' end as `status upside fear 99.5`

,case when `hc credit upside fear 99.5` > `RiskAppetite fear 99.5` then `hc credit upside fear 99.5` - `RiskAppetite fear 99.5`
when `hc credit upside fear 99.5` <= `RiskAppetite fear 99.5` then 0 end as `USD option pnl upside fear 99.5`

,case when `hc credit downside fear 99.5` > `RiskAppetite fear 99.5` then 'BREACH'
when `hc credit downside fear 99.5` <= `RiskAppetite fear 99.5` then 'ok' end as `status downside fear 99.5`

,case when `hc credit downside fear 99.5` > `RiskAppetite fear 99.5` then `hc credit downside fear 99.5` - `RiskAppetite fear 99.5`
when `hc credit downside fear 99.5` <= `RiskAppetite fear 99.5` then 0 end as `USD option pnl downside fear 99.5`

,case when `hc credit upside fear 100` > `RiskAppetite fear 100` then 'BREACH'
when `hc credit upside fear 100` <= `RiskAppetite fear 100` then 'ok' end as `status upside fear 100`

,case when `hc credit upside fear 100` > `RiskAppetite fear 100` then `hc credit upside fear 100` - `RiskAppetite fear 100`
when `hc credit upside fear 100` <= `RiskAppetite fear 100` then 0 end as `USD option pnl upside fear 100`

,case when `hc credit downside fear 100` > `RiskAppetite fear 100` then 'BREACH'
when `hc credit downside fear 100` <= `RiskAppetite fear 100` then 'ok' end as `status downside fear 100`

,case when `hc credit downside fear 100` > `RiskAppetite fear 100` then `hc credit downside fear 100` - `RiskAppetite fear 100`
when `hc credit downside fear 100` <= `RiskAppetite fear 100` then 0 end as `USD option pnl downside fear 100`

,nop.NOP

from 
(

select scenario, rank_instrument, InstrumentID, InstrumentDisplayName_dash,InstrumentType_dash
,Avg_Zero_week,Avg_Comm_week,Appetite_Risk 
,Appetite_Risk as `RiskAppetite fear 99.5`
,Appetite_Risk*2 as `RiskAppetite fear 100`
,case when InstrumentType_dash = 'Indices' then 0.02
when InstrumentType_dash = 'Commodities' then 0.03  end as `upside fear 99.5_perc` ---add group


,case when InstrumentType_dash = 'Indices' then -0.05
when InstrumentType_dash = 'Commodities' then -0.03  end as `downside fear 99.5_perc` ---add group


,case when InstrumentType_dash = 'Indices' then hc_2
when InstrumentType_dash = 'Commodities' then hc_3  end as `hc credit upside fear 99.5` ---add group


,case when InstrumentType_dash = 'Indices' then hc_21
when InstrumentType_dash = 'Commodities' then hc_19  end as `hc credit downside fear 99.5` ---add group

,case when InstrumentType_dash = 'Indices' then 0.04
when InstrumentType_dash = 'Commodities' then 0.06  end as `upside fear 100_perc` ---add group

,case when InstrumentType_dash = 'Indices' then -0.06
when InstrumentType_dash = 'Commodities' then -0.06  end as `downside fear 100_perc` ---add group

,case when InstrumentType_dash = 'Indices' then hc_4
when InstrumentType_dash = 'Commodities' then hc_6  end as `hc credit upside fear 100` ---add group

,case when InstrumentType_dash = 'Indices' then hc_22
when InstrumentType_dash = 'Commodities' then hc_22  end as `hc credit downside fear 100` ---add group
,NOP_Hedged

from
(

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
,0 as hc_0
--,app.Avg_Zero_week,app.Avg_Comm_week,app.Appetite_Risk
,NOP_Hedged

from
(
select base.*, inst.InstrumentID,inst.InstrumentType, coalesce(inst.InstrumentDisplayName,base.rank_instrument) as InstrumentDisplayName_dash
from
(
select hc.*
,coalesce(PnL_client_1,0)-coalesce(PnL_etoro_1,0) as hc_1
,coalesce(PnL_client_2,0)-coalesce(PnL_etoro_2,0) as hc_2
,coalesce(PnL_client_3,0)-coalesce(PnL_etoro_3,0) as hc_3
,coalesce(PnL_client_4,0)-coalesce(PnL_etoro_4,0) as hc_4
,coalesce(PnL_client_5,0)-coalesce(PnL_etoro_5,0) as hc_5
,coalesce(PnL_client_6,0)-coalesce(PnL_etoro_6,0) as hc_6
,coalesce(PnL_client_7,0)-coalesce(PnL_etoro_7,0) as hc_7
,coalesce(PnL_client_8,0)-coalesce(PnL_etoro_8,0) as hc_8
,coalesce(PnL_client_9,0)-coalesce(PnL_etoro_9,0) as hc_9
,coalesce(PnL_client_10,0)-coalesce(PnL_etoro_10,0) as hc_10
,coalesce(PnL_client_11,0)-coalesce(PnL_etoro_11,0) as hc_11
,coalesce(PnL_client_12,0)-coalesce(PnL_etoro_12,0) as hc_12
,coalesce(PnL_client_13,0)-coalesce(PnL_etoro_13,0) as hc_13
,coalesce(PnL_client_14,0)-coalesce(PnL_etoro_14,0) as hc_14
,coalesce(PnL_client_15,0)-coalesce(PnL_etoro_15,0) as hc_15
,coalesce(PnL_client_16,0)-coalesce(PnL_etoro_16,0) as hc_16
,coalesce(PnL_client_17,0)-coalesce(PnL_etoro_17,0) as hc_17
,coalesce(PnL_client_18,0)-coalesce(PnL_etoro_18,0) as hc_18
,coalesce(PnL_client_19,0)-coalesce(PnL_etoro_19,0) as hc_19
,coalesce(PnL_client_20,0)-coalesce(PnL_etoro_20,0) as hc_20
,coalesce(PnL_client_21,0)-coalesce(PnL_etoro_21,0) as hc_21
,coalesce(PnL_client_22,0)-coalesce(PnL_etoro_22,0) as hc_22
,coalesce(PnL_client_23,0)-coalesce(PnL_etoro_23,0) as hc_23
,coalesce(PnL_client_24,0)-coalesce(PnL_etoro_24,0) as hc_24
,coalesce(PnL_client_25,0)-coalesce(PnL_etoro_25,0) as hc_25
,coalesce(PnL_client_26,0)-coalesce(PnL_etoro_26,0) as hc_26
,coalesce(PnL_client_27,0)-coalesce(PnL_etoro_27,0) as hc_27
,coalesce(PnL_client_28,0)-coalesce(PnL_etoro_28,0) as hc_28
,coalesce(PnL_client_29,0)-coalesce(PnL_etoro_29,0) as hc_29
,coalesce(PnL_client_30,0)-coalesce(PnL_etoro_30,0) as hc_30
,coalesce(PnL_client_31,0)-coalesce(PnL_etoro_31,0) as hc_31
,coalesce(PnL_client_32,0)-coalesce(PnL_etoro_32,0) as hc_32
,NOP_Hedged
from
(

select clients1.*,PnL_etoro_1,PnL_etoro_2,PnL_etoro_3,PnL_etoro_4,PnL_etoro_5,PnL_etoro_6,PnL_etoro_7,PnL_etoro_8,PnL_etoro_9,PnL_etoro_10
,PnL_etoro_11,PnL_etoro_12,PnL_etoro_13,PnL_etoro_14,PnL_etoro_15,PnL_etoro_16,PnL_etoro_17,PnL_etoro_18,PnL_etoro_19,PnL_etoro_20,PnL_etoro_21
,PnL_etoro_22,PnL_etoro_23,PnL_etoro_24,PnL_etoro_25,PnL_etoro_26,PnL_etoro_27,PnL_etoro_28,PnL_etoro_29,PnL_etoro_30,PnL_etoro_31,PnL_etoro_32
,NOP_Hedged
from
(
select clients.scenario,clients.rank_instrument,sum(clients.PnL_client_1)PnL_client_1,sum(clients.PnL_client_2)PnL_client_2,sum(clients.PnL_client_3)PnL_client_3
,sum(clients.PnL_client_4)PnL_client_4,sum(clients.PnL_client_5)PnL_client_5,sum(clients.PnL_client_6)PnL_client_6,sum(clients.PnL_client_7)PnL_client_7
,sum(clients.PnL_client_8)PnL_client_8,sum(clients.PnL_client_9)PnL_client_9,sum(clients.PnL_client_10)PnL_client_10,sum(clients.PnL_client_11)PnL_client_11
,sum(clients.PnL_client_12)PnL_client_12,sum(clients.PnL_client_13)PnL_client_13,sum(clients.PnL_client_14)PnL_client_14,sum(clients.PnL_client_15)PnL_client_15
,sum(clients.PnL_client_16)PnL_client_16,sum(clients.PnL_client_17)PnL_client_17,sum(clients.PnL_client_18)PnL_client_18,sum(clients.PnL_client_19)PnL_client_19
,sum(clients.PnL_client_20)PnL_client_20,sum(clients.PnL_client_21)PnL_client_21,sum(clients.PnL_client_22)PnL_client_22,sum(clients.PnL_client_23)PnL_client_23
,sum(clients.PnL_client_24)PnL_client_24,sum(clients.PnL_client_25)PnL_client_25,sum(clients.PnL_client_26)PnL_client_26,sum(clients.PnL_client_27)PnL_client_27
,sum(clients.PnL_client_28)PnL_client_28,sum(clients.PnL_client_29)PnL_client_29,sum(clients.PnL_client_30)PnL_client_30,sum(clients.PnL_client_31)PnL_client_31
,sum(clients.PnL_client_32)PnL_client_32
from

(
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID,  'diffusion' as scenario, 'long' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_diffusion_client_pnl_cfd_instruments_2_long_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID,'diffusion' as scenario, 'short' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_diffusion_client_pnl_cfd_instruments_2_short_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID, 'diffusion' as scenario, 'long' as direction,'real' as cfd_real from risk.risk_output_rm_tables_diffusion_client_pnl_real_instruments_2_long_pnl
union all
--select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID,'diffusion' as scenario, 'short' as direction,'real' as cfd_real from risk.risk_output_rm_tables_diffusion_client_pnl_real_instruments_2_short_pnl
--union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID, 'credit' as scenario, 'long' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_cfd_instruments_2_long_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID,'credit' as scenario, 'short' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_cfd_instruments_2_short_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID, 'credit' as scenario, 'long' as direction,'real' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_real_instruments_2_long_pnl
--union all
--select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID,'credit' as scenario, 'short' as direction,'real' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_real_instruments_2_short_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID, 'credit' as scenario, 'long' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_cfd_others_2_long_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID, 'credit' as scenario, 'short' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_cfd_others_2_short_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID, 'credit' as scenario, 'long' as direction,'real' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_real_others_2_long_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID, 'diffusion' as scenario, 'long' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_diffusion_client_pnl_cfd_others_2_long_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID, 'diffusion' as scenario, 'short' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_diffusion_client_pnl_cfd_others_2_short_pnl
union all
select rank_instrument,PnL_client_1,scenario_1_shock_value,PnL_client_2,scenario_2_shock_value,PnL_client_3,scenario_3_shock_value,PnL_client_4,scenario_4_shock_value,PnL_client_5,scenario_5_shock_value,PnL_client_6,scenario_6_shock_value,PnL_client_7,scenario_7_shock_value,PnL_client_8,scenario_8_shock_value,PnL_client_9,scenario_9_shock_value,PnL_client_10,scenario_10_shock_value,PnL_client_11,scenario_11_shock_value,PnL_client_12,scenario_12_shock_value,PnL_client_13,scenario_13_shock_value,PnL_client_14,scenario_14_shock_value,PnL_client_15,scenario_15_shock_value,PnL_client_16,scenario_16_shock_value,PnL_client_17,scenario_17_shock_value,PnL_client_18,scenario_18_shock_value,PnL_client_19,scenario_19_shock_value,PnL_client_20,scenario_20_shock_value,PnL_client_21,scenario_21_shock_value,PnL_client_22,scenario_22_shock_value,PnL_client_23,scenario_23_shock_value,PnL_client_24,scenario_24_shock_value,PnL_client_25,scenario_25_shock_value,PnL_client_26,scenario_26_shock_value,PnL_client_27,scenario_27_shock_value,PnL_client_28,scenario_28_shock_value,PnL_client_29,scenario_29_shock_value,PnL_client_30,scenario_30_shock_value,PnL_client_31,scenario_31_shock_value,PnL_client_32,scenario_32_shock_value,HedgeServerID, 'diffusion' as scenario, 'long' as direction,'real' as cfd_real from risk.risk_output_rm_tables_diffusion_client_pnl_real_others_2_long_pnl
)clients
group by scenario,rank_instrument
)clients1
left join
(
select rank_instrument, sum(PnL_etoro_1)PnL_etoro_1, sum(PnL_etoro_2)PnL_etoro_2,sum(PnL_etoro_3)PnL_etoro_3,sum(PnL_etoro_4)PnL_etoro_4,sum(PnL_etoro_5)PnL_etoro_5,
sum(PnL_etoro_6)PnL_etoro_6,sum(PnL_etoro_7)PnL_etoro_7,sum(PnL_etoro_8)PnL_etoro_8,sum(PnL_etoro_9)PnL_etoro_9,sum(PnL_etoro_10)PnL_etoro_10,sum(PnL_etoro_11)PnL_etoro_11
,sum(PnL_etoro_12)PnL_etoro_12,sum(PnL_etoro_13)PnL_etoro_13,sum(PnL_etoro_14)PnL_etoro_14,sum(PnL_etoro_15)PnL_etoro_15,sum(PnL_etoro_16)PnL_etoro_16,sum(PnL_etoro_17)PnL_etoro_17
,sum(PnL_etoro_18)PnL_etoro_18,sum(PnL_etoro_19)PnL_etoro_19,sum(PnL_etoro_20)PnL_etoro_20,sum(PnL_etoro_21)PnL_etoro_21,sum(PnL_etoro_22)PnL_etoro_22,sum(PnL_etoro_23)PnL_etoro_23
,sum(PnL_etoro_24)PnL_etoro_24,sum(PnL_etoro_25)PnL_etoro_25,sum(PnL_etoro_26)PnL_etoro_26,sum(PnL_etoro_27)PnL_etoro_27,sum(PnL_etoro_28)PnL_etoro_28,sum(PnL_etoro_29)PnL_etoro_29
,sum(PnL_etoro_30)PnL_etoro_30,sum(PnL_etoro_31)PnL_etoro_31,sum(PnL_etoro_32)PnL_etoro_32
,sum(NOP_Hedged)NOP_Hedged
from
(
select rank_instrument,HedgeServerID,PnL_etoro_1,PnL_etoro_2,PnL_etoro_3,PnL_etoro_4,PnL_etoro_5,PnL_etoro_6,PnL_etoro_7,PnL_etoro_8,PnL_etoro_9,PnL_etoro_10,PnL_etoro_11,PnL_etoro_12,PnL_etoro_13,PnL_etoro_14,PnL_etoro_15,PnL_etoro_16,PnL_etoro_17,PnL_etoro_18,PnL_etoro_19,PnL_etoro_20,PnL_etoro_21,PnL_etoro_22,PnL_etoro_23,PnL_etoro_24,PnL_etoro_25,PnL_etoro_26,PnL_etoro_27,PnL_etoro_28,PnL_etoro_29,PnL_etoro_30,PnL_etoro_31,PnL_etoro_32,NOP_Hedged from risk.risk_output_rm_tables_diffusion_etoro_pnl_instruments_2_etoro_pnl_clients
 union all
select rank_instrument,HedgeServerID,PnL_etoro_1,PnL_etoro_2,PnL_etoro_3,PnL_etoro_4,PnL_etoro_5,PnL_etoro_6,PnL_etoro_7,PnL_etoro_8,PnL_etoro_9,PnL_etoro_10,PnL_etoro_11,PnL_etoro_12,PnL_etoro_13,PnL_etoro_14,PnL_etoro_15,PnL_etoro_16,PnL_etoro_17,PnL_etoro_18,PnL_etoro_19,PnL_etoro_20,PnL_etoro_21,PnL_etoro_22,PnL_etoro_23,PnL_etoro_24,PnL_etoro_25,PnL_etoro_26,PnL_etoro_27,PnL_etoro_28,PnL_etoro_29,PnL_etoro_30,PnL_etoro_31,PnL_etoro_32,NOP_Hedged from risk.risk_output_rm_tables_diffusion_etoro_pnl_others_2_etoro_pnl_clients
)etoro_temp
group by rank_instrument
)etoro
on clients1.rank_instrument=etoro.rank_instrument
)hc
)base
left join risk.risk_output_rm_tables_diffusion_main_instrument_details inst
on base.rank_instrument=inst.Name

)final_temp
)final_table
left join risk.risk_output_rm_tables_diffusion_risk_appetite app
on final_table.InstrumentDisplayName_dash=app.InstrumentDisplayName
)final1
where scenario='credit'
and
InstrumentType_dash in ('Commodities','Indices') ---add group

)final2


left join

(--NOP
select rank_instrument, sum (NOP) NOP 
from

(
select rank_instrument,NOP_1,scenario_1_shock_value,NOP_2,scenario_2_shock_value,NOP_3,scenario_3_shock_value,NOP_4,scenario_4_shock_value,NOP_5,scenario_5_shock_value,NOP_6,scenario_6_shock_value,NOP_7,scenario_7_shock_value,NOP_8,scenario_8_shock_value,NOP_9,scenario_9_shock_value,NOP_10,scenario_10_shock_value,NOP_11,scenario_11_shock_value,NOP_12,scenario_12_shock_value,NOP_13,scenario_13_shock_value,NOP_14,scenario_14_shock_value,NOP_15,scenario_15_shock_value,NOP_16,scenario_16_shock_value,NOP_17,scenario_17_shock_value,NOP_18,scenario_18_shock_value,NOP_19,scenario_19_shock_value,NOP_20,scenario_20_shock_value,NOP_21,scenario_21_shock_value,NOP_22,scenario_22_shock_value,NOP_23,scenario_23_shock_value,NOP_24,scenario_24_shock_value,NOP_25,scenario_25_shock_value,NOP_26,scenario_26_shock_value,NOP_27,scenario_27_shock_value,NOP_28,scenario_28_shock_value,NOP_29,scenario_29_shock_value,NOP_30,scenario_30_shock_value,NOP_31,scenario_31_shock_value,NOP_32,scenario_32_shock_value,NOP,HedgeServerID, 'credit' as scenario, 'long' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_cfd_instruments_2_long_nop
union all
select rank_instrument,NOP_1,scenario_1_shock_value,NOP_2,scenario_2_shock_value,NOP_3,scenario_3_shock_value,NOP_4,scenario_4_shock_value,NOP_5,scenario_5_shock_value,NOP_6,scenario_6_shock_value,NOP_7,scenario_7_shock_value,NOP_8,scenario_8_shock_value,NOP_9,scenario_9_shock_value,NOP_10,scenario_10_shock_value,NOP_11,scenario_11_shock_value,NOP_12,scenario_12_shock_value,NOP_13,scenario_13_shock_value,NOP_14,scenario_14_shock_value,NOP_15,scenario_15_shock_value,NOP_16,scenario_16_shock_value,NOP_17,scenario_17_shock_value,NOP_18,scenario_18_shock_value,NOP_19,scenario_19_shock_value,NOP_20,scenario_20_shock_value,NOP_21,scenario_21_shock_value,NOP_22,scenario_22_shock_value,NOP_23,scenario_23_shock_value,NOP_24,scenario_24_shock_value,NOP_25,scenario_25_shock_value,NOP_26,scenario_26_shock_value,NOP_27,scenario_27_shock_value,NOP_28,scenario_28_shock_value,NOP_29,scenario_29_shock_value,NOP_30,scenario_30_shock_value,NOP_31,scenario_31_shock_value,NOP_32,scenario_32_shock_value,NOP,HedgeServerID,'credit' as scenario, 'short' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_cfd_instruments_2_short_nop
union all
select rank_instrument,NOP_1,scenario_1_shock_value,NOP_2,scenario_2_shock_value,NOP_3,scenario_3_shock_value,NOP_4,scenario_4_shock_value,NOP_5,scenario_5_shock_value,NOP_6,scenario_6_shock_value,NOP_7,scenario_7_shock_value,NOP_8,scenario_8_shock_value,NOP_9,scenario_9_shock_value,NOP_10,scenario_10_shock_value,NOP_11,scenario_11_shock_value,NOP_12,scenario_12_shock_value,NOP_13,scenario_13_shock_value,NOP_14,scenario_14_shock_value,NOP_15,scenario_15_shock_value,NOP_16,scenario_16_shock_value,NOP_17,scenario_17_shock_value,NOP_18,scenario_18_shock_value,NOP_19,scenario_19_shock_value,NOP_20,scenario_20_shock_value,NOP_21,scenario_21_shock_value,NOP_22,scenario_22_shock_value,NOP_23,scenario_23_shock_value,NOP_24,scenario_24_shock_value,NOP_25,scenario_25_shock_value,NOP_26,scenario_26_shock_value,NOP_27,scenario_27_shock_value,NOP_28,scenario_28_shock_value,NOP_29,scenario_29_shock_value,NOP_30,scenario_30_shock_value,NOP_31,scenario_31_shock_value,NOP_32,scenario_32_shock_value,NOP,HedgeServerID, 'credit' as scenario, 'long' as direction,'real' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_real_instruments_2_long_nop
--union all
--select rank_instrument,NOP_1,scenario_1_shock_value,NOP_2,scenario_2_shock_value,NOP_3,scenario_3_shock_value,NOP_4,scenario_4_shock_value,NOP_5,scenario_5_shock_value,NOP_6,scenario_6_shock_value,NOP_7,scenario_7_shock_value,NOP_8,scenario_8_shock_value,NOP_9,scenario_9_shock_value,NOP_10,scenario_10_shock_value,NOP_11,scenario_11_shock_value,NOP_12,scenario_12_shock_value,NOP_13,scenario_13_shock_value,NOP_14,scenario_14_shock_value,NOP_15,scenario_15_shock_value,NOP_16,scenario_16_shock_value,NOP_17,scenario_17_shock_value,NOP_18,scenario_18_shock_value,NOP_19,scenario_19_shock_value,NOP_20,scenario_20_shock_value,NOP_21,scenario_21_shock_value,NOP_22,scenario_22_shock_value,NOP_23,scenario_23_shock_value,NOP_24,scenario_24_shock_value,NOP_25,scenario_25_shock_value,NOP_26,scenario_26_shock_value,NOP_27,scenario_27_shock_value,NOP_28,scenario_28_shock_value,NOP_29,scenario_29_shock_value,NOP_30,scenario_30_shock_value,NOP_31,scenario_31_shock_value,NOP_32,scenario_32_shock_value,NOP,HedgeServerID,'credit' as scenario, 'short' as direction,'real' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_real_instruments_2_short_nop
union all
select rank_instrument,NOP_1,scenario_1_shock_value,NOP_2,scenario_2_shock_value,NOP_3,scenario_3_shock_value,NOP_4,scenario_4_shock_value,NOP_5,scenario_5_shock_value,NOP_6,scenario_6_shock_value,NOP_7,scenario_7_shock_value,NOP_8,scenario_8_shock_value,NOP_9,scenario_9_shock_value,NOP_10,scenario_10_shock_value,NOP_11,scenario_11_shock_value,NOP_12,scenario_12_shock_value,NOP_13,scenario_13_shock_value,NOP_14,scenario_14_shock_value,NOP_15,scenario_15_shock_value,NOP_16,scenario_16_shock_value,NOP_17,scenario_17_shock_value,NOP_18,scenario_18_shock_value,NOP_19,scenario_19_shock_value,NOP_20,scenario_20_shock_value,NOP_21,scenario_21_shock_value,NOP_22,scenario_22_shock_value,NOP_23,scenario_23_shock_value,NOP_24,scenario_24_shock_value,NOP_25,scenario_25_shock_value,NOP_26,scenario_26_shock_value,NOP_27,scenario_27_shock_value,NOP_28,scenario_28_shock_value,NOP_29,scenario_29_shock_value,NOP_30,scenario_30_shock_value,NOP_31,scenario_31_shock_value,NOP_32,scenario_32_shock_value,NOP,HedgeServerID, 'credit' as scenario, 'long' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_cfd_others_2_long_nop
union all
select rank_instrument,NOP_1,scenario_1_shock_value,NOP_2,scenario_2_shock_value,NOP_3,scenario_3_shock_value,NOP_4,scenario_4_shock_value,NOP_5,scenario_5_shock_value,NOP_6,scenario_6_shock_value,NOP_7,scenario_7_shock_value,NOP_8,scenario_8_shock_value,NOP_9,scenario_9_shock_value,NOP_10,scenario_10_shock_value,NOP_11,scenario_11_shock_value,NOP_12,scenario_12_shock_value,NOP_13,scenario_13_shock_value,NOP_14,scenario_14_shock_value,NOP_15,scenario_15_shock_value,NOP_16,scenario_16_shock_value,NOP_17,scenario_17_shock_value,NOP_18,scenario_18_shock_value,NOP_19,scenario_19_shock_value,NOP_20,scenario_20_shock_value,NOP_21,scenario_21_shock_value,NOP_22,scenario_22_shock_value,NOP_23,scenario_23_shock_value,NOP_24,scenario_24_shock_value,NOP_25,scenario_25_shock_value,NOP_26,scenario_26_shock_value,NOP_27,scenario_27_shock_value,NOP_28,scenario_28_shock_value,NOP_29,scenario_29_shock_value,NOP_30,scenario_30_shock_value,NOP_31,scenario_31_shock_value,NOP_32,scenario_32_shock_value,NOP,HedgeServerID, 'credit' as scenario, 'short' as direction,'cfd' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_cfd_others_2_short_nop
union all
select rank_instrument,NOP_1,scenario_1_shock_value,NOP_2,scenario_2_shock_value,NOP_3,scenario_3_shock_value,NOP_4,scenario_4_shock_value,NOP_5,scenario_5_shock_value,NOP_6,scenario_6_shock_value,NOP_7,scenario_7_shock_value,NOP_8,scenario_8_shock_value,NOP_9,scenario_9_shock_value,NOP_10,scenario_10_shock_value,NOP_11,scenario_11_shock_value,NOP_12,scenario_12_shock_value,NOP_13,scenario_13_shock_value,NOP_14,scenario_14_shock_value,NOP_15,scenario_15_shock_value,NOP_16,scenario_16_shock_value,NOP_17,scenario_17_shock_value,NOP_18,scenario_18_shock_value,NOP_19,scenario_19_shock_value,NOP_20,scenario_20_shock_value,NOP_21,scenario_21_shock_value,NOP_22,scenario_22_shock_value,NOP_23,scenario_23_shock_value,NOP_24,scenario_24_shock_value,NOP_25,scenario_25_shock_value,NOP_26,scenario_26_shock_value,NOP_27,scenario_27_shock_value,NOP_28,scenario_28_shock_value,NOP_29,scenario_29_shock_value,NOP_30,scenario_30_shock_value,NOP_31,scenario_31_shock_value,NOP_32,scenario_32_shock_value,NOP,HedgeServerID, 'credit' as scenario, 'long' as direction,'real' as cfd_real from risk.risk_output_rm_tables_credit_client_pnl_real_others_2_long_nop
)
base
group by rank_instrument) nop
on final2.rank_instrument=nop.rank_instrument
)final3
)final4
group by InstrumentID_rpt, rank_instrument_rpt, InstrumentType_dash
)final5
)final6
)
)final7
where rank_instrument_rpt<>'Commodities_all'
)final8
)final9