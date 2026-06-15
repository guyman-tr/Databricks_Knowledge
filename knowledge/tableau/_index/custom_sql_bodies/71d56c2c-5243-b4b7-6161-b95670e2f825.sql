SELECT dp.CID,
       dc.GCID,
       dp.PositionID,
       di.InstrumentType,
       dp.IsSettled,
       dp.Amount,
       cast(dp.OpenOccurred as date) OpenDate,
       LEFT(dp.OpenDateID,6) OpenYearMonth,
       LEFT(dp.CloseDateID,6) CloseYearMonth,
       dp.MirrorID,
       dm.MirrorTypeID,
       dc.PlayerLevelID,
       LEFT(dm.OpenDateID,6) OpenMirrorYearMonth
FROM DWH_dbo.Dim_Position dp
JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID = di.InstrumentID
JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID=dp.CID AND dc.IsValidCustomer=1
LEFT JOIN DWH_dbo.Dim_Mirror dm ON dp.MirrorID = dm.MirrorID AND dp.CID = dm.CID AND dp.OpenDateID = dm.OpenDateID
WHERE CAST(CONVERT(VARCHAR(6),dp.OpenOccurred,112) AS INT) BETWEEN CAST(CONVERT(VARCHAR(6),DATEADD(MONTH,-6,CAST(GETDATE() AS DATE)),112)AS INT) AND CAST(CONVERT(VARCHAR(6),DATEADD(MONTH,-1,CAST(GETDATE() AS DATE)),112) AS INT)
  AND dp.IsAirDrop IS NULL