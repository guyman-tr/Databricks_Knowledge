SELECT closed_pos.CID,
CONVERT(date, convert(varchar(10), closed_pos.CloseDateID)) 'Date',
dc.Name 'Country',
dr1.Name 'Regulation',
fsc.IsCreditReportValidCB,
CASE WHEN dc1.TanganyStatusID=1 THEN 'Pending'
	WHEN dc1.TanganyStatusID=2 THEN 'Internal'
	WHEN dc1.TanganyStatusID=3 THEN 'Customer'END AS 'TanganyStatus',
closed_pos.[Amount Closed Positions],
comp.[Amount Compensation]


FROM 
(
SELECT dp.CID,CloseDateID,sum(isnull(dp.Amount,0)+isnull(dp.NetProfit,0)) 'Amount Closed Positions'
FROM DWH_dbo.Dim_Position dp
WHERE dp.CloseDateID>=CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT) and dp.CloseDateID<=CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
AND dp.ClosePositionReasonID=22
group BY dp.CID,CloseDateID
)closed_pos
join
(
SELECT fca.RealCID,
fca.DateID,
sum(fca.Amount) 'Amount Compensation'
FROM DWH_dbo.Fact_CustomerAction fca

WHERE fca.DateID>=CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
 and fca.DateID<=CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
AND fca.ActionTypeID=36 
AND fca.CompensationReasonID in (113,114)
GROUP BY fca.RealCID,
fca.DateID
)comp
ON closed_pos.CID=comp.RealCID AND comp.DateID=closed_pos.CloseDateID

JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON closed_pos.CID = fsc.RealCID
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND closed_pos.CloseDateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Country dc ON fsc.CountryID = dc.CountryID
JOIN DWH_dbo.Dim_Regulation dr1 ON fsc.RegulationID=dr1.DWHRegulationID
JOIN DWH_dbo.Dim_Customer dc1 ON fsc.RealCID = dc1.RealCID