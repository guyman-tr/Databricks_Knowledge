select "Current VaR 99% is " as description ,round(hc_value,0) value,
".The reference is" as comment1, "15,000,000" as reference, case when hc_value<= 15E6 then ".Ok" else ".Not ok" end as status

from risk.risk_output_rm_tables_var_percentiles
where Percentile=99