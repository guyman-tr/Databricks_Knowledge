SELECT
	c.*
   ,dc1.Name AS Country
FROM
main.bi_output_stg.bi_output_operations_monthly_kpis_wires  c
	JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
		ON c.CID = dc.RealCID
	JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1
		ON dc.CountryID = dc1.CountryID
where FundingTypeID=2