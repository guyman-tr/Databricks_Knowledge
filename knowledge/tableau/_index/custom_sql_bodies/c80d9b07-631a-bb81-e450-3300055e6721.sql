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
)

SELECT 
  aj.Journey_Name, 
  aj.JourneyDate, 
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
  aj.GCID