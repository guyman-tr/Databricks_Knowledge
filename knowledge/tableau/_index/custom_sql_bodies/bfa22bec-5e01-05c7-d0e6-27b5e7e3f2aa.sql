select final.*


from
(

select base1.* except(base1.hc_day, base1.weight_inst) ,update_time.diffusion_time,update_time.lp_time
,base1.current_NOP - base1.NOP_Hedged as NOP_exposure
,coalesce(base1.NOP_Hedged/base1.current_NOP,0) as NOP_Hedged_perc
,percentiles.hc_value as hc_day
,coalesce(base1.hc_inst/percentiles.hc_value,0) as weight_inst
, year(base1.Report_time_history)*1e8 + month(base1.Report_time_history)*1e6 + day(base1.Report_time_history)*1e4 + hour(base1.Report_time_history)*1e2 + minute(base1.Report_time_history) as report_time_id


from
(
select base.* 
, row_number() over(Partition by Report_time, Percentile, InstrumentName order by base.Report_time_history asc) rn
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
and InstrumentID not in (3000,3005,3006,4238,4459,4465)--HS25
)final
where report_time_id <> 202308180007 -- Crypto data mistake: Or request (20230820)
order by Report_time_history desc, Percentile desc