With cids as (
  SELECT
	c.RealCID,
  c.RegisteredReal,
  c.GCID,
	co.Name as KYC_Country,
  co1.Name as CountryIDByIP,
	c.VerificationLevelID,
	ps.Name as PlayerStatus,
	pl.Name as PlayerLevel,
  cc.Comments,
  at.Name as AccountType,
  p.PendingClosureStatusName,
  c.IsDepositor
FROM
	main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked c
	LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country co on co.CountryID = c.CountryID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country co1 on co1.CountryID = c.CountryIDByIP
	LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ps on ps.PlayerStatusID = c.PlayerStatusID
	LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl on c.PlayerLevelID = pl.PlayerLevelID
  LEFT JOIN main.general.bronze_etoro_customer_customer_masked cc on cc.CID = c.RealCID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype at on at.AccountTypeID = c.AccountTypeID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus p on p.PendingClosureStatusID = c.PendingClosureStatusID
WHERE 
  c.PlayerStatusID IN (2)
  and lower(cc.Comments) like ('%registration abuse%')
)

,ps AS (
  SELECT a.CID
      ,a.PlayerStatusID AS Current_ID
      ,dps.Name AS Current_PlayerStatus     
      ,a.Previous_PlayerStatusID AS Previous_ID
      ,pps.Name AS Previous_PlayerStatus
      ,a.Change_Date
      ,a.Is_FTD      
      ,ROW_NUMBER() OVER (PARTITION BY a.CID ORDER BY a.Change_Date DESC) AS RowNum
  FROM (
    SELECT fsc.RealCID AS CID
          ,CASE WHEN fsc.IsDepositor = 1 THEN 1 ELSE 0 END AS Is_FTD
          ,fsc.PlayerStatusID 
          ,TO_DATE(CAST(dr.FromDateID AS STRING), 'yyyyMMdd') AS Change_Date            
          ,LAG(fsc.PlayerStatusID, 1, 0) OVER(PARTITION BY fsc.RealCID ORDER BY dr.FromDateID ASC) AS Previous_PlayerStatusID
    FROM 
      dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    INNER JOIN 
      main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr ON fsc.DateRangeID = dr.DateRangeID
    JOIN 
      cids c on c.realcid = fsc.RealCID            
  ) a

  INNER JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus dps ON a.PlayerStatusID = dps.PlayerStatusID
  INNER JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus pps ON a.Previous_PlayerStatusID = pps.PlayerStatusID

  WHERE 
    a.PlayerStatusID <> a.Previous_PlayerStatusID
    AND a.PlayerStatusID = 2
)

,psfinal as (
SELECT DISTINCT
  p.CID
  ,p.Previous_PlayerStatus
  ,p.Change_Date
  ,p.Current_PlayerStatus
FROM 
  ps p
WHERE 
  p.RowNum = 1
)

,evvendor as (
SELECT DISTINCT
    cc.RealCID
    ,ev.Name as EvProvider
    ,ev1.EvMatchStatusName
FROM  
    main.compliance.bronze_userapidb_ev_customerresult  cr
JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked cc on cr.GCID = cc.GCID
LEFT JOIN 
    main.compliance.bronze_userapidb_dictionary_evprovider ev on ev.EvProviderId = cr.EvProviderId
LEFT JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus ev1 on cc.EvMatchStatus=ev1.EvMatchStatusId
)

,finalev as (

Select distinct 
    e.RealCID
    ,concat_ws(', ', collect_list(e.EvProvider)) as EvProviders
    ,concat_ws(', ', collect_list(e.EvMatchStatusName)) as EvMatchStatus
FROM 
    evvendor e
GROUP BY 
    e.RealCID
)


select
  c.*
  ,p.change_date as ClosureDate
  ,f.evproviders
  ,f.evmatchstatus
FROM
  cids c 
JOIN 
  psfinal p on p.CID = c.RealCID
LEFT JOIN 
  finalev f on f.RealCID = c.RealCID