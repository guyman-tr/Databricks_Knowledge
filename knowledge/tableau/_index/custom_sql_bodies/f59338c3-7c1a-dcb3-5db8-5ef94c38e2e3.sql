select * except(UpdateTime,UpdateTime_choosing_date) from risk.risk_output_rm_tables_var_fx_top_instruments
where hc_inst>2 -- removing 0
order by Percentile desc,weight_inst desc