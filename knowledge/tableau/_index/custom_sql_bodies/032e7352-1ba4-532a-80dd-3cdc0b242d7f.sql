SELECT dc.AffiliateID,
       dc.RealCID,
	   dc2.Name User_Country,
	   dc2.MarketingRegionManualName User_Region,
	   dc3.Name Affiliate_Country,
	   dc3.MarketingRegionManualName Affiliate_Region,
	   da.Channel,
	   da.SubChannel,
	   da.AffiliatesGroupsName,
	   da.Contact,
	   da.ContractName,
	   da.AccountActivated,
	   da.LoginName AffLoginName,
	   da.TradingAccount_RealCID,
	   da.TradingAccount_UserName,
	   da.Email,
	   da.CompanyAddress,
	   da.City,
	   da.WebSiteURL,
	   RIGHT(da.WebSiteURL,CHARINDEX('.',REVERSE(da.WebSiteURL))) URL_Extension,
	   da.WebSiteTitle,
	   da.EntityName,
	   da.ContactPersonFullName,
	   da.Telephone,
	   CAST(dc.RegisteredReal AS DATE) RegDate,
	   CASE WHEN YEAR(dc.FirstDepositDate)>=2000 THEN CAST(dc.FirstDepositDate AS DATE) END FTD_Date,
	   CASE WHEN YEAR(dc.FirstDepositDate)>=2000 THEN 1 END IsFTD
FROM DWH_dbo.Dim_Customer dc
JOIN DWH_dbo.Dim_Channel dc1 ON dc.SubChannelID = dc1.SubChannelID
JOIN DWH_dbo.Dim_Country dc2 ON dc.CountryID = dc2.CountryID
JOIN DWH_dbo.Dim_Affiliate da ON dc.AffiliateID = da.AffiliateID
JOIN DWH_dbo.Dim_Country dc3 ON da.CountryID = dc3.CountryID 
WHERE YEAR(dc.RegisteredReal)>=2020
AND dc.IsValidCustomer=1