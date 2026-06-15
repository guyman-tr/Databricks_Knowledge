SELECT cp.*,ROW_NUMBER() OVER (PARTITION BY CID ,dd.CalendarYearMonth ORDER BY cp.DateID DESC) rn 
FROM [BI_DB_dbo].[BI_DB_CID_DailyPanel_Club] cp WITH (NOLOCK)
INNER JOIN DWH_dbo.Dim_Date dd WITH (NOLOCK)
ON cp.DateID = dd.DateKey
WHERE cp.IsUpgrade = 1
AND cp.DateID >=20230101