-- 9k Difference

SELECT
    bdppl.DateID
  , bdppl.IsBuy
  , fsc.RegulationID
  , dr1.Name AS Regulation
  , bdppl.Leverage
  , di1.InstrumentType
  , fsc.IsCreditReportValidCB
  , CASE WHEN fsc.RegulationID IN (6,7,8) THEN 1 ELSE 0 END AS IsUSRegulation
  , CASE WHEN bdppl.IsSettled = 1 THEN 'Real' ELSE 'CFD' END AS RealCFD
  , SUM (bdppl.NOP) AS NOP
  , SUM (CASE WHEN bdppl.IsBuy=1 THEN bdppl.NOP ELSE-1*bdppl.NOP END) AS Notional_NOP_Based
  , SUM (isnull(bdppl.Amount,0)) AS Notional_Inversted_Amount_Based
  , SUM (isnull(bdppl.PositionPnL,0)) AS PositionPnL
  , SUM (isnull(bdppl.Amount,0))+SUM (isnull(bdppl.PositionPnL,0)) AS Equity
  , dc.Name AS Country
  , sum(dp.FullCommission)  FullCommission
  , sum(bdppl.Commission) Commission
  , sum(isnull(dp.FullCommission,0)) - sum(isnull(bdppl.Commission,0)) AS Spread
  , sum(isnull(PositionPnL,0)) + sum(isnull(dp.FullCommission,0)) - sum(isnull(bdppl.Commission,0)) AS AdjustedPnLForRegulations
  , sum(isnull(dp.FullCommission,0)) + sum(isnull(PositionPnL,0)) AS Zero
  --, CASE WHEN vgbf.CID IS NOT NULL THEN 1 ELSE 0 END AS IsGermanBafin
 , di.IsFuture
 , sum(case WHEN bdppl.SettlementTypeID = 5 AND bdppl.Leverage <> 1 AND di.InstrumentTypeID IN (5,6) THEN bdppl.InitForexRate * bdppl.AmountInUnitsDecimal*bdppl.CurrentConversionRate - bdppl.Amount ELSE 0 end) AS TotalStockMarginLoan 
FROM BI_DB_dbo.BI_DB_PositionPnL bdppl
JOIN DWH_dbo.Dim_Position dp
	ON bdppl.PositionID = dp.PositionID
JOIN DWH_dbo.Dim_Instrument di
ON bdppl.InstrumentID=di.InstrumentID
JOIN DWH_dbo.Fact_SnapshotCustomer fsc
ON fsc.RealCID=bdppl.CID
JOIN DWH_dbo.Dim_Range dr
ON fsc.DateRangeID=dr.DateRangeID AND bdppl.DateID BETWEEN dr.FromDateID
   AND dr.ToDateID
JOIN DWH_dbo.Dim_Regulation dr1
ON dr1.DWHRegulationID=fsc.RegulationID
JOIN DWH_dbo.Dim_Instrument di1
ON bdppl.InstrumentID=di1.InstrumentID
JOIN DWH_dbo.Dim_Country dc
ON fsc.CountryID = dc.CountryID
--LEFT JOIN BI_DB_dbo.V_GermanBaFin vgbf
--ON bdppl.CID = vgbf.CID AND bdppl.DateID = vgbf.DateID
WHERE bdppl.DateID = CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
GROUP BY
bdppl.DateID
  , bdppl.IsBuy
  , fsc.RegulationID
  , dr1.Name
  , di1.InstrumentType
  , bdppl.Leverage
  , fsc.IsCreditReportValidCB
  , CASE WHEN fsc.RegulationID IN (6,7,8) THEN 1 ELSE 0 END
  , CASE WHEN bdppl.IsSettled = 1 THEN 'Real' ELSE 'CFD' END
  , dc.Name
  --, CASE WHEN vgbf.CID IS NOT NULL THEN 1 ELSE 0 END
, di.IsFuture