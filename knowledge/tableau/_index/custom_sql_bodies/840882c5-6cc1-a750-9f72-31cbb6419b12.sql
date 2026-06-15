select PositionsTime_calculation,InstrumentID,InstrumentName,InstrumentType,Bid,Ask,'diffusion' as scenario from risk.risk_output_rm_tables_diffusion_prices_calculation
union all
select PositionsTime_calculation,InstrumentID,InstrumentName,InstrumentType,Bid,Ask,'credit' as scenario from risk.risk_output_rm_tables_credit_prices_calculation