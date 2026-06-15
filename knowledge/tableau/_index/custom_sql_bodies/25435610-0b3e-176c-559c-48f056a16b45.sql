SELECT InstrumentID,Leverage,
InstrumentDisplayName,
SUM(VolumeOnOpen)VolumeOnOpen,
SUM(VolumeOnClose)AS VolumeOnClose, 
SUM(TotalVolume) AS TotalVolume,
SUM(a.clicks) clicks,
AVG(nop) AS NOP, 
avg(OP) AS OP,
SUM(Zero) Zero  FROM (
SELECT 
DateID,Leverage,
dddc.InstrumentID,
dddc.InstrumentDisplayName,
SUM(VolumeOnOpen)VolumeOnOpen,
SUM(VolumeOnClose)AS VolumeOnClose, 
SUM(dddc.TotalVolume) AS TotalVolume,
SUM(dddc.NumberOfPositionsOpened+dddc.NumberOfPositionsClosed) clicks,
SUM(NOP) AS nop, 
SUM(dddc.LongOpenPositions+dddc.ShortOpenPositions) AS OP,
SUM(dddc.TotalZero) Zero 
FROM Dealing_dbo.Dealing_DealingDashboard_Clients dddc
WHERE dddc.DateID BETWEEN 20230101 AND 20240901
AND dddc.InstrumentType = 'Currencies'
--AND dddc.Leverage = 30 
GROUP BY DateID,dddc.InstrumentID,dddc.InstrumentDisplayName,Leverage
--ORDER BY dddc.InstrumentID,dddc.InstrumentDisplayName
) a GROUP BY InstrumentID,
InstrumentDisplayName, Leverage