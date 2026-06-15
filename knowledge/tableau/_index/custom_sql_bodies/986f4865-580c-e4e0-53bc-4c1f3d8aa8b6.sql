SELECT pos.Date AS 'Date'
,IsLastDayOfMonth
, 'Data1 Client Data' AS datasource
, SUM(AmountInUnitsDecimal) AS AmountInUnitsDecimal
, SUM(NOP) AS NOP
, SUM(Amount) AS Amount
, SUM(PositionPnL) AS PositionPnL
, SUM(ISNULL(Amount, 0) + ISNULL(PositionPnL, 0)) AS Equity
, COUNT(DISTINCT CID) AS ClientCount
from --#posFCA
(
SELECT bdppl.*, di.ISINCode, di.InstrumentDisplayName,IsLastDayOfMonth
FROM BI_DB_dbo.BI_DB_PositionPnL bdppl
	JOIN DWH_dbo.Dim_Instrument di
		ON bdppl.InstrumentID = di.InstrumentID AND di.InstrumentTypeID IN (5,6)
 join DWH_dbo.Dim_Date dd on bdppl.DateID=dd.DateKey
WHERE --DateID IN (SELECT dd.DateKey FROM DWH_dbo.Dim_Date dd WHERE /*dd.IsLastDayOfMonth='Y' AND*/ dd.FullDate>='2023-01-01')
/*AND*/ bdppl.IsSettled = 1
and DateID between CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT) 
and CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT)
)pos
JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON fsc.RealCID=pos.CID
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND pos.DateID BETWEEN dr.FromDateID AND dr.ToDateID

WHERE  fsc.RegulationID = 2 AND fsc.IsCreditReportValidCB = 1 AND fsc.IsValidCustomer = 1
GROUP BY pos.Date,IsLastDayOfMonth