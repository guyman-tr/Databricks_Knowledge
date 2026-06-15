select -- TOP 10 
cb.*, a.CBDailyCompType, dpl.Name AS PlayerLevel,a.IsApex
from BI_DB_dbo.BI_DB_Client_New_CompensationBreakdown cb with (nolock)
LEFT JOIN 
(	SELECT dcr.CompensationReasonID
	, Name AS CompensationReason
	, CASE WHEN dcr.CompensationReasonID NOT IN  (7,8,11,17,18,19,22,30,31,32,33,34,36,37,38,40,41,50,51,52) THEN 'IncludedInCBDailyComp' ELSE 'ExcludedFromCBDailyComp' END AS CBDailyCompType,
CASE WHEN dcr.CompensationReasonID IN (45,60,62,63,64,65,66,67,68,69,70,71,
72,75,76,78,79,81,82,83,84,85,86,87,88,
89,91,92,93,94,95,96,97,98,99,103,104,105,106,107) then 1 else 0 end as 'IsApex'
FROM DWH_dbo.Dim_CompensationReason dcr  with (nolock)
) a
ON cb.CompensationReasonID = a.CompensationReasonID
JOIN DWH_dbo.Fact_SnapshotCustomer fsc with (nolock)
	ON cb.CID = fsc.RealCID
JOIN DWH_dbo.Dim_Range dr with (nolock) 
	ON fsc.DateRangeID = dr.DateRangeID AND cb.DateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_PlayerLevel dpl with (nolock)
	ON fsc.PlayerLevelID = dpl.PlayerLevelID
where cb.DateID between 
CAST(CONVERT(VARCHAR(10), CAST(<[Parameters].[Parameter 1]> as DATE), 112) AS INT)
and 
CAST(CONVERT(VARCHAR(10), CAST(<[Parameters].[Parameter 2]> as DATE), 112) AS INT)