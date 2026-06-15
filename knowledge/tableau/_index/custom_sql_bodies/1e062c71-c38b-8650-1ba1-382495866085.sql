WITH JourneyData AS (
  SELECT 
    DISTINCT 
    CAST(bdsajlt.TimeStamp AS DATE) AS JourneyDate,  /* Convert timestamp to date */
    SPLIT(bdsajlt.Journey_Name, '_')[0] AS CampaignNumber,
    bdsajlt.Journey_Name,
    bdsajlt.GCID,
    bdsajlt.Action,     
    bdsajlt.Message
  FROM 
    main.sfmc.silver_sfmc_accountjourneylogtracking bdsajlt
  WHERE 
    bdsajlt.Journey_Name LIKE '%APACAirdrop%'  /* Filter only APAC Airdrop related journeys */
    AND bdsajlt.Action NOT IN ('Email', 'Intercom') /* Exclude email and intercom actions */
),

pop AS (
SELECT 
  aj.Journey_Name, 
  aj.JourneyDate,
  aj.CampaignNumber, 
  aj.GCID,
  CASE 
    WHEN MAX(CASE WHEN aj.Message LIKE '%Control%' THEN 1 ELSE 0 END) = 1 THEN 'Control' /* Prioritize Control */
    WHEN MAX(CASE WHEN aj.Message LIKE '%Test%' OR (aj.Action = 'Entry' AND aj.Message NOT LIKE '%Test%') THEN 1 ELSE 0 END) = 1 THEN 'Test' /* Otherwise, Test */
    ELSE 'Unknown' /* Catch-all, if neither Test nor Control exists */
  END AS Group
FROM 
  JourneyData aj
GROUP BY 
  aj.Journey_Name, 
  aj.JourneyDate,
  aj.CampaignNumber, 
  aj.GCID
 
), 

pop_metrics AS (
SELECT p.*,
  ddr.Region,
  ddr.Country,
  ddr.Regulation,
  SUM(ddr.Deposits) AS Deposits_30D_After,
  SUM(ddr.DepositsCount) AS DepositsCount_30D_After,
  SUM(ddr.Cashouts) AS Cashouts_30D_After,
  SUM(ddr.CashoutsCount) AS CashoutsCount_30D_After,
  SUM(ddr.Revenue) AS Revenue_30D_After
FROM pop p
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON p.GCID = dc.GCID
  JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level ddr ON (dc.RealCID = ddr.CID) AND (ddr.etr_ymd BETWEEN p.JourneyDate AND DATEADD(DAY, 30, p.JourneyDate))  
GROUP BY
  p.Journey_Name, 
  p.JourneyDate,
  p.CampaignNumber, 
  p.GCID,
  p.Group,
  ddr.Region,
  ddr.Country,
  ddr.Regulation

)
SELECT 
  pm.Journey_Name,
  pm.JourneyDate,
  pm.CampaignNumber,
  pm.Group,
  pm.Region,
  pm.Country,
  pm.Regulation,
  COUNT(pm.GCID) AS Client_Count,
  SUM(pm.Deposits_30D_After) AS Deposits_30D_After,
  SUM(pm.DepositsCount_30D_After) AS DepositsCount_30D_After,
  SUM(pm.Cashouts_30D_After) AS Cashouts_30D_After,
  SUM(pm.CashoutsCount_30D_After) AS CashoutsCount_30D_After,
  SUM(pm.Revenue_30D_After) AS Revenue_30D_After    

FROM pop_metrics pm
GROUP BY
  pm.Journey_Name,
  pm.JourneyDate,
  pm.CampaignNumber,
  pm.Group,
  pm.Region,
  pm.Country,
  pm.Regulation