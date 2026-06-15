--select * from risk.risk_output_rm_tables_abnormal_grossop_nop



select * from
risk.risk_output_rm_tables_abnormal_grossop_nop
where is_used=1
and (NOP >=10E6 or NOP<=-10E6)
and day_report_id=year(getdate())*1E4 + month(getdate())*1E2 + day(getdate())
and Report_time = (select max(Report_time) from risk.risk_output_rm_tables_abnormal_grossop_nop)
order by Report_time desc