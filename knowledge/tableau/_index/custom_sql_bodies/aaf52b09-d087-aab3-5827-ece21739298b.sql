SELECT da.DateCreated,
    da.AffiliateID,
    da.TradingAccount_RealCID,
    dc.GCID GCID,
	dat.Name AccountType
FROM DWH_dbo.Dim_Affiliate da 
	LEFT JOIN DWH_dbo.Dim_Customer dc 
	ON da.TradingAccount_RealCID = dc.RealCID
	LEFT JOIN DWH_dbo.Dim_AccountType dat
	ON dc.AccountTypeID = dat.AccountTypeID
WHERE DateCreated >= '2019-01-01'