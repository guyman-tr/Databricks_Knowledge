SELECT *
FROM (

    SELECT 
        frs.DateID, 
        di.InstrumentID, 
        di.InstrumentDisplayName, 
        frs.Leverage, 
        CASE WHEN frs.IsBuy = 1 THEN 'Long' WHEN frs.IsBuy = 0 THEN 'Short' ELSE 'Error' END AS PositionType,
        SUM(CAST(frs.RolloverFee AS BIGINT)) AS Total_Overnight_Fee 
    FROM 
        BI_DB_dbo.Function_Revenue_RolloverFee(
            CAST(CONVERT(CHAR(8), DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0), 112) AS INT),
            CAST(CONVERT(CHAR(8), DATEADD(DAY, -1, GETDATE()), 112) AS INT),                 
            1                                                                               
        ) frs
    INNER JOIN (
        -- This subquery replaces your #pop temp table.
        -- It selects the exact same customer population.
        SELECT	dc.RealCID AS CID
              ,dr.Name AS Regulation  
        	  ,dps.Name AS PlayerStatus 
        	  ,dpl.Name AS Club
              ,dc1.Desk
              ,mif.Name AS MifidCategorisation
        	  ,mif.MifidCategorizationID
              ,dc1.Name AS CountryOfResidence
              ,CONVERT(DATE, fd.VerificationLevel3Date) VerificationLevel3Date
        FROM DWH_dbo.Dim_Customer dc
        JOIN DWH_dbo.[Dim_Country] dc1	ON dc1.CountryID = dc.CountryID
        JOIN DWH_dbo.Dim_PlayerStatus dps ON dc.PlayerStatusID = dps.PlayerStatusID AND dc.PlayerStatusID NOT IN (2,4,9,15)
        JOIN DWH_dbo.Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
        JOIN DWH_dbo.[Dim_Regulation] dr ON dr.DWHRegulationID = dc.RegulationID AND dc.RegulationID = 2
        LEFT JOIN DWH_dbo.Dim_MifidCategorization mif ON mif.MifidCategorizationID = dc.MifidCategorizationID
        LEFT JOIN BI_DB_dbo.[BI_DB_CIDFirstDates] fd WITH (NOLOCK) ON dc.RealCID = fd.CID
        WHERE dc.IsValidCustomer = 1
        AND dc.VerificationLevelID = 3
        AND dc.IsDepositor = 1
    ) p ON frs.RealCID = p.CID
    INNER JOIN DWH_dbo.Dim_Instrument di
        ON frs.InstrumentID = di.DWHInstrumentID
    WHERE frs.IsSettled = 0
    GROUP BY frs.DateID, di.InstrumentID, di.InstrumentDisplayName, frs.Leverage, CASE WHEN frs.IsBuy = 1 THEN 'Long' WHEN frs.IsBuy = 0 THEN 'Short' ELSE 'Error' END
) AS final_data