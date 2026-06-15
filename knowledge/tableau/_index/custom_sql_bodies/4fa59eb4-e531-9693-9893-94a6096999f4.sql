SELECT   CONCAT(YEAR(sub.OccurredDate),'-',MONTH(sub.OccurredDate),'-01') AS 'ActiveMonth'
        ,sub.CID
        ,sub.RegAccountSubProgram
        ,sub.BankAccountIBAN
        ,SUM(CASE WHEN sub.rn = 1 THEN 1 ELSE 0 END) AS 'IsOpenFirstTime'
FROM (
    SELECT  dp.CID
           ,CAST(dp.OpenOccurred AS DATE) AS OccurredDate
           ,dp.OpenOccurred
           ,fsc.IsValidCustomer
           ,fsc.CountryID
           ,fsc.PlayerLevelID
           ,mda.RegAccountSubProgram
           ,mda.BankAccountIBAN
           ,ROW_NUMBER() OVER (PARTITION BY dp.CID ORDER BY dp.OpenOccurred) AS rn
    FROM DWH_dbo.Dim_Position dp

    INNER JOIN BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN b
        ON dp.PositionID = b.PositionID

    INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc 
        ON dp.CID = fsc.RealCID

    INNER JOIN DWH_dbo.Dim_Range drg 
        ON fsc.DateRangeID = drg.DateRangeID 
        AND CAST(CONVERT(CHAR(8), dp.OpenOccurred, 112) AS INT)
            BETWEEN drg.FromDateID AND drg.ToDateID 

    INNER JOIN eMoney_dbo.eMoney_Dim_Account mda 
        ON dp.CID = mda.CID
        AND mda.GCID_Unique_Count = 1

    WHERE dp.OpenOccurred >= '2024-04-01'
      AND (dp.IsPartialCloseChild = 0 OR dp.IsPartialCloseChild IS NULL)

) sub
GROUP BY 
        CONCAT(YEAR(sub.OccurredDate),'-',MONTH(sub.OccurredDate),'-01'),
        sub.CID,
        sub.RegAccountSubProgram,
        sub.BankAccountIBAN