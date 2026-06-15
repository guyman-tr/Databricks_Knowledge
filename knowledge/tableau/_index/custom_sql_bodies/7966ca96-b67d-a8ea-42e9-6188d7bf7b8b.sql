SELECT c.*, dc1.Name as Country, ft.Name as FundingType,
CASE WHEN c.HoursBetween<=2 THEN 'A: <=2 hrs'
WHEN c.HoursBetween<=4 THEN 'B: <=4 hrs'
WHEN c.HoursBetween<=6 THEN 'C: <=6 hrs'
WHEN c.HoursBetween<=8 THEN 'D: <=8 hrs'
WHEN c.HoursBetween<=10 THEN 'E: <=10 hrs'
WHEN c.HoursBetween<=12 THEN 'F: <=12 hrs'
WHEN c.HoursBetween<=16 THEN 'G: <=16 hrs'
WHEN c.HoursBetween<=18 THEN 'H: <=18 hrs'
WHEN c.HoursBetween<=20 THEN 'I: <=20 hrs'
WHEN c.HoursBetween<=22 THEN 'J: <=22 hrs'
WHEN c.HoursBetween<=24 THEN 'K: <=24 hrs'
ELSE 'L: >24 Hrs' END AS HoursDistribution,
CASE WHEN dc.HasWallet = 1 then 'Yes' else 'No' end as HasWallet
FROM main.bi_output_stg.bi_output_operations_monthly_kpis_cashouts c
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON c.CID = dc.RealCID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1 ON dc.CountryID = dc1.CountryID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ft ON ft.FundingTypeID = c.FundingTypeID
where RequestDate >= add_months(current_date(), -6)