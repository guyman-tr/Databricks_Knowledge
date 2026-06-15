SELECT
  count(dc.RealCID) as TotalClients
  ,coalesce(dc.`2FA`, 0) as `2FA`
  ,pl.Name as PlayerLevel
  ,cast(c.LastLoggedIn as date) as LastLoggedIn
  ,co.Name as Country
  ,r.Name as Regulation
,dc.VerificationLevelID
FROM 
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
LEFT JOIN 
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl on pl.PlayerLevelID = dc.PlayerLevelID
LEFT JOIN 
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked c on c.CID = dc.RealCID
LEFT JOIN 
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country co on co.CountryID = dc.CountryID
LEFT JOIN 
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r on r.ID = dc.RegulationID
WHERE 
    dc.PlayerStatusID not in (2,4)
    AND dc.IsValidCustomer = 1
GROUP BY 
  all