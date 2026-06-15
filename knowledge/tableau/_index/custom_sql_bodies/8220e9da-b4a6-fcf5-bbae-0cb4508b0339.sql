SELECT tt.ActiveDate
		,tt.NewMarketingRegion
		,SUM(tt.Upgraded) Upgraded
		,SUM(tt.BronzeCID) CID
FROM 
(SELECT mp.CID
		,mp.ActiveDate
		,mp.NewMarketingRegion
		,CASE WHEN mp.EOM_Club NOT LIKE '%Bronze%' AND ISNULL(mp1.EOM_Club,'Bronze') LIKE '%Bronze%' THEN 1 ELSE 0 END Upgraded
		,CASE WHEN ISNULL(mp1.EOM_Club,'Bronze')LIKE '%Bronze%' AND ISNULL(mp1.IsFunded_New,1) = 1  THEN 1 ELSE 0 END BronzeCID
FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData mp
LEFT JOIN BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData mp1
ON mp.CID = mp1.CID
AND mp.ActiveDate = DATEADD(mm,1,mp1.ActiveDate)
WHERE mp.ActiveDate >= '20220101') tt
GROUP BY tt.ActiveDate
		,tt.NewMarketingRegion