SELECT 
    CASE 
        WHEN di.InstrumentType IN ('ETF','Stocks') AND dp.IsSettled=1 AND dp.MirrorID=0 THEN 'Real Stocks'
        WHEN di.InstrumentType IN ('ETF','Stocks') AND dp.IsSettled=0 AND dp.MirrorID=0 THEN 'CFD Stocks'
        WHEN di.InstrumentType='Crypto Currencies' AND dp.IsSettled=1 AND dp.MirrorID=0 THEN 'Real Crypto'
        WHEN di.InstrumentType='Crypto Currencies' AND dp.IsSettled=0 AND dp.MirrorID=0 THEN 'CFD Crypto'
        WHEN di.InstrumentType IN ('Currencies','Indices','Commodities') AND dp.MirrorID=0 THEN 'FX/Comm/Ind'
        WHEN dp.MirrorID>0 THEN 'Copy' 
    END AS AssetType,
    dc1.MarketingRegionManualName AS Region,
    MONTH(dp.OpenOccurred) + YEAR(dp.OpenOccurred) * 100 AS ActiveMonth,
    COUNT(DISTINCT dp.CID) AS users
FROM DWH_dbo.Dim_Position dp
JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID = di.InstrumentID
JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID = dp.CID AND dc.IsValidCustomer = 1
JOIN DWH_dbo.Dim_Country dc1 ON dc.CountryID = dc1.CountryID 
WHERE CAST(dp.OpenOccurred AS DATE) >= '2024-10-01'
  AND ISNULL(dp.IsAirDrop, 0) = 0 
  
  -- החרגת לקוחות שהפקידו בדיוק 1$ בתאריך 22.5.2026
  AND NOT (CAST(dc.FirstDepositDate AS DATE) = '2026-05-22' AND dc.FirstDepositAmount = 1)

GROUP BY 
    CASE 
        WHEN di.InstrumentType IN ('ETF','Stocks') AND dp.IsSettled=1 AND dp.MirrorID=0 THEN 'Real Stocks'
        WHEN di.InstrumentType IN ('ETF','Stocks') AND dp.IsSettled=0 AND dp.MirrorID=0 THEN 'CFD Stocks'
        WHEN di.InstrumentType='Crypto Currencies' AND dp.IsSettled=1 AND dp.MirrorID=0 THEN 'Real Crypto'
        WHEN di.InstrumentType='Crypto Currencies' AND dp.IsSettled=0 AND dp.MirrorID=0 THEN 'CFD Crypto'
        WHEN di.InstrumentType IN ('Currencies','Indices','Commodities') AND dp.MirrorID=0 THEN 'FX/Comm/Ind'
        WHEN dp.MirrorID>0 THEN 'Copy' 
    END,
    dc1.MarketingRegionManualName,
    MONTH(dp.OpenOccurred) + YEAR(dp.OpenOccurred) * 100