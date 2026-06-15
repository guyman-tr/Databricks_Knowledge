SELECT b.*,
	  CASE WHEN DATEDIFF(HOUR,b.BlockedTime,GETDATE())<=24 THEN 'Under 24h'
		WHEN DATEDIFF(HOUR,b.BlockedTime,GETDATE())<=48 THEN 'Under 48h'
		WHEN  DATEDIFF(DAY,b.BlockedTime,GETDATE())<=5 THEN '5 days'
		WHEN  DATEDIFF(DAY,b.BlockedTime,GETDATE())<=10 THEN '10 days'
		WHEN  DATEDIFF(DAY,b.BlockedTime,GETDATE())<=15 THEN '15 days'
		WHEN  DATEDIFF(month,b.BlockedTime,GETDATE())<=1 THEN '1 month'
		WHEN  DATEDIFF(month,b.BlockedTime,GETDATE())<=2 THEN '2 months'
		ELSE 'Over 2 Months' END AS TimeBucket
	   ,cs.CountTickets
	   ,cs.FirstDateOpenTicket
	   ,cs.LastDateOpenTicket
from(SELECT 
	act.CID
	,act.Country
	,act.Region
	,act.Desk
	,act.LastLoggedIn
	,act.Regulation
	,act.Balance
	,act.TotalEquity
	,MIN(dd.FullDate) AS BlockedTime
   ,dps.Name PlayerStatus
   ,dps.CanRequestWithdraw
FROM (SELECT 
	fd.CID,
	dc1.Name Country,
	dc1.Region,
	dc1.Desk,
	fd.LastLoggedIn,
	regulation.Name AS Regulation,
	vl.Credit  AS Balance,
	vl.Liabilities + vl.ActualNWA AS TotalEquity,
	dc.PlayerStatusID
FROM BI_DB.[dbo].[BI_DB_CIDFirstDates] fd
JOIN DWH.dbo.Dim_Customer dc ON dc.RealCID=fd.CID
JOIN DWH..Dim_Country dc1 ON fd.CountryID = dc1.CountryID
join DWH.dbo.V_Liabilities vl on vl.CID=fd.CID and vl.DateID = CAST(CONVERT(VARCHAR(8),getdate()-1,112)AS int)
join DWH.dbo.Dim_Regulation regulation on regulation.ID=dc.RegulationID
WHERE DATEADD(MONTH, -12, GETDATE())<=LastLoggedIn
AND dc.IsValidCustomer=1
AND dc.IsDepositor=1
AND dc.CountryID = 219
AND (vl.Credit>0 OR vl.Liabilities + vl.ActualNWA>0)) AS act
JOIN DWH.dbo.Fact_SnapshotCustomer fsc ON fsc.RealCID=act.CID AND fsc.PlayerStatusID=act.PlayerStatusID
JOIN DWH..Dim_Range dr ON fsc.DateRangeID=dr.DateRangeID
JOIN DWH..Dim_Date dd ON dd.DateKey = dr.FromDateID
JOIN DWH..Dim_PlayerStatus dps ON dps.PlayerStatusID = fsc.PlayerStatusID
WHERE dps.Name NOT IN ('Normal','Warning')
GROUP BY act.CID
	    ,act.Country
		,act.Region
		,act.Desk
		,act.LastLoggedIn
		,act.Regulation
		,act.Balance
		,act.TotalEquity
		,dps.Name
		,dps.CanRequestWithdraw
)AS b
LEFT JOIN (SELECT cf.CID
	      ,COUNT(cf.TicketID)CountTickets
	      ,MIN(cf.CreatedDate)FirstDateOpenTicket
		  ,MAX(cf.CreatedDate)LastDateOpenTicket
	FROM BI_DB.[dbo].[BI_DB_SF_Cases] cf 
	JOIN DWH..Dim_Customer dc
		ON cf.CID = dc.RealCID
	WHERE cf.Phase = 'Phase 2'
	AND dc.CountryID=219
	GROUP BY cf.CID) cs
ON b.CID = cs.CID