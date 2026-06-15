SELECT  
T.*, 
da.Contact, 
bdlp.LTV_8Y_VolFix, 
bdlp.LTV_8Y_GroupLevel, 
dc1.MarketingRegionManualName,
CASE WHEN T.Registration = 1 AND T.FTD = 1 THEN 1 ELSE 0 END RegFTD_sameDay

FROM  BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints T
JOIN DWH_dbo.Dim_Customer dc 
ON dc.RealCID = T.CID

JOIN DWH_dbo.Dim_Country dc1 
ON dc.CountryID = dc1.CountryID

LEFT JOIN BI_DB_dbo.BI_DB_LTV_Predictions bdlp
ON dc.RealCID = bdlp.RealCID

left join DWH_dbo.Dim_Affiliate as da 
on da.AffiliateID = T.AffiliateID

WHERE  Date >= DATEADD( MONTH,-13,GETDATE())
AND Date < DATEADD( MONTH,0,GETDATE())
AND dc.IsValidCustomer = 1