SELECT q0.DateID
	  ,q0.Date
	  ,q0.CID
	  ,q0.CreatedDate
	  ,q0.LogID
	  ,q0.RegulationAtOpen
	  ,q0.ClubTierAtOpen
	  ,q0.Desk
	  ,q0.SubType
	  ,q0.SubType2
	  ,q0.ActionType
	  ,q0.LastCsat
	  ,q0.FirstCsat
	  ,q0.ClusterDetail
	  ,q0.NewMarketingRegion Region
	  ,q0.CategoriesBCG
FROM
(
SELECT sfc.DateID
	  ,sfc.Date
	  ,sfc.CID
	  ,sfc.CreatedDate
	  ,sfc.LogID
	  ,sfc.RegulationAtOpen
	  ,sfc.ClubTierAtOpen
	  ,sfc.Desk
	  ,sfc.SubType
	  ,sfc.SubType2
	  ,sfc.ActionType
	  ,sfc.LastCsat
	  ,sfc.FirstCsat
	  ,cls.ClusterDetail
	  ,ROW_NUMBER() OVER (PARTITION BY sfc.LogID ORDER BY sfc.Date DESC) rn
	  ,CASE WHEN sfc.ActionType IN ('Marketing tools','Technical issues - Partners dashboard','Partner Compliance'
           ,'Commissions / payments','eToro Programs','Tracking') THEN 'Affiliates'
            WHEN sfc.ActionType = 'AML' THEN 'AML'
	        WHEN sfc.ActionType IN ('Deposits','Deposit') THEN 'MI'
			WHEN sfc.ActionType IN ('Withdrawal') THEN 'MO'
			WHEN sfc.ActionType IN ('Card issues','Unrecognised transaction','Payments in','Unrecognized transaction','Verification','Other Transactions','Dispute Transaction','Payments out')
			THEN 'MoneyCard'
			WHEN sfc.ActionType = 'OPS' THEN 'OPS'
			WHEN sfc.ActionType IN ('Account Verification','KYC','Account Details') THEN 'Onboarding'
			WHEN sfc.ActionType IN ('Transfer') THEN 'Redeem'
			WHEN sfc.ActionType IN ('General Technical Issue','Platform Issues') THEN 'Technical'
			WHEN sfc.ActionType IN ('Risk','Chargeback','Security') THEN 'Risk Alerts'
			WHEN sfc.ActionType IN ('Trading') THEN 'Trading'
			WHEN sfc.ActionType IN ('Transactions','Simplex','Wallet','Use of Wallet','Account inquiries','Crypto to Fiat') THEN 'Wallet'
			WHEN sfc.ActionType IN ('Other','Suggestions','Making a suggestion','Security','New eToro','NULL','General Question','General Questions'
			,'General information','Privacy','Make a suggestion','General','eToro Clubs','Account statement','Law enforcement inquiries','How To'
			,'Requests','Bonuses and Promotions') THEN 'Others'END CategoriesBCG
			,fd.NewMarketingRegion
FROM [BI_DB].[dbo].[BI_DB_SF_Cases] sfc WITH (NOLOCK)
LEFT JOIN BI_DB.dbo.BI_DB_CID_DailyCluster cls WITH (NOLOCK)
ON sfc.CID = cls.CID
AND cls.FromDate <=sfc.CreatedDate
AND cls.ToDate >=sfc.CreatedDate
LEFT JOIN [BI_DB].[dbo].[BI_DB_CIDFirstDates] fd WITH (NOLOCK)
ON sfc.CID = fd.CID
WHERE sfc.TicketStatus = 'Solved'
AND sfc.Source != 'Email'
AND sfc.CreatedDate >='2021-01-01'
)q0
WHERE q0.rn = 1