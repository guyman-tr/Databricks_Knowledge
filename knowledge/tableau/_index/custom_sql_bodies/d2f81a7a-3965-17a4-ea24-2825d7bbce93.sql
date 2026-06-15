SELECT  

cast(fca.Occurred AS DATE) AS 'Date',
fca.DateID,
fca.RealCID,
fsc.IsCreditReportValidCB,
dr1.Name AS 'Regulation',
dc.Name AS 'Country',
sum(fca.Amount*-1) AS 'Gross Ticketing Fee',
max(CASE WHEN fsc.RegulationID IN (4,10) and fsc.CountryID=12 AND di.Exchange = 'Sydney' and dp.IsSettled = 1  and InstrumentTypeID IN (5,6) AND c.PlayerLevelID<> 4 and fsc.IsCreditReportValidCB = 1THEN 0.1  
            when fsc.RegulationID IN (11) and fsc.CountryID=217 and dp.IsSettled = 1 and InstrumentTypeID IN (5,6) AND c.PlayerLevelID<> 4and fsc.IsCreditReportValidCB = 1then 0.0
            WHEN fsc.RegulationID IN (13) and fsc.CountryID=183 and dp.IsSettled = 1 and InstrumentTypeID IN (5,6) AND c.PlayerLevelID<> 4 and fsc.IsCreditReportValidCB = 1 then 0.09
ELSE 0 END) AS 'GST/VAT rate', --,
dp.IsSettled, -- 10/06/2025 Update
di.InstrumentType-- 10/06/2025 Update
--fca.PositionID,
--di.exc
,c.Name as PlayerLevel
,di.Exchange
FROM DWH_dbo.Fact_CustomerAction fca
JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON fca.RealCID = fsc.RealCID
JOIN DWH_dbo.Dim_Range dr ON  dr.DateRangeID=fsc.DateRangeID AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Country dc ON fsc.CountryID = dc.CountryID
JOIN DWH_dbo.Dim_Regulation dr1 ON dr1.DWHRegulationID=fsc.RegulationID
JOIN DWH_dbo.Dim_Position dp ON fca.PositionID = dp.PositionID
JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID = di.InstrumentID
join DWH_dbo.Dim_PlayerLevel c on c.PlayerLevelID= fsc.PlayerLevelID
WHERE fca.ActionTypeID=35
AND fca.IsFeeDividend=4
AND fca.DateID>=20240701
and fca.DateID between CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
and CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
group BY 
cast(fca.Occurred AS DATE),
fca.DateID,
fca.RealCID,
fsc.IsCreditReportValidCB,
dr1.Name,
dc.Name,
dp.IsSettled, 
di.InstrumentType,
c.Name,
di.Exchange
/*

*/