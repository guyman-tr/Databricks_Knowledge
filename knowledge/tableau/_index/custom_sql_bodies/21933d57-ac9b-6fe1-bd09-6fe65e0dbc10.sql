SELECT DISTINCT 
COUNT(distinct fb.GCID) 'User Count'
,SUM(fb.BalanceUSD) BalanceUSD
, fb.FullDate
 , dc1.Name AS Country
, dc1.Region
,dr.Name AS Regulation
 ,CASE
		WHEN 
			dc.IsTestAccount=1     THEN 'TestUser'
		When dc.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS IsRealUser
from EXW.dbo.EXW_FactBalance fb  with (NOLOcK)
JOIN DWH.dbo.Dim_Date dd on  fb.FullDateID = dd.DateKey 
JOIN EXW.dbo.EXW_DimUser dc WITH (nolock) on dc.GCID= fb.GCID
join
(
SELECT fsc.RealCID AS CID, d.DateKey as DateID, fsc.CountryID, fsc.RegulationID, fsc.PlayerLevelID
FROM DWH..Fact_SnapshotCustomer fsc WITH (nolock)
	JOIN DWH..Dim_Range dr 		ON fsc.DateRangeID = dr.DateRangeID
	join DWH.dbo.Dim_Date d 	   on d.DateKey between FromDateID and ToDateID
WHERE 1=1 
	--AND fsc.CountryID = 79
	) b
	on  fb.RealCID =b.CID and fb.FullDateID = b.DateID
	JOIN DWH.dbo.Dim_Country dc1 ON b.CountryID=dc1.CountryID
	JOIN DWH.dbo.Dim_Regulation dr ON b.RegulationID =dr.DWHRegulationID
--	join [DWH].[dbo].[Dim_PlayerLevel] p WITH (nolock) on b.PlayerLevelID = p.PlayerLevelID
 	 Where dd.DateKey >=  CAST(CONVERT(VARCHAR(8),  DATEADD(Month,-4, getdate()), 112) AS INT)
AND  (dd.IsLastDayOfMonth='Y' or dd.DateKey  =CAST(CONVERT(VARCHAR(8),   getdate(), 112) AS INT))
and fb.GCID>0
GROUP BY 
fb.FullDate
 , dc1.Name  
, dc1.Region
,dr.Name  
 ,CASE
		WHEN 
			dc.IsTestAccount=1     THEN 'TestUser'
		When dc.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END