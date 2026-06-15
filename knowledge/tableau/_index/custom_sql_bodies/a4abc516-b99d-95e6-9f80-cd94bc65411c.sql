SELECT FORMAT(Occurred, 'MM-yyyy') AS [Month-Year],
COUNT(DISTINCT fca.GCID) AS UniqueLoggedInClients
FROM [DWH_dbo].[Fact_CustomerAction] fca 
JOIN [DWH_dbo].[Dim_Customer] dc
ON fca.RealCID = dc.RealCID
WHERE fca.Occurred >= '2025-01-01' 
AND fca.ActionTypeID = 14
AND dc.IsValidCustomer = 1
GROUP BY FORMAT(Occurred, 'MM-yyyy')