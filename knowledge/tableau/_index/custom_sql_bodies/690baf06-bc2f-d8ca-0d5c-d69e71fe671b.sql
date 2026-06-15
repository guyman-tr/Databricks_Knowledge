select 'clients_diffusion' as source_data,  Update_diffution_GMT as GMT_time from risk.risk_output_rm_tables_var_hourly_percentile_100_updatetime_clients
union all
select 'eToro_hedging' as source_data, Update_eToro_GMT as GMT_time from risk.risk_output_rm_tables_var_hourly_percentile_100_updatetime_etoro