--select * from risk.risk_output_rm_tables_abnormal_low_price


select * from
risk.risk_output_rm_tables_abnormal_low_price
where is_used=1
and day_report_id=year(getdate())*1E4 + month(getdate())*1E2 + day(getdate())
order by Report_time desc