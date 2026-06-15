SELECT  Distinct

  	dc.Name as Country
    ,evp.Name as EvProvider
,       dr.Name as DesignatedRegulation
,      CAST (cr.TransactionDate AS date) TransactionDate
, cc.EvMatchStatus
,e.EvMatchStatusName
,db.IsFTD
,cc.VerificationLevelID
,cc.RealCID
,cast(cc.RegisteredReal as date) as RegisteredReal
     FROM  main.compliance.bronze_userapidb_ev_customerresult  cr
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked cc on cr.GCID = cc.GCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc on cc.CountryID=dc.CountryID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr on dr.ID= cc.DesignatedRegulationID
JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus e on e.EvMatchStatusID = cc.EvMatchStatus
JOIN main.compliance.bronze_userapidb_dictionary_evprovider evp on cr.EvProviderId = evp.EvProviderId
LEFT JOIN main.billing.bronze_etoro_billing_deposit db on db.CID=cc.RealCID AND db.IsFTD=1
where 
cast(TransactionDate as date)>='2024-01-01'
        and cr.EvProviderId not in (3,4,13)
        and cc.CountryID in (12,13,19,43,57,72,74,79,102,123,132,143,154,161,162,183,191,196,197,218,219,226)