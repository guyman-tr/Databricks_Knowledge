SELECT bdwpr.*, dc.GCID
FROM BI_DB_dbo.BI_DB_Wire_PIP_Report bdwpr
join DWH_dbo.Dim_Customer dc on dc.RealCID=bdwpr.CID
WHERE --bdwpr.[eMoney Supported]=0
--AND bdwpr.MarketingRegionManualName IN ('Arabic','Australia','CEE','Latam','ROW','SEA')
bdwpr.AccountType='Private'
AND bdwpr.Club<>'Internal'
AND bdwpr.PaymentDate between <[Parameters].[Parameter 1]> and <[Parameters].[Parameter 2]>
AND dc.PlayerStatusID NOT IN (2,4,13)
UNION ALL
SELECT bdwpr.*, dc.GCID
FROM BI_DB_dbo.BI_DB_Wire_PIP_Report bdwpr
join DWH_dbo.Dim_Customer dc on dc.RealCID=bdwpr.CID
WHERE bdwpr.AccountType IN ('Corporate')
AND bdwpr.PaymentDate between <[Parameters].[Parameter 1]> and <[Parameters].[Parameter 2]>
AND bdwpr.Club<>'Internal'
AND dc.PlayerStatusID NOT IN (2,4,13)