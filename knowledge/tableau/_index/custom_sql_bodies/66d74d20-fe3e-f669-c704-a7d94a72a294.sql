SELECT 
    b.Name AS CountryName,
    dpl.Name AS Club_At_Position_Opening_Date,
    fsc.*,
    base.Num_Positions,
    base.Total_Amount
FROM (
    -- == Base Aggregation (same as #Base)
    SELECT 
        dp.CID,
        CAST(CONVERT(CHAR(8), dp.OpenOccurred, 112) AS INT) AS DateID,
        COUNT(DISTINCT dp.PositionID) AS Num_Positions,
        SUM(dp.Amount) AS Total_Amount
    FROM DWH_dbo.Dim_Position dp
    JOIN  BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN
	 ib
        ON dp.PositionID = ib.PositionID
    JOIN eMoney_dbo.eMoney_Dim_Account mda
        ON dp.CID = mda.CID
    WHERE dp.OpenOccurred IS NOT NULL
	
      AND mda.IsValidETM = 1
      AND mda.GCID_Unique_Count = 1
      AND mda.IsTestAccount = 0
      AND mda.AccountSubProgramID IN (13,14)
    GROUP BY 
        dp.CID,
        CAST(CONVERT(CHAR(8), dp.OpenOccurred, 112) AS INT)
) base
INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc
    ON base.CID = fsc.RealCID
INNER JOIN DWH_dbo.Dim_Range dr
    ON dr.DateRangeID = fsc.DateRangeID
    AND base.DateID BETWEEN dr.FromDateID AND dr.ToDateID
INNER JOIN DWH_dbo.Dim_Country b
    ON fsc.CountryID = b.CountryID
INNER JOIN DWH_dbo.Dim_PlayerLevel dpl
    ON fsc.PlayerLevelID = dpl.PlayerLevelID