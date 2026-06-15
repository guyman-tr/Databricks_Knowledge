SELECT  

  	dc.Name as Country
,       dr.Name as DesignatedRegulation
,      CAST (cr.TransactionDate AS date) TransactionDate
,      count(distinct cc.RealCID) as NoOfCIDsSent
,       count(distinct case when cc.EvMatchStatus=2 then cc.RealCID end) as NoOfCIDsVerified
,		 count(distinct case when db.IsFTD=1 AND cc.EvMatchStatus=2 then cc.RealCID end) as NoDeposited
,        count(distinct case when cc.VerificationLevelID=2 AND cc.EvMatchStatus=2 then cc.RealCID end) as NoLevel2
,        count(distinct case when cc.VerificationLevelID=3 AND cc.EvMatchStatus=2 then cc.RealCID end) as NoLevel3
     FROM  main.compliance.bronze_userapidb_ev_customerresult  cr
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked cc on cr.GCID = cc.GCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc on cc.CountryID=dc.CountryID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr on dr.ID= cc.DesignatedRegulationID
LEFT JOIN main.billing.bronze_etoro_billing_deposit db on db.CID=cc.RealCID AND db.IsFTD=1
where 
cast(TransactionDate as date)>='2022-08-01'
        and cr.EvProviderId not in (3,4,13)
        and cc.CountryID in (12,13,19,43,57,72,74,79,102,123,132,143,154,161,162,183,191,196,197,218,219,226)
Group by 
        dc.Name,
CAST (cr.TransactionDate AS date),
 dr.Name
Order by
        dc.Name asc,
      CAST (cr.TransactionDate AS date)