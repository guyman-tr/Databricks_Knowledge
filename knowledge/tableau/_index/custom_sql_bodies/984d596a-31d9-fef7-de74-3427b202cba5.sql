SELECT
    DATEADD(day, -(dd.DayNumberOfWeek_Sun_Start - 1), dd.FullDate) AS StartOfWeekDate,
    SUM(x.FullCommission_CFD_Crypto) AS FullCommission_CFD_Crypto,
    SUM(x.OverNightFee_CFD_Crypto)   AS OverNightFee_CFD_Crypto,
	SUM(FullCommission_CFD_NonCrypto) AS FullCommission_CFD_NonCrypto,
	SUM(OverNightFee_CFD_NonCrypto) AS OverNightFee_CFD_NonCrypto
FROM (
    SELECT 
        dddc.DateID,
        SUM(CASE WHEN dddc.InstrumentType = 'Crypto Currencies' AND dddc.IsCFD = 1
                 THEN dddc.FullCommission ELSE 0 END) AS FullCommission_CFD_Crypto,
        SUM(CASE WHEN dddc.InstrumentType = 'Crypto Currencies' AND dddc.IsCFD = 1
                 THEN dddc.OverNightFee ELSE 0 END) AS OverNightFee_CFD_Crypto,
		SUM(CASE WHEN dddc.InstrumentType <> 'Crypto Currencies' AND dddc.IsCFD = 1 
				 THEN dddc.FullCommission ELSE 0 END) AS FullCommission_CFD_NonCrypto,
		SUM(CASE WHEN dddc.InstrumentType <> 'Crypto Currencies' AND dddc.IsCFD = 1 
			    THEN dddc.OverNightFee ELSE 0 END) AS OverNightFee_CFD_NonCrypto
    FROM Dealing_dbo.Dealing_DealingDashboard_Clients dddc
    WHERE dddc.DateID >= 20250701
      AND dddc.Regulation = 'MAS'
    GROUP BY dddc.DateID
) x
JOIN DWH_dbo.Dim_Date dd
  ON x.DateID = dd.DateKey
GROUP BY DATEADD(day, -(dd.DayNumberOfWeek_Sun_Start - 1), dd.FullDate)
--ORDER BY StartOfWeekDate;