---------Notional Amount by EOW---------

SELECT  pnl.Date,
	dc.Name AS Country,
dmc.Name AS MifidCategorization,
        SUM(CASE WHEN dp.IsSettled = 0 THEN ISNULL(pnl.Amount, 0)*ISNULL(dp.Leverage, 1) ELSE 0 END) 'Notional_CFDs', 
        SUM(ISNULL(pnl.Amount,0)*ISNULL(dp.Leverage,1)) 'Notional'
FROM  BI_DB_dbo.BI_DB_PositionPnL pnl WITH (NOLOCK) 
INNER JOIN DWH_dbo.Dim_Position dp ON pnl.PositionID = dp.PositionID
INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON pnl.CID = fsc.RealCID
INNER JOIN DWH_dbo.Dim_MifidCategorization dmc ON fsc.MifidCategorizationID = dmc.MifidCategorizationID
INNER JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND pnl.DateID BETWEEN dr.FromDateID AND dr.ToDateID
INNER JOIN DWH_dbo.Dim_Date dd ON dd.DateKey=pnl.DateID
INNER JOIN DWH_dbo.Dim_Country dc ON fsc.CountryID = dc.CountryID
WHERE ISNULL(dp.IsAirDrop, -1) < 1
      AND fsc.IsValidCustomer = 1
      AND fsc.IsDepositor = 1  
      AND fsc.VerificationLevelID = 3
      ---AND fsc.CountryID = 191
      AND DateKey>= CAST(FORMAT(CAST(DATEADD(WEEK,-7,GETDATE()-1) AS DATE),'yyyyMMdd') as INT)
AND DateKey <= CAST(FORMAT(CAST(DATEADD(DAY, 8 - DATEPART(WEEKDAY, GETDATE()-1), DATEADD(WEEK, -1, GETDATE()-1)) AS DATE),'yyyyMMdd') as INT)
AND dd.DayNumberOfWeek_Sun_Start = 1
GROUP BY pnl.Date,
        dmc.Name,
	dc.Name