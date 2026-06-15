SELECT DISTINCT
	a.AffiliateID,
	CASE WHEN a.AccountActivated = 1 THEN 'Active' ELSE 'Inactive' END AS Status,
	a.TradingAccount_RealCID,
CASE WHEN exch.MarketingExpenseName='Networks' THEN  'Networks' ELSE a.SubChannel END SubChannelUpdate,

	COUNT(DISTINCT CASE  
		WHEN fd.DesignatedRegulationID = 1   
			AND DATEDIFF(DAY, CAST(fd.FirstDepositDate AS DATE), GETDATE()) <= 183  
		THEN fd.CID
	END) AS TotalFTDsEUlast365days,  

	COUNT(DISTINCT CASE  
		WHEN fd.DesignatedRegulationID = 1   
			and fd.VerificationLevel3Date is NOT NULL
			AND DATEDIFF(DAY, CAST(fd.registered AS DATE), GETDATE()) <= 183  
		THEN fd.CID 
	END) AS TotalRegistrationsEUlast365days
	

FROM DWH_dbo.Dim_Affiliate a
LEFT JOIN BI_DB_dbo.BI_DB_CIDFirstDates fd 
	ON fd.SerialID = a.AffiliateID
LEFT JOIN DWH_dbo.Ext_Dim_Channel exch ON a.AffiliateID = exch.AffiliateID 
WHERE	fd.Channel = 'Affiliate'
GROUP BY 
	a.AffiliateID,
	CASE WHEN a.AccountActivated = 1 THEN 'Active' ELSE 'Inactive' END,
	a.TradingAccount_RealCID,
	CASE WHEN exch.MarketingExpenseName='Networks' THEN  'Networks' ELSE a.SubChannel end