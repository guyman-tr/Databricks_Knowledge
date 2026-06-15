SELECT fm.CID
	  ,fm.Active_Month
	  ,fm.FTDdate
	  ,fm.FTDA
	  ,fm.NewMarketingRegion
	  ,fm.ClusterDetail
	  ,fm.IsEOM_Funded_NEW
	  ,CASE WHEN LEAD(fm.IsFunded_New) OVER (PARTITION BY fm.CID ORDER BY fm.ActiveDate) = 0 
	  AND fm.IsFunded_New = 1 THEN 1 ELSE 0 END IsChurn
FROM [BI_DB].[dbo].[BI_DB_CID_MonthlyPanel_FullData] fm WITH (NOLOCK)
WHERE fm.ActiveDate >='2020-10-01'