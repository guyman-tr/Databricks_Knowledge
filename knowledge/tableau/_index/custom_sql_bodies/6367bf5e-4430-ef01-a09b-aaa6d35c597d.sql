SELECT 
    ISNULL(y.Regulation, w.Regulation) AS Regulation,
    ISNULL(y.PlayerCategorization, w.PlayerCategorization) AS PlayerCategorization,
    ISNULL(y.RecoverableFromBalance_YTD, 0) AS RecoverableFromBalance_YTD,
    ISNULL(y.DeltaLoss_YTD, 0) AS DeltaLoss_YTD,
    ISNULL(w.RecoverableFromBalance_1W, 0) AS RecoverableFromBalance_1W,
    ISNULL(w.DeltaLoss_1W, 0) AS DeltaLoss_1W
FROM 
    (
        -- YTD subquery, unchanged
        SELECT 
            Regulation,
            PlayerCategorization,
            SUM(CASE 
                    WHEN availablebalance < 0 THEN 0
                    WHEN availablebalance > DeltaLoss THEN DeltaLoss
                    ELSE availablebalance 
                END) AS RecoverableFromBalance_YTD,
            SUM(DeltaLoss) AS DeltaLoss_YTD
        FROM 
            (
                SELECT 
                    tt.CID,
                    Date,
                    MIN(tt.Credit) AS availablebalance,
                    dr.Name AS Regulation,
                    CASE WHEN dc.MifidCategorizationID IN (1,4) THEN 'Retail' ELSE 'Else' END AS PlayerCategorization,
                    ee.DeltaLoss
                FROM 
                    DWH_dbo.etoro_History_Credit tt
                JOIN 
                    Dealing_dbo.Dealing_ESMANetLoss ee
                    ON tt.PositionID = ee.PositionID
                JOIN 
                    DWH_dbo.Dim_Position dp 
                    ON ee.PositionID = dp.PositionID
                JOIN 
                    DWH_dbo.Dim_Customer dc 
                    ON dc.RealCID = tt.CID
                JOIN 
                    DWH_dbo.Dim_Regulation dr 
                    ON dc.RegulationID = dr.DWHRegulationID
                WHERE 
                    YEAR(ee.Date) = YEAR(CAST(GETDATE() AS DATE)) 
                    AND ee.Date <= CAST(GETDATE() AS DATE)
                    AND tt.CreditTypeID = 4
                    AND Date = CAST(tt.Occurred AS DATE)
                GROUP BY 
                    tt.CID, dr.Name, Date,
                    CASE WHEN dc.MifidCategorizationID IN (1,4) THEN 'Retail' ELSE 'Else' END,
                    ee.DeltaLoss
            ) tt
        GROUP BY 
            Regulation, PlayerCategorization
    ) y
FULL JOIN 
    (
        -- 1W subquery: Fixing the logic to match your required approach
        SELECT 
            Regulation,
            PlayerCategorization,
            SUM(CASE 
                    WHEN availablebalance < 0 THEN 0
                    WHEN availablebalance > dd.DeltaLoss THEN dd.DeltaLoss
                    ELSE availablebalance 
                END) AS RecoverableFromBalance_1W,
            SUM(dd.DeltaLoss) AS DeltaLoss_1W
        FROM 
            (
                -- AvailableBalance_1W
                SELECT 
                    tt.CID,
                    Date,
                    MIN(tt.Credit) AS availablebalance,
                    dr.Name AS Regulation,
                    CASE WHEN dc.MifidCategorizationID IN (1,4) THEN 'Retail' ELSE 'Else' END AS PlayerCategorization
                FROM 
                    DWH_dbo.etoro_History_Credit tt
                JOIN 
                    (
                        -- Delta_1W: Getting data for the last 7 days
                        SELECT 
                            Date,
                            dp.CID,
                            ee.PositionID AS PID,
                            ee.DeltaLoss
                        FROM 
                            Dealing_dbo.Dealing_ESMANetLoss ee
                        JOIN 
                            DWH_dbo.Dim_Position dp 
                            ON ee.PositionID = dp.PositionID
                        WHERE 
                            Date >= GETDATE()-7 
                            AND Date <= GETDATE()
                    ) dd 
                    ON tt.PositionID = dd.PID 
                       AND tt.CreditTypeID = 4 
                       AND Date = CAST(tt.Occurred AS DATE)
                JOIN 
                    DWH_dbo.Dim_Customer dc 
                    ON dc.RealCID = tt.CID
                JOIN 
                    DWH_dbo.Dim_Regulation dr 
                    ON dc.RegulationID = dr.DWHRegulationID
                GROUP BY 
                    tt.CID, dr.Name, Date,
                    CASE WHEN dc.MifidCategorizationID IN (1,4) THEN 'Retail' ELSE 'Else' END
            ) tt
        JOIN 
            (
                -- Delta_1W: Getting data for the last 7 days
                SELECT 
                    Date,
                    dp.CID,
                    ee.InstrumentID,
                    ee.PositionID AS PID,
                    ee.DeltaLoss
                FROM 
                    Dealing_dbo.Dealing_ESMANetLoss ee
                JOIN 
                    DWH_dbo.Dim_Position dp 
                    ON ee.PositionID = dp.PositionID
                WHERE 
                    Date >= GETDATE()-7 
                    AND Date <= GETDATE()
            ) dd
        ON tt.CID = dd.CID 
        AND tt.Date = dd.Date
        GROUP BY 
            Regulation, PlayerCategorization
    ) w
    ON y.Regulation = w.Regulation 
    AND y.PlayerCategorization = w.PlayerCategorization