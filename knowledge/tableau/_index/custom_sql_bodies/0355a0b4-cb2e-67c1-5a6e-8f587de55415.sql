(
select "Last NOP CFD is " as description,
NOP_CFD,". Average of this month is" as comment1
,avg_NOP_CFD_month, case when NOP_CFD>=avg_NOP_CFD_month then ".Ok" else ".Not ok" end as status
from
(
select current_nop.*,base2.avg_NOP_CFD_month
from
(
select year(DataUpdate)*100 + month(DataUpdate) as yearmonth,NOP_CFD
from
(
select DataUpdate,sum(NOP_CFD) NOP_CFD
from risk.risk_output_rm_tables_concentration_instrument_gross_op_nop_instrument_cfd
group by DataUpdate
)base
)current_nop
left join
(
select * from
(
select yearmonth, avg(NOP_CFD) as avg_NOP_CFD_month
from
(
select year(DataUpdate)*100 + month(DataUpdate) as yearmonth, NOP_CFD
from
(
select DataUpdate, sum(NOP_CFD) NOP_CFD

from
(
select distinct DataUpdate,NOP_CFD-- NOP_CFD--, year(DataUpdate)*100 + month(DataUpdate) as yearmonth
from
risk.risk_output_rm_tables_concentration_instrument_history_gross_op_nop_instrument_cfd
)base1
group by DataUpdate
)base1_temp
)base1_temp1
group by yearmonth
)
)base2
on current_nop.yearmonth=base2.yearmonth
)final
)