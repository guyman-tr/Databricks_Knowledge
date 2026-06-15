With cids as (
SELECT
	c.RealCID,
	c.GCID,
	co.Name as KYC_Country,
	r.Name as Regulation,
  op.OptionsApexID
FROM
	main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked c
LEFT JOIN 
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country co on co.CountryID = c.CountryID
LEFT JOIN  
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r on r.ID = c.RegulationID
JOIN 
  main.general.bronze_usabroker_apex_options op on op.GCID = c.GCID
WHERE 
  c.RegulationID NOT IN (6,7,8,12,14)
  and c.CountryID NOT IN (218) 
  and c.IsValidCustomer = 1
  and c.PlayerLevelID not in (4)
  and c.PlayerStatusID not in (2,4)
)

,countrychange AS (
  SELECT a.CID
      ,a.CountryID AS Current_ID
      ,dps.Name AS Current_Country   
      ,a.Previous_CountryID AS Previous_ID
      ,pps.Name AS Previous_Country
      ,a.Change_Date
      ,ROW_NUMBER() OVER (PARTITION BY a.CID ORDER BY a.Change_Date DESC) AS RowNum
  FROM (
    SELECT fsc.RealCID AS CID
          ,fsc.CountryID
          ,TO_DATE(CAST(dr.FromDateID AS STRING), 'yyyyMMdd') AS Change_Date            
          ,LAG(fsc.CountryID, 1, 0) OVER(PARTITION BY fsc.RealCID ORDER BY dr.FromDateID ASC) AS Previous_CountryID
    FROM 
      dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    INNER JOIN 
      main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr ON fsc.DateRangeID = dr.DateRangeID   
    JOIN cids c on c.RealCID = fsc.RealCID      
  ) a

  INNER JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dps ON a.CountryID = dps.CountryID
  INNER JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country pps ON a.Previous_CountryID = pps.CountryID
  WHERE 
    a.CountryID <> a.Previous_CountryID
)


select
  c.gcid
  ,c.realcid
  ,c.regulation
  ,c.optionsapexid
  ,cc.change_date
  ,cc.current_country
  ,cc.previous_country
FROM 
  cids c 
LEFT JOIN 
  countrychange cc ON c.RealCID = cc.CID
WHERE 
  cc.RowNum = 1
  --and cc.previous_id = 218
  and c.optionsapexid is not null