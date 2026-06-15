SELECT	bdfa.CID
		,dc.Gender
                ,bdfa.FirstDepositDate
		,bdfa.FirstAction
		,bdfa.FirstCross
		,bdfa.SecondCross
		,DATEDIFF(DAY,bdfa.FirstActionDate,bdfa.FirstCrossDate)FirstTimeCross
		,bdfa.Revenue14days
		,bdfa.Revenue30days
		,bdfa.Revenue60days
		,bdfa.Revenue90days
		,bdfa.Revenue180days
		,bdfa.Revenue360days
FROM BI_DB.dbo.BI_DB_First5Actions bdfa
JOIN DWH.dbo.Dim_Customer dc 
ON bdfa.CID = dc.RealCID
WHERE dc.IsValidCustomer = 1
AND dc.Gender IS NOT NULL