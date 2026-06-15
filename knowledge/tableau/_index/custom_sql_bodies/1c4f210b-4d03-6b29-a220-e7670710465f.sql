--select * from risk.risk_output_rm_tables_abnormal_return



select * from
risk.risk_output_rm_tables_abnormal_return
where is_used=1
and day_report_id=year(getdate())*1E4 + month(getdate())*1E2 + day(getdate())
and Report_time = (select max(Report_time) from risk.risk_output_rm_tables_abnormal_return)
order by Report_time desc