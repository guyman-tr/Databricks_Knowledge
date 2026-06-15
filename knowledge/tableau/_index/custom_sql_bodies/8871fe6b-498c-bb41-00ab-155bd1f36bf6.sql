SELECT 'Buy' AS Action, fca.DateID, fca.IsSettled, case when IsSettled = 1 then 'Real' else 'CFD' end as Real_CFD, di.InstrumentType,  di.IsFuture, dc.Name AS Country, dr1.Name AS Regulation, sum(fca.Amount) AS AmountUSD
FROM DWH_dbo.Fact_CustomerAction fca
	JOIN DWH_dbo.Fact_SnapshotCustomer fsc
		ON fca.RealCID = fsc.RealCID
	JOIN DWH_dbo.Dim_Range dr
		ON fsc.DateRangeID = dr.DateRangeID AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
	JOIN DWH_dbo.Dim_Instrument di
		ON fca.InstrumentID = di.InstrumentID
	JOIN DWH_dbo.Dim_Country dc
		ON fsc.CountryID = dc.CountryID
	JOIN DWH_dbo.Dim_Regulation dr1
		ON fsc.RegulationID = dr1.DWHRegulationID
WHERE fca.DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT) AND  CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
AND fca.ActionTypeID IN (1,2,3,39)
GROUP BY di.InstrumentType,  di.IsFuture, dc.Name,dr1.Name, fca.DateID,fca.IsSettled, case when IsSettled = 1 then 'Real' else 'CFD' end 
UNION ALL 
SELECT 'Sell' AS Action, fca.DateID, fca.IsSettled, case when IsSettled = 1 then 'Real' else 'CFD' end as Real_CFD, di.InstrumentType,  di.IsFuture, dc.Name AS Country, dr1.Name AS Regulation, sum(fca.Amount + fca.NetProfit) AS AmountUSD
FROM DWH_dbo.Fact_CustomerAction fca
	JOIN DWH_dbo.Fact_SnapshotCustomer fsc
		ON fca.RealCID = fsc.RealCID
	JOIN DWH_dbo.Dim_Range dr
		ON fsc.DateRangeID = dr.DateRangeID AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
	JOIN DWH_dbo.Dim_Instrument di
		ON fca.InstrumentID = di.InstrumentID
	JOIN DWH_dbo.Dim_Country dc
		ON fsc.CountryID = dc.CountryID
	JOIN DWH_dbo.Dim_Regulation dr1
		ON fsc.RegulationID = dr1.DWHRegulationID
WHERE fca.DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT) AND  CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
AND fca.ActionTypeID IN (4,5,6,28,40)
GROUP BY di.InstrumentType, di.IsFuture, dc.Name,dr1.Name, fca.DateID,fca.IsSettled, case when IsSettled = 1 then 'Real' else 'CFD' end