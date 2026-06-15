--DECLARE @date DATE = cast (getdate()-1 as date)
--DECLARE @dateID int =CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)

SELECT  a.InstrumentID
	, a.InstrumentType
	, a.Name
	, a.InstrumentDisplayName
	, a.Symbol
	, a.ISINCode
	, a.CUSIP
	, a.DLTOpen
	, a.IsBuy
	, a.IsSettled
	, a.DateID
	, dc.Name AS Country
	, dr1.Name AS Regulation
	, fsc.IsValidCustomer
	, fsc.IsCreditReportValidCB
	, sum(a.InitialAmountInvested	) as InitialAmountInvested
	, sum(a.InitialUnitsInvested	) as InitialUnitsInvested
	, sum(a.VolumeOpen		) as VolumeOpen
 --        , sum(DimPosVolume              ) as DimPosVolume
	, sum(a.EstimateCloseFeeOnOpen	) as EstimateCloseFeeOnOpen
FROM 
(
SELECT dp.CID
	, dp.InstrumentID
	, di.InstrumentType
	, di.Name
	, di.InstrumentDisplayName
	, di.Symbol
	, di.ISINCode
	, di.CUSIP
	, dp.DLTOpen
	, dp.IsBuy
	, dp.IsSettled
	, dp.OpenDateID AS DateID
	, sum(dp.InitialAmountCents/100) AS InitialAmountInvested
	, sum(dp.InitialUnits) AS InitialUnitsInvested
	, SUM(dp.InitialUnits * dp.InitForexRate * ISNULL(dp.InitConversionRate,1)) AS VolumeOpen
  --       , sum(Volume) as DimPosVolume
	, SUM(bdppl.EstimateCloseFeeOnOpen) AS EstimateCloseFeeOnOpen
FROM DWH_dbo.Dim_Position dp
	LEFT JOIN BI_DB_dbo.BI_DB_PositionPnL bdppl
		ON dp.PositionID = bdppl.PositionID AND bdppl.DateID = CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT) 
	JOIN DWH_dbo.Dim_Instrument di
		ON dp.InstrumentID = di.InstrumentID 
			AND di.Tradable = 1
			AND di.Symbol NOT LIKE '%Drm.Crypto%'
			AND NOT di.IsFuture = 1 
			AND NOT (di.InstrumentTypeID IN (5,6) AND dp.IsSettled = 1)
WHERE dp.OpenDateID = CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT) 
and isnull(dp.IsPartialCloseChild,0) = 0
GROUP BY dp.CID
	, dp.InstrumentID
	, di.InstrumentType
	, di.Name
	, di.InstrumentDisplayName
	, di.Symbol
	, di.ISINCode
	, di.CUSIP
	, dp.DLTOpen
	, dp.IsBuy
	, dp.IsSettled
	, dp.OpenDateID 
) a 
	JOIN DWH_dbo.Fact_SnapshotCustomer fsc
		ON a.CID = fsc.RealCID
	JOIN DWH_dbo.Dim_Range dr
		ON fsc.DateRangeID = dr.DateRangeID AND CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)  BETWEEN dr.FromDateID AND dr.ToDateID
	JOIN DWH_dbo.Dim_Regulation dr1
		ON fsc.RegulationID = dr1.DWHRegulationID
	JOIN DWH_dbo.Dim_Country dc
		ON fsc.CountryID = dc.CountryID 
GROUP BY 
	a.InstrumentID
	, a.InstrumentType
	, a.Name
	, a.InstrumentDisplayName
	, a.Symbol
	, a.ISINCode
	, a.CUSIP
	, a.DLTOpen
	, a.IsBuy
	, a.IsSettled
	, a.DateID
	, dc.Name 
	, dr1.Name
	, fsc.IsValidCustomer
	, fsc.IsCreditReportValidCB