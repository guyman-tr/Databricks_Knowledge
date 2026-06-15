select NOP_CFD as Value, "NOP_CFD" as type
from
(select  NOP_CFD
,NOP - NOP_CFD as NOP_Real
from
(
select t1.NOP,t2.NOP_CFD

from
(
select sum(NOP) as NOP, 1 as sup 
from risk.risk_output_rm_tables_concentration_instrument_gross_op_nop_instrument 
)t1
left join
(select sum(NOP_CFD) as NOP_CFD , 1 as sup 
from risk.risk_output_rm_tables_concentration_instrument_gross_op_nop_instrument_cfd
)t2
on t1.sup=t2.sup
)final
)
union


select NOP_Real as Value, "NOP_Real" as type
from
(select  NOP_CFD
,NOP - NOP_CFD as NOP_Real
from
(
select t1.NOP,t2.NOP_CFD

from
(
select sum(NOP) as NOP, 1 as sup 
from risk.risk_output_rm_tables_concentration_instrument_gross_op_nop_instrument 
)t1
left join
(select sum(NOP_CFD) as NOP_CFD , 1 as sup 
from risk.risk_output_rm_tables_concentration_instrument_gross_op_nop_instrument_cfd
)t2
on t1.sup=t2.sup
)final
)