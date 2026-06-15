SELECT 
f.RealCID
,f.TransactionID
,f.Date as FirstDepositDate
,cast(dc.RegisteredReal as date) as RegisteredReal
,f.MIMOPlatform
,f.AmountUSD as FirstDepositAmount
,f.IsGlobalFTD 
,case when a.RealCID is NULL then 'No' else 'Yes' end as HasDepositInTrading
,r.Name as Regulation
,c.Name as Country
,e.ProviderHolderID as HolderID
from 
	BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms f
JOIN 
	DWH_dbo.Dim_Customer dc on dc.RealCID = f.RealCID
LEFT JOIN 
	DWH_dbo.Dim_Country c on c.CountryID = dc.CountryID
LEFT JOIN 
	DWH_dbo.Dim_Regulation r on r.ID = dc.RegulationID
LEFT JOIN 
	(Select DISTINCT e.CID,e.ProviderHolderID FROM eMoney_dbo.eMoney_Dim_Account e )e on e.CID = f.RealCID
LEFT JOIN 
	(Select DISTINCT 
		f.RealCID 
	 from 
		BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms f
	 WHERE 
		f.MIMOAction = 'Deposit'
		and f.MIMOPlatform = 'TradingPlatform'
		and f.IsPlatformFTD = 1
	) a on a.RealCID = f.RealCID

    WHERE
        f.MIMOAction = 'Deposit'
		and f.MIMOPlatform = 'eMoney'
        and f.IsGlobalFTD = 1
        --and f.IsPlatformFTD = 1
        --and f.RealCID = 45193908
		and dc.IsValidCustomer = 1