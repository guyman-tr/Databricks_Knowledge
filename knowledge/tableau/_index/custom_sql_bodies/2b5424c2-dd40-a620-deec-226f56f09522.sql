SELECT fca.DateID
	, dr1.Name AS Regulation
  ,	di.InstrumentDisplayName
  , di.InstrumentID
  , di.ISINCode
  , di.ISINCountryCode
  , dp.HedgeServerID
  , SUM (dp.InitialAmountCents)/100 AS ApproxVolume
  , SUM (fca.Amount) AS SDRTPaid
  , COUNT (dp.PositionID) AS CountPositions
  , (SUM (fca.Amount) / (SUM (dp.InitialAmountCents)/100)) * 100 AS ApproxSDRTPercent
FROM DWH_dbo.Fact_CustomerAction fca
	JOIN DWH_dbo.Dim_Position dp
		ON fca.PositionID = dp.PositionID
	JOIN DWH_dbo.Dim_Instrument di
		ON dp.InstrumentID = di.InstrumentID
	JOIN DWH_dbo.Fact_SnapshotCustomer fsc
		ON fca.RealCID = fsc.RealCID
	JOIN DWH_dbo.Dim_Range dr
		ON fsc.DateRangeID = dr.DateRangeID AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
	JOIN DWH_dbo.Dim_Regulation dr1
		ON fsc.RegulationID = dr1.DWHRegulationID
WHERE fca.DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
AND fca.ActionTypeID = 35
AND fca.IsFeeDividend = 3
AND fsc.IsCreditReportValidCB = 1
--AND left(di.ISINCode,2) <> 'GB'
--AND di.InstrumentID IN (2775,2601)
GROUP BY DateID
	, dr1.Name
	, di.InstrumentDisplayName
	, di.ISINCode, di.InstrumentID
	, di.ISINCountryCode
	, dp.HedgeServerID