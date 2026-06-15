select base.*
,row_number() over(partition by diffusion_time,credit_time,eToro_hedging order by Report_time_history desc) rn --desc to be aligned with last one showed


from
(
select dif.* 
,cred.credit_time
,lp.eToro_hedging
from
(select max_position_time as diffusion_time, Report_time_history from risk.risk_output_rm_tables_stress_test_history_clients_diffusion_update_time_v2 ) dif
left join
(select max_position_time as credit_time, Report_time_history from risk.risk_output_rm_tables_stress_test_history_clients_credit_update_time_v2 ) cred
on dif.Report_time_history=cred.Report_time_history
left join
(select etoro_pnl_time as eToro_hedging ,Report_time_history from risk.risk_output_rm_tables_stress_test_history_etoro_update_time_v2 ) lp
on dif.Report_time_history=lp.Report_time_history
)base
where base.Report_time_history not in
(select distinct Report_time_history from

(select Report_time_history, scenario, scenario_market, sum(risk) risk_total
from risk.risk_output_rm_tables_stress_test_history_clients_v2 
group by Report_time_history, scenario, scenario_market) base1
where abs(risk_total) >=200E6 --fixing not realistic outliers
)
qualify rn=1
order by Report_time_history desc