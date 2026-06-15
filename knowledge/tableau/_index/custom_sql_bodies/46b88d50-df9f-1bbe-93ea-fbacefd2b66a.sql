SELECT fca.RealCID AS CID
	 ,SUM(fca.Amount) AS Total_Deposits
	 ,dft.Name AS MOP
	 ,dr.Name AS Regulation
,fca.ActionTypeID
,fca.DateID
FROM DWH_dbo.Fact_CustomerAction fca
JOIN DWH_dbo.Dim_Customer dc
ON fca.RealCID = dc.RealCID 
AND dc.IsDepositor = 1 
AND dc.IsValidCustomer =1
AND dc.RegulationID IN (1,2,4,7,8,9,10,11,13)
JOIN DWH_dbo.Dim_Regulation dr ON dr.DWHRegulationID = dc.RegulationID
JOIN DWH_dbo.Dim_FundingType dft ON fca.FundingTypeID = dft.FundingTypeID
WHERE fca.ActionTypeID IN (7,8) -- Deposit
-- AND dft.FundingTypeID IN (2,1,27,33)
AND fca.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
GROUP BY fca.RealCID ,dft.Name,fca.DateID,dr.Name,fca.ActionTypeID