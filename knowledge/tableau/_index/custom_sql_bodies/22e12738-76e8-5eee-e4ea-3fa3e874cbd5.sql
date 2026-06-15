select  inst.InstrumentID,inst.InstrumentType,inst.Name
,base.*
from risk.risk_output_rm_tables_diffusion_risk_appetite base
left join risk.risk_output_rm_tables_diffusion_main_instrument_details inst
on base.InstrumentDisplayName=inst.InstrumentDisplayName
order by InstrumentID