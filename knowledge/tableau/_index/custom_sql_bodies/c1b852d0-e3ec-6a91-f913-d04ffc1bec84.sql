SELECT 
      b.Name AS CountryName
    , dpl.Name AS Club_At_Position_Opening_Date   -- alias unchanged
    , mda.Entity                                  -- added entity
    , fsc.*
    , base.Num_Positions
    , base.Total_Amount
    , base.SellCurrency
    , CAST(CAST(base.DateID AS VARCHAR(8)) AS DATE) AS PositionCloseDate -- Added: Tableau will recognize this as a Date
    , CASE WHEN mda.AccountSubProgramID IN (13,14) THEN 'Australia' ELSE 'Denmark DKK' END AS 'Country (Based On SubProgram)' 
FROM (
        -- == Base Aggregation (same as #Base)
        SELECT 
              dp.CID
            , i.SellCurrency
            , CAST(CONVERT(CHAR(8), dp.CloseOccurred, 112) AS INT) AS DateID
            , COUNT(DISTINCT dp.PositionID) AS Num_Positions
            , SUM(dp.Amount) AS Total_Amount
        FROM DWH_dbo.Dim_Position dp
        JOIN BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN ib
            ON dp.PositionID = ib.PositionID
        JOIN eMoney_dbo.eMoney_Dim_Account mda
            ON dp.CID = mda.CID
        JOIN DWH_dbo.Dim_Instrument i 
            ON dp.InstrumentID = i.InstrumentID
        WHERE dp.CloseOccurred IS NOT NULL
          AND dp.MirrorID = 0                     -- << EXCLUDE COPY POSITIONS
          AND mda.IsValidETM = 1
          AND mda.GCID_Unique_Count = 1
          AND mda.IsTestAccount = 0
          AND mda.AccountSubProgramID IN (13,14,15,16)
        GROUP BY 
              dp.CID
            , i.SellCurrency
            , CAST(CONVERT(CHAR(8), dp.CloseOccurred, 112) AS INT)
     ) base
INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc
        ON base.CID = fsc.RealCID
INNER JOIN DWH_dbo.Dim_Range dr
        ON dr.DateRangeID = fsc.DateRangeID
       AND base.DateID BETWEEN dr.FromDateID AND dr.ToDateID
INNER JOIN eMoney_dbo.eMoney_Dim_Account mda            -- entity join
        ON base.CID = mda.CID
INNER JOIN DWH_dbo.Dim_Country b
        ON fsc.CountryID = b.CountryID
INNER JOIN DWH_dbo.Dim_PlayerLevel dpl
        ON fsc.PlayerLevelID = dpl.PlayerLevelID