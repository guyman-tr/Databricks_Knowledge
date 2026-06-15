select * 
, case when ind_var_breach=1 and rn_ind_var_time=1 then 1 else 0 end as ind_var_breach_new

from
(
select * 
, row_number() over( partition by ind_var_distinct order by report_time) as rn_ind_var_time
from
(
select *
, concat(ind_var_breach, "_",var99,"_",year(report_time)*1E4+month(report_time)*1e2 + day(report_time))as ind_var_distinct 
from
(

SELECT Report_time_history as report_time, hc_value as var99
,case when hc_value>=15E6 then 1 else 0 end as ind_var_breach
FROM risk.risk_output_rm_tables_history_var_percentiles 
where Percentile=99
and hc_value<100E6
and Report_time_history >='2023-01-01'
and Report_time_history <'2023-06-12' --Var 99 using 3 years

and Report_time_history in
(

---Manual: 6 hours and 1 hour difference

select current_time
from
(

select base1.*
,case when dif_difussion_lp>=1 or dif_diffusion_now>=6 or dif_lp_now>=6 then 0 else 1 end  as ind_continue
from
(
select base.*
,round(abs(datediff(minute,diffusion_time,lp_time)/60),2) as dif_difussion_lp
,round(abs(datediff(minute,diffusion_time,current_time)/60),2) as dif_diffusion_now
,round(abs(datediff(minute,lp_time,current_time)/60),2)as dif_lp_now

from
(


select t1.diffusion_time,t1.Report_time_history as current_time, t2.lp_time
from
(
select GMT_time as diffusion_time, Report_time_history from risk.risk_output_rm_tables_history_var_updatetime where source_data='clients_diffusion'
)t1
left join
(
select GMT_time as lp_time, Report_time_history from risk.risk_output_rm_tables_history_var_updatetime where source_data='eToro_hedging'
)t2
on t1.Report_time_history=t2.Report_time_history
)base
)base1
)base2
where ind_continue=1


)
)
final
)final1
)final2
order by report_time desc