SELECT fd.CID
      ,l.Rev_14d Revenue14days
      ,l.Rev_30d Revenue30days
		,l.Revenue180days_LTV
		,l.Revenue360days_LTV
		,l.Revenue3Y_LTV
		,l.Revenue8Y_LTV
		,l.DaysFromDeposit
      ,fd.SubAffiliateID
		,fd.SerialID AS AffiliateID
		,fd.Channel
		,fd.SubChannel
		,fd.State
		,fd.Country
		,fd.FirstDepositDate
		,fd.FunnelFromName
		,fd.FunnelName
		,fd.FirstDepositAmount
		,fd.registered AS RegistrationDate
		,fd.Club AS CurrentClub
	        ,bdfa.FirstAction
		,bdfa.FirstInstrument
		,bdfa.FirstCross
                ,da.Contact
FROM BI_DB..BI_DB_CIDFirstDates fd 
JOIN BI_DB..BI_DB_LTV_BI_Actual l ON fd.CID = l.CID
JOIN BI_DB..BI_DB_First5Actions bdfa ON fd.CID = bdfa.CID
JOIN DWH.dbo.Dim_Affiliate da ON da.AffiliateID = fd.SerialID
WHERE fd.Region = 'USA'
AND bdfa.FirstDepositDate >= '20190201'