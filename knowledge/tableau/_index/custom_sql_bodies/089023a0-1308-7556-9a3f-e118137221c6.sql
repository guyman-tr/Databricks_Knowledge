SELECT  
	CAST (cr.TransactionDate AS date) TransactionDate
 ,	dc.Name as Country
 ,	ev1.EvMatchStatusName as EvMatchStatus
 ,	count(distinct cc.RealCID) as NoOfCIDs
,cast(cc.RegisteredReal as Date) as RegisteredReal
FROM  main.compliance.bronze_userapidb_ev_customerresult cr
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked cc on cr.GCID = cc.GCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc on cc.CountryID=dc.CountryID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus ev1 on cc.EvMatchStatus=ev1.EvMatchStatusId
where 
cast(TransactionDate as date)>='2023-01-01'
and cr.EvProviderId not in (3,4,13)
and cc.CountryID in (12,13,19,43,57,72,74,79,102,123,132,143,154,161,162,183,191,196,197,218,219,226)
Group by 
dc.Name,
CAST (cr.TransactionDate AS date),
ev1.EvMatchStatusName
,cast(cc.RegisteredReal as Date)
Order by
dc.Name asc,
CAST (cr.TransactionDate AS date)