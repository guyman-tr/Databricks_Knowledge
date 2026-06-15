SELECT  dd.CalendarYearMonth
     ,dp.CID
     ,SUM(FullCommission) Revenue
FROM [DWH].[dbo].[Dim_Position] dp WITH (NOLOCK)
INNER JOIN DWH.dbo.Dim_Date dd WITH (NOLOCK)
ON dd.DateKey = dp.CloseDateID
INNER JOIN [DWH].[dbo].[Dim_Customer] dc WITH (NOLOCK)
ON dp.CID = dc.RealCID
WHERE dp.CloseDateID >=20221101
AND dc.RegulationID = 9
AND dc.IsValidCustomer = 1
GROUP BY dd.CalendarYearMonth
     ,dp.CID
HAVING SUM(FullCommissionOnClose) >=5000