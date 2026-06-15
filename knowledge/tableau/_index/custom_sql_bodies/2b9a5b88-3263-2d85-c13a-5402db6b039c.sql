SELECT
  t.[Date] AS DateMinus1,
  COUNT(DISTINCT CASE WHEN t.Metric = 'FTD' THEN t.GCID END) AS FTD_total,
  COUNT(DISTINCT CASE WHEN t.Metric = 'Reg' THEN t.GCID END) AS Registrations
FROM (
    SELECT CAST(dc.FirstDepositDate AS date) AS [Date], dc.GCID, 'FTD' AS Metric
    FROM DWH_dbo.Dim_Customer dc
    WHERE dc.RegulationID IN (6,7,8,12,14)
      AND dc.IsDepositor = 1
      AND dc.FirstDepositDate >= DATEADD(WEEK, -10, CAST(GETDATE() AS date))

    UNION ALL

    SELECT CAST(dc.RegisteredReal AS date) AS [Date], dc.GCID, 'Reg' AS Metric
    FROM DWH_dbo.Dim_Customer dc
    WHERE dc.RegulationID IN (6,7,8,12,14)
      AND dc.RegisteredReal >= DATEADD(WEEK, -10, CAST(GETDATE() AS date))
) t
GROUP BY t.[Date]
--ORDER BY t.[Date]