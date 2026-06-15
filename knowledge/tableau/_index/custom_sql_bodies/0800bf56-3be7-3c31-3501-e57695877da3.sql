select 
Report_time,diffusion_time, lp_time, Percentile, OccurredDate
,row_number() over(partition by diffusion_time,lp_time,Percentile, OccurredDate order by Report_time desc) rn_new --desc to be aligned with last one showed


from
(

select base1.* except(base1.hc_day, base1.weight_inst) ,update_time.diffusion_time,update_time.lp_time
,base1.current_NOP - base1.NOP_Hedged as NOP_exposure
,coalesce(base1.NOP_Hedged/base1.current_NOP,0) as NOP_Hedged_perc
,percentiles.hc_value as hc_day
,coalesce(base1.hc_inst/percentiles.hc_value,0) as weight_inst


from
(
select base.* 
, row_number() over(Partition by Report_time, Percentile, InstrumentName, OccurredDate order by base.Report_time_history asc) rn
from risk.risk_output_rm_tables_history_var_top_contributor base
qualify rn=1
)base1
inner join
(

select * from 
risk.risk_output_rm_tables_var_trigger_time
where ind_continue=1

)update_time
on
base1.Report_time=update_time.Report_time

inner join
(select distinct Percentile, hc_value,Report_time
from risk.risk_output_rm_tables_history_var_percentiles
) percentiles
on base1.Report_time=percentiles.Report_time and base1.Percentile=percentiles.Percentile
where base1.InstrumentName is not null
and base1.Report_time >='2023-06-01' -- no abnormal values from 202303

)final
qualify rn_new=1
order by Report_time desc, Percentile desc