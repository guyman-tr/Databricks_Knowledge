SELECT CID
      ,a.Region
      ,DateID
	  ,Date
      ,DateFTC
      ,IsDowngrade
      ,MAX(FirstDateDowngrade) OVER (PARTITION BY CID) FirstDateDowngrade 
	  ,CASE WHEN MAX(FirstDateDowngrade) OVER (PARTITION BY CID) > a.DateID 
	  OR MAX(IsDowngrade) OVER (PARTITION BY CID) = 0 THEN 1 ELSE 0 END IsStillInClub
,CASE WHEN CONVERT(CHAR(8),DATEADD(MONTH,2,DateFTC),112) >= a.DateID THEN 0 ELSE 1 END Ind
from(
SELECT  dpc.CID
,CASE WHEN dc1.Name IN ('Netherlands','Netherlands Antilles') THEN 'Netherlands'
           WHEN dc1.Name IN ('Mexico') THEN 'Mexico'
           WHEN dc1.Name IN ('Romania') THEN 'Romania'
         WHEN dc1.Region IN ('ROE','Eastern Europe','North Europe') THEN 'Europe' 
         WHEN dc1.Region IN ('Africa','ROW','Israel','Russian') THEN 'ROW' 
         WHEN dc1.Region IN ('Arabic GCC','Arabic Other') THEN 'Arabic GCC & Other'
         WHEN dc1.Region IN ('China','Other Asia') THEN 'China & Other Asia'
         WHEN dc1.Region IN ('Spain') THEN 'Spanish' 
         WHEN dc1.Region IN ('South & Central America') THEN 'LATAM' ELSE dc1.Region END AS Region
, dpc.DateID, dpc.Date
,datefromparts(YEAR(dpc.FTCDate),MONTH(dpc.FTCDate), 1) DateFTC
,dpc.IsDowngrade
,MIN(dpc.DateID) OVER (PARTITION BY dpc.CID,dpc.IsDowngrade) FirstDateDowngrade
FROM BI_DB..BI_DB_CID_DailyPanel_Club dpc
JOIN DWH..Dim_Customer dc
ON dpc.CID = dc.RealCID
JOIN DWH..Dim_Country dc1
ON dc.CountryID = dc1.CountryID
WHERE EOMonth(Date) = Date AND datefromparts(YEAR(dpc.FTCDate),MONTH(dpc.FTCDate), 1) >= '20200101'
)a