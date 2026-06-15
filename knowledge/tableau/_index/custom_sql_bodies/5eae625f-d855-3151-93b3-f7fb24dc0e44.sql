SELECT a.FullDate 
, a.Regulation
, (CASE WHEN a.InstrumentType = 'Stocks' AND a.IsSettled = 1 THEN 'Real Stocks' 
WHEN a.InstrumentType = 'Stocks' AND a.IsSettled = 0 THEN 'CFD Stocks'
ELSE a.InstrumentType END) AS InstrumentType
, SUM(VolumeOnOpen) AS VolumeOnOpen
, SUM(VolumeOnClose) AS VolumeOnClose
, SUM(VolumeOnOpen) + SUM(VolumeOnClose) AS TotalVolume
, SUM(a.FullCommissions) AS FullCommissions
, SUM(a.Commissions) AS Commissions
, SUM(a.FullCommissionOnCloseAdjustment) AS FullCommissionOnCloseAdjustment
, SUM(a.CommissionOnCloseAdjustment) AS CommissionOnCloseAdjustment
FROM BI_DB_dbo.BI_DB_DailyCommisionReport a
WHERE DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
AND CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT) 
AND a.Regulation = 'FCA'
AND a.InstrumentType <> 'N/A'
GROUP BY FullDate, a.Regulation
, (CASE WHEN a.InstrumentType = 'Stocks' AND a.IsSettled = 1 THEN 'Real Stocks' 
WHEN a.InstrumentType = 'Stocks' AND a.IsSettled = 0 THEN 'CFD Stocks'
ELSE a.InstrumentType END)