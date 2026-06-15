select 'Diffusion' as source, max_position_time as GMT_time from risk.risk_output_rm_tables_diffusion_client_pnl_cfd_instruments_2_updatime_time
union all
select 'Credit' as source, max_position_time as GMT_time from risk.risk_output_rm_tables_credit_client_pnl_cfd_instruments_2_updatime_time
union all
select 'eToro_hedging' as source, etoro_pnl_time as GMT_time from risk.risk_output_rm_tables_diffusion_etoro_pnl_instruments_2_update_time