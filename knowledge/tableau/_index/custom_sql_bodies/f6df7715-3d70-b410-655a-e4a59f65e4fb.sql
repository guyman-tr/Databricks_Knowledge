select 'Diffusion' as source, max_position_time as GMT_time from risk.risk_output_rm_tables_stress_test_diffusion_update_time
union all
select 'Credit' as source, max_position_time as GMT_time from risk.risk_output_rm_tables_stress_test_credit_update_time
union all
select 'eToro_hedging' as source, etoro_pnl_time as GMT_time from risk.risk_output_rm_tables_stress_test_lp_exposure_update_time