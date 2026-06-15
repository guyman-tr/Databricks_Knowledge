select * except(UpdateTime,UpdateTime_choosing_date) from risk.risk_output_rm_tables_var_top_instruments
where hc_inst>2 -- removing 0
and Percentile =99
order by hc_inst desc
limit 5