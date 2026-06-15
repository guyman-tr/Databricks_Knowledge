-- select 'clients_diffusion' as source_data,  Update_table_pnl_day as GMT_time from risk.risk_output_rm_tables_var_temp_update_time_temp
-- union all
-- select 'eToro_hedging' as source_data, etoro_pnl_time as GMT_time from risk.risk_output_rm_tables_var_etoro_pnl_daily_update_time



select 'clients_diffusion' as source_data,  base.diffusion_time as GMT_time
from

(select distinct Report_time from risk.risk_output_rm_tables_var_percentiles) perc
left join
(select * from
risk.risk_output_rm_tables_var_trigger_time
where ind_continue=1
order by Report_time desc
limit 1) base
on base.Report_time=perc.Report_time

union all

select 'eToro_hedging' as source_data,  base1.lp_time as GMT_time
from

(select distinct Report_time from risk.risk_output_rm_tables_var_percentiles) perc
left join
(select * from
risk.risk_output_rm_tables_var_trigger_time
where ind_continue=1
order by Report_time desc
limit 1) base1
on base1.Report_time=perc.Report_time