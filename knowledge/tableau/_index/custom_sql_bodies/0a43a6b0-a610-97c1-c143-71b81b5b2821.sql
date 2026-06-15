SELECT 
        DISTINCT CAST(bdsajlt.TimeStamp AS DATE) AS JourneyDate, /* Remove duplicate action rows from journey*/
        SPLIT(bdsajlt.Journey_Name, '_')[0] AS CampaignNumber,
        bdsajlt.Journey_Name,
        bdsajlt.GCID,
        bdsajlt.Action,     
        bdsajlt.Message
FROM main.sfmc.silver_sfmc_accountjourneylogtracking bdsajlt

WHERE bdsajlt.Journey_Name LIKE '202405010123%'
ORDER BY bdsajlt.GCID, bdsajlt.Journey_Name