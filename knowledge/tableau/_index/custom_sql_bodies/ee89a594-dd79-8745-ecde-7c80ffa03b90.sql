select DataUpdate,InstrumentType, sum(Gross_OP_CFD) Gross_OP_CFD,sum(NOP_CFD) NOP_CFD
from
(
select distinct DataUpdate, InstrumentType, Gross_OP_CFD, NOP_CFD
from
(
risk.risk_output_rm_tables_concentration_instrument_history_gross_op_nop_instrument_cfd
)base
)final

group by DataUpdate,InstrumentType

order by DataUpdate