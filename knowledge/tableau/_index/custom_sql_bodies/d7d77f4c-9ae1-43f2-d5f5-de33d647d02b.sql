SELECT 
	pos.Date
   ,pos.CID
   ,pos.ISINCode
   ,pos.InstrumentDisplayName
   ,pos.HedgeServerID
   ,pos.Units
   ,pos.[Value]
   ,pos.[Price Per Unit]
   ,FLOOR(pos.[Units to be transfered])'Units to be transfered'
   ,sum(FLOOR(pos.[Units to be transfered])*pos.[Price Per Unit]/*pos.[Value of units to be transfered]*/)'Value of units to be transfered'
   ,fsc.IsCreditReportValidCB
   ,sum(FLOOR(pos.[Units to be transfered])*pos.[Price Per Unit]/*pos.[Value of units to be transfered]*/) AS 'Total value of shares to be transferred per CID'
   ,sum(ISNULL(comp.[Compensation Deducted],0)) AS 'Compensation Deducted'
from
(
SELECT cast(dp.CloseOccurred AS DATE) 'Date',
dp.CloseDateID AS 'DateID',
dp.CID,
di.ISINCode,
di.InstrumentDisplayName,
dp.HedgeServerID,
sum(dp.AmountInUnitsDecimal) AS 'Units',
sum(dp.AmountInUnitsDecimal*dp.EndForexRate)'Value',
dp.EndForexRate AS 'Price Per Unit',
sum(dp.AmountInUnitsDecimal) AS 'Units to be transfered',
sum(FLOOR(dp.AmountInUnitsDecimal)*dp.EndForexRate) AS 'Value of units to be transfered'
FROM DWH_dbo.Dim_Position dp
JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID = di.InstrumentID and InstrumentTypeID<>10
WHERE dp.ClosePositionReasonID=22
AND dp.CloseDateID>=CAST(FORMAT(CAST(<[Parameters].[Parameter 1]>AS DATE),'yyyyMMdd') as INT)
GROUP BY 
cast(dp.CloseOccurred AS DATE) ,
dp.CloseDateID,
dp.CID,
di.ISINCode,
di.InstrumentDisplayName,
dp.HedgeServerID,
dp.EndForexRate 
)pos
LEFT JOIN
(
SELECT fca.RealCID 'CID',
fca.DateID,
cast(fca.Occurred AS DATE) 'Date',
sum(fca.Amount)  'Compensation Deducted'
FROM DWH_dbo.Fact_CustomerAction fca
WHERE fca.ActionTypeID=36
AND fca.CompensationReasonID=114
GROUP BY  fca.RealCID ,
fca.DateID,
cast(fca.Occurred AS DATE)
)comp ON comp.CID=pos.CID AND comp.Date=pos.Date
JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON pos.CID=fsc.RealCID
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND pos.DateID BETWEEN dr.FromDateID AND dr.ToDateID
where pos.Date between<[Parameters].[Parameter 1]> and<[Parameters].[Parameter 2]>
GROUP BY pos.Date
   ,pos.CID
   ,pos.ISINCode
   ,pos.InstrumentDisplayName
   ,pos.HedgeServerID
   ,pos.Units
   ,pos.[Value]
   ,pos.[Price Per Unit]
   ,FLOOR(pos.[Units to be transfered])
   ,fsc.IsCreditReportValidCB

UNION ALL 

SELECT comp2.Date
	  ,comp2.CID
	  ,comp2.ISINCode
	  ,comp2.InstrumentDisplayName
	  ,comp2.HedgeServerID
	  ,comp2.Units
	  ,comp2.[Value]
	  ,comp2.[Price Per Unit]
	  ,comp2.[Units to be transfered]
	  ,comp2.[Value of units to be transfered]'Value of units to be transfered'
	  ,fsc.IsCreditReportValidCB
	  ,0 'Total value of shares to be transferred per CID'
	  ,comp2.[Compensation Deducted]
FROM
(
SELECT cast(dp.CloseOccurred AS DATE) 'Date',
dp.CloseDateID AS 'DateID',
dp.CID,
di.ISINCode,
di.InstrumentDisplayName,
dp.HedgeServerID,
sum(dp.AmountInUnitsDecimal) AS 'Units',
sum(dp.AmountInUnitsDecimal*dp.EndForexRate)'Value',
dp.EndForexRate AS 'Price Per Unit',
sum(FLOOR(dp.AmountInUnitsDecimal)) AS 'Units to be transfered',
sum(FLOOR(dp.AmountInUnitsDecimal)*dp.EndForexRate) AS 'Value of units to be transfered'
FROM DWH_dbo.Dim_Position dp
JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID = di.InstrumentID and InstrumentTypeID<>10
WHERE dp.ClosePositionReasonID=22
AND dp.CloseDateID>=CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)  and dp.CloseDateID<=CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
GROUP BY 
cast(dp.CloseOccurred AS DATE) ,
dp.CloseDateID,
dp.CID,
di.ISINCode,
di.InstrumentDisplayName,
dp.HedgeServerID,
dp.EndForexRate 
)pos2
JOIN (
SELECT cast(fca.Occurred AS date) 'Date'
   ,fca.RealCID 'CID'
   ,null as ISINCode
   ,null as InstrumentDisplayName
   ,null as HedgeServerID
   ,null as Units
   ,null as [Value]
   ,null as [Price Per Unit]
   ,null as [Units to be transfered]
   ,sum(0) as [Value of units to be transfered]
,sum(fca.Amount)  'Compensation Deducted'
FROM DWH_dbo.Fact_CustomerAction fca
WHERE fca.ActionTypeID=36
AND fca.CompensationReasonID=114
GROUP BY  fca.RealCID ,
fca.DateID,
cast(fca.Occurred AS DATE)
)comp2 ON comp2.CID=pos2.CID AND comp2.Date>pos2.Date
JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON pos2.CID=fsc.RealCID
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND pos2.DateID BETWEEN dr.FromDateID AND dr.ToDateID
where pos2.DateID between CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT) and CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)