--select * 
--from risk.risk_output_rm_tables_var_hourly_percentile_99_hc_hourly
--order by OccurredDate


select var99_hourly.* except (pk), final_time1.gap_tables_min
from

(select * , 1 as pk from risk.risk_output_rm_tables_var_hourly_percentile_99_hc_hourly )var99_hourly
left join
(
select diffusion_time,etoro_time,pk
,abs(datediff(minute,diffusion_time,etoro_time)) as gap_tables_min
from
(
select dif.*,etoro.etoro_time
from
(
select Update_table_pnl_day as diffusion_time,1 as pk from risk.risk_output_rm_tables_var_temp_update_time_temp 
)dif

left join
(select etoro_pnl_time  as  etoro_time ,1 as pk from risk.risk_output_rm_tables_var_etoro_pnl_daily_update_time ) etoro
on dif.pk=etoro.pk
)final_time
) final_time1
on var99_hourly.pk=final_time1.pk

order by var99_hourly.OccurredDate desc