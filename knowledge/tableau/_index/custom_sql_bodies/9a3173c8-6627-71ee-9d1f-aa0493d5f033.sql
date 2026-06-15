SELECT  f.ActiveDate
,f.Country
, f.EOM_Club club_customequery1
,COUNT(DISTINCT dm.CID) Active_Copy
,COUNT(DISTINCT(CASE WHEN dm.MirrorTypeID IN (1, 2) THEN dm.CID END )) Active_CopyTrading
,COUNT (DISTINCT(CASE WHEN dm.MirrorTypeID = 4 THEN dm.CID END )) Active_CopyPortfolio
FROM DWH_dbo.Dim_Mirror dm
INNER JOIN [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] f
ON dm.CID = f.CID
INNER JOIN DWH_dbo.Dim_MirrorType dmt
ON dm.MirrorTypeID = dmt.MirrorTypeID
WHERE  f.ActiveDate BETWEEN dateADD(MONTH,-13,GETDATE()) and  dateADD(MONTH,-1,GETDATE())   
AND dm.OpenOccurred<DATEADD(MONTH,1,f.ActiveDate)
	AND (CloseDateID=0 OR CloseDateID>= CAST(CONVERT(VARCHAR(8),f.ActiveDate, 112) AS INT))
	GROUP BY f.ActiveDate
	,f.Country
,f.EOM_Club