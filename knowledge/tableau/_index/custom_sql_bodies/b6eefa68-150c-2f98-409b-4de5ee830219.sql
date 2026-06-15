SELECT b.RealCID
	,b.PlayerStatus
	,b.Country
	,b.Region
	,b.Desk
	,MIN(dd.FullDate)FromDate
	--INTO #final
FROM( 
SELECT a.*
	   ,ROW_NUMBER()OVER(PARTITION BY RealCID ORDER BY  FromDateID desc)rnk
	   ,ROW_NUMBER()OVER(PARTITION BY RealCID,a.PlayerStatus ORDER BY  FromDateID )rnk_s
from(SELECT fsc.RealCID
,CASE WHEN dps.PlayerStatusID IN (1,5) THEN 'Normal' ELSE dps.Name END  PlayerStatus
,CASE WHEN fsc.PlayerStatusID NOT in (1,5) THEN 1 ELSE 0 END IsMIMOBlocked
,dr.FromDateID
,dr.ToDateID
,dc1.Name Country
,dc1.MarketingRegionManualName Region
,dc1.Desk
FROM DWH..Fact_SnapshotCustomer fsc
JOIN  DWH..Dim_Customer dc
	ON fsc.RealCID = dc.RealCID
	AND dc.PlayerStatusID = fsc.PlayerStatusID
JOIN DWH..Dim_PlayerStatus dps
	ON fsc.PlayerStatusID = dps.PlayerStatusID
JOIN DWH..Dim_Country dc1
	ON dc.CountryID = fsc.CountryID
JOIN DWH..Dim_Range dr
	ON fsc.DateRangeID = dr.DateRangeID
WHERE fsc.CountryID = 219 
AND dc.IsValidCustomer = 1
 ) AS a)AS b
 JOIN DWH..Dim_Date dd
	ON dd.DateKey = b.FromDateID
WHERE b.rnk = b.rnk_s
GROUP BY b.RealCID
	,b.PlayerStatus
	,b.Country
	,b.Region
	,b.Desk