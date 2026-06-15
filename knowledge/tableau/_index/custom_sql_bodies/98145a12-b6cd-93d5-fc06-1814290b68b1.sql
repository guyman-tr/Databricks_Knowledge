select * 
from risk.risk_output_rm_tables_stress_test_history_clients_v2
where Report_time_history >='2023-07-26' --fixing SQQQ configuration like VIX during July 25th 2023
and scenario_market in ('all up','all down','bearish','bullish')
and Report_time_history  not in
(select distinct Report_time_history from

(select Report_time_history, scenario, scenario_market, sum(risk) risk_total
from risk.risk_output_rm_tables_stress_test_history_clients_v2 
group by Report_time_history, scenario, scenario_market) base 
where abs(risk_total) >=200E6 --fixing not realistic outliers
)

order by Report_time_history

/*
select * 
from risk.risk_output_rm_tables_stress_test_history_clients_v2
where Report_time_history >='2023-07-26' --fixing SQQQ configuration like VIX during July 25th 2023
order by Report_time_history
*/