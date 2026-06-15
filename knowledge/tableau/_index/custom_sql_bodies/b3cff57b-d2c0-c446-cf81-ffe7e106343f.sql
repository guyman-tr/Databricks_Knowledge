SELECT  cast(fca.Occurred AS DATE) AS 'Date',
fca.DateID,
fca.RealCID,
dr1.Name AS 'Regulation',
dc.Name AS 'Country',
fca.Amount*-1 AS 'Gross Ticketing Fee',
CASE WHEN fsc.RegulationID IN (4,10) THEN 0.1 ELSE 0 END AS 'GST/VAT rate'--,
--fca.PositionID,
--di.exc
FROM DWH_dbo.Fact_CustomerAction fca
JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON fca.RealCID = fsc.RealCID
JOIN DWH_dbo.Dim_Range dr ON  dr.DateRangeID=fsc.DateRangeID AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Country dc ON fsc.CountryID = dc.CountryID
JOIN DWH_dbo.Dim_Regulation dr1 ON dr1.DWHRegulationID=fsc.RegulationID
JOIN DWH_dbo.Dim_Position dp ON fca.PositionID = dp.PositionID
JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID = di.InstrumentID
WHERE fca.ActionTypeID=35
AND fca.IsFeeDividend=4
AND fca.DateID>=20240701
and fca.DateID between CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
and CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)