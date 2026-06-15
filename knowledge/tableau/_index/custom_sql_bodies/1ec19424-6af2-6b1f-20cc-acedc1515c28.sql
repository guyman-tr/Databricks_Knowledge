select base.*
,case when InstrumentID in (3000,4238) then 'SPY vs VOO'
when InstrumentID in (3006,4459,4465) then 'QQQ vs SQQQ,TQQQ'
when InstrumentID =3005 then 'IWM' end as group_name

,case when InstrumentID =4459 then Nop_UnHedged*-3
when InstrumentID=4465 then NOP_UnHedged*3
else NOP_Unhedged end NOP_UNHedged_exposure

from
(
select *,coalesce (current_NOP,0)-coalesce(NOP_Hedged,0 ) NOP_UnHedged
 from risk.risk_output_rm_tables_history_var_instruments_hs_25
)base