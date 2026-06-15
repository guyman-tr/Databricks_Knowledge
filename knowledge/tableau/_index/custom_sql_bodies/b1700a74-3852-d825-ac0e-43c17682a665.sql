SELECT ac.RealCID AS CID,
	cust.Country,
	cust.Club,
	CONVERT(VARCHAR(6), ac.Occurred, 112) AS BonusYearMonth,
    SUM(ac.Amount) AS [Total Compensation (USD)],
	ac.Description,
	ac.CompensationReasonID,
	dcr.Name AS CompensationReason,
	dps.Name PlayerStatus,
	dpsr.Name AS PlayerStatusReasons,
	dpssr.PlayerStatusSubReasonName
FROM DWH_dbo.Fact_CustomerAction AS ac
LEFT JOIN DWH_dbo.Dim_CompensationReason dcr ON ac.CompensationReasonID = dcr.CompensationReasonID
LEFT JOIN BI_DB_dbo.BI_DB_CIDFirstDates cust ON ac.RealCID = cust.CID
LEFT JOIN DWH_dbo.Dim_Customer dc ON ac.RealCID =dc.RealCID
LEFT JOIN DWH_dbo.Dim_PlayerStatus dps ON dc.PlayerStatusID = dps.PlayerStatusID
LEFT JOIN DWH_dbo.Dim_PlayerStatusReasons dpsr ON dc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
LEFT JOIN DWH_dbo.Dim_PlayerStatusSubReasons dpssr ON dc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID
WHERE 
    ac.ActionTypeID = 36 
    AND ac.Occurred >= '20260301'
	AND (dcr.Name LIKE '%Friend%' OR dcr.Name LIKE '%Special Promotion%')
	GROUP BY ac.RealCID,ac.Description,dcr.Name,CONVERT(VARCHAR(6), ac.Occurred, 112)
	,ac.CompensationReasonID,cust.Country,dps.Name,dpsr.Name,dpssr.PlayerStatusSubReasonName,cust.Club