SELECT  
    dc.Name as Country
    ,ev.Name as EvProvider
    ,CAST (cr.TransactionDate AS date) TransactionDate
    ,count(distinct cc.RealCID) as NoOfCIDsSent
    ,count(distinct case when  lower(cc2.Comments) like ('%registration abuse%')then cc2.CID end) as NoOfCIDsSent_Abuse
    ,count(distinct case when cc.EvMatchStatus=2 then cc.RealCID end) as NoOfCIDsVerified
FROM  
    main.compliance.bronze_userapidb_ev_customerresult  cr
JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked cc on cr.GCID = cc.GCID
JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc on cc.CountryID=dc.CountryID
JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr on dr.ID= cc.DesignatedRegulationID
LEFT JOIN 
    main.compliance.bronze_userapidb_dictionary_evprovider ev on ev.EvProviderId = cr.EvProviderId
LEFT JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus ev1 on cc.EvMatchStatus=ev1.EvMatchStatusId
LEFT JOIN 
  main.general.bronze_etoro_customer_customer_masked cc2 on cc2.CID = cc.RealCID
where 
    cast(TransactionDate as date)>='2025-10-01' and
     cr.EvProviderId not in (3,4,13) -- Au10tix-Documents, TruNarrative, Onfido
    and cc.CountryID in (12,13,19,43,57,72,74,79,102,123,132,143,154,161,162,183,191,196,197,218,219,226)
   --and dc.Name in ('Germany','France')
Group by 
    dc.Name   
    ,CAST (cr.TransactionDate AS date)
    ,ev.Name