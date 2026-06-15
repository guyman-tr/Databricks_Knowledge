SELECT  f.ActiveDate
,COUNT(DISTINCT dm.CID) ActiveCopy
FROM DWH_dbo.Dim_Mirror dm
INNER JOIN [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] f
ON dm.CID = f.CID
INNER JOIN DWH_dbo.Dim_MirrorType dmt
ON dm.MirrorTypeID = dmt.MirrorTypeID
WHERE  f.ActiveDate  >='20220101' 
AND dm.OpenOccurred<DATEADD(MONTH,1,f.ActiveDate)
	AND (CloseDateID=0 OR CloseDateID>= CAST(CONVERT(VARCHAR(8),f.ActiveDate, 112) AS INT))
	GROUP BY f.ActiveDate