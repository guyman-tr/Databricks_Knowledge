--new
select  
COUNT(DISTINCT a.GCID)GCID
, a.Country
, a.Regulation
, a.FullDate
, m.NewUserMonthEnd
,CASE
		WHEN 
			a.IsTestAccount=1     THEN 'TestUser'
		When a.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS IsRealUser
from 
(SELECT 
 efb.GCID
,efb.FullDate
 , dc1.Name AS Country
, dc1.Region
, p.Name as 'Club'
,dr.Name AS Regulation
, dc.IsTestAccount
, dc.IsValidCustomer
from EXW.dbo.EXW_FactBalance efb with (NOLOcK) 
JOIN DWH.dbo.Dim_Date dd on efb.FullDate = dd.FullDate 
	JOIN EXW.dbo.EXW_DimUser dc WITH (nolock) on dc.RealCID=efb.RealCID
join
(
SELECT fsc.RealCID AS CID, d.DateKey as DateID, fsc.CountryID, fsc.RegulationID, fsc.PlayerLevelID
FROM DWH..Fact_SnapshotCustomer fsc WITH (nolock)
	JOIN DWH..Dim_Range dr 		ON fsc.DateRangeID = dr.DateRangeID
	join DWH.dbo.Dim_Date d 	   on d.DateKey between FromDateID and ToDateID
WHERE 1=1 
	--AND fsc.CountryID = 79
	) b
	on  efb.RealCID =b.CID and efb.FullDateID = b.DateID
	JOIN DWH.dbo.Dim_Country dc1 ON b.CountryID=dc1.CountryID
	JOIN DWH.dbo.Dim_Regulation dr ON b.RegulationID =dr.DWHRegulationID
	join [DWH].[dbo].[Dim_PlayerLevel] p WITH (nolock) on b.PlayerLevelID = p.PlayerLevelID
	
	WHERE  1=1
and dd.DateKey >=  CAST(CONVERT(VARCHAR(8),  DATEADD(Month,-4, getdate()), 112) AS INT)
AND ( dd.IsLastDayOfMonth='Y' or dd.FullDate  =cast(getdate()  as date))
)a
JOIN
--select m.GCID, m.NewUserMonthEnd from 
(SELECT efb.GCID, EOMONTH( min(efb.FullDate)) as NewUserMonthEnd
FROM EXW.dbo.EXW_FactBalance efb with (NOLOcK) 
where efb.GCID>0
group by efb.GCID) m 
ON m.GCID =a.GCID and  m.NewUserMonthEnd=EOMONTH(a.FullDate ) 

GROUP BY 
a.Country
, a.Regulation
, a.FullDate
, m.NewUserMonthEnd
,CASE
		WHEN 
			a.IsTestAccount=1     THEN 'TestUser'
		When a.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END