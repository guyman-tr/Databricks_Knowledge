SELECT da.AffiliateID, 
       CAST(da.DateCreated AS DATE)DateCreated,
	   da.Contact, da.ContractName,
	   da.ContractType,
           dct.Name ContractTypeName,
	   da.AffiliatesGroupsName,
	   da.AccountActivated, 
	   da.TradingAccount_RealCID, 
	   da.TradingAccount_UserName, 
	   da.Email, 
	   da.GCID, 
	   da.Channel,
	   da.SubChannel,
	   dc.Name Country,
	   dc.MarketingRegionManualName Region
FROM DWH_dbo.Dim_Affiliate da
JOIN DWH_dbo.Dim_Country dc ON da.CountryID = dc.CountryID
JOIN DWH_dbo.Dim_ContractType dct ON da.ContractType=dct.ContractTypeID