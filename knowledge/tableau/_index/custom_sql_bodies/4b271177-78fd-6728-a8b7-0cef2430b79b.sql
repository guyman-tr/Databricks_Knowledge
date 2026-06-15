SELECT  
	CAST (cr.TransactionDate AS date) TransactionDate
 ,	dc.Name as Country
,	count(distinct cc.RealCID) as NoOfCIDs
,count(cc.RealCID) as NoOfTransactions
,      evp.Name As EvProvider
,        evs.Name As EvStatus
,cast(cc.RegisteredReal as Date) as RegisteredReal
     FROM  main.compliance.bronze_userapidb_ev_customerresult cr
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked cc on cr.GCID = cc.GCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc on cc.CountryID=dc.CountryID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus ev1 on cc.EvMatchStatus=ev1.EvMatchStatusId
join main.compliance.bronze_userapidb_dictionary_evprovider evp on cr.EvProviderId = evp.EvProviderId
join main.bi_db.bronze_userapidb_dictionary_evstatus evs on cr.EvStatusId = evs.EvStatusId
where 
cast(TransactionDate as date)>='2023-01-01'
        and cr.EvProviderId not in (3,4,13)
        and cc.CountryID in (12,13,19,43,57,72,74,79,102,123,132,143,154,161,162,183,191,196,197,218,219,226)
Group by 
        dc.Name,
CAST (cr.TransactionDate AS date),
evp.Name,
evs.Name,
cast(cc.RegisteredReal as Date) 
Order by
        dc.Name asc,
      CAST (cr.TransactionDate AS date)