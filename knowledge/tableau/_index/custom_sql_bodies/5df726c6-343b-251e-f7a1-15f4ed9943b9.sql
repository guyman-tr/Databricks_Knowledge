select Gross_OP_CFD as Value, "Gross_OP_CFD" as type
from
(select  Gross_OP_CFD
,Gross_OP - Gross_OP_CFD as Gross_OP_Real
from
(
select t1.Gross_OP,t2.Gross_OP_CFD

from
(
select sum(Gross_OP) as Gross_OP, 1 as sup 
from risk.risk_output_rm_tables_concentration_instrument_gross_op_nop_instrument 
)t1
left join
(select sum(Gross_OP_CFD) as Gross_OP_CFD , 1 as sup 
from risk.risk_output_rm_tables_concentration_instrument_gross_op_nop_instrument_cfd
)t2
on t1.sup=t2.sup
)final
)
union


select Gross_OP_Real as Value, "Gross_OP_Real" as type
from
(select  Gross_OP_CFD
,Gross_OP - Gross_OP_CFD as Gross_OP_Real
from
(
select t1.Gross_OP,t2.Gross_OP_CFD

from
(
select sum(Gross_OP) as Gross_OP, 1 as sup 
from risk.risk_output_rm_tables_concentration_instrument_gross_op_nop_instrument 
)t1
left join
(select sum(Gross_OP_CFD) as Gross_OP_CFD , 1 as sup 
from risk.risk_output_rm_tables_concentration_instrument_gross_op_nop_instrument_cfd
)t2
on t1.sup=t2.sup
)final
)