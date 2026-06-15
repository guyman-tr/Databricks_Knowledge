SELECT
    CID,
    SUM(Net_Payment_Amount) AS Net_Payment_Amount,
    SUM(Gross_Daily_Interest) AS Gross_Daily_Interest
FROM (
    SELECT 
        bdid.CID,
        bdid.DateID,
        bdid.Interest AS Interest_Paid_Still_In_Balance,
        (bdid.Credit - bdid.Interest) AS Balance_Earning_Interest,

        -- Tax withholding percent
        CASE 
            WHEN bdid.RegulationID IN (1,9,11,12) THEN 0
            WHEN bdid.RegulationID = 2 THEN 20
            WHEN bdid.RegulationID IN (4,10) AND bdid.CountryID = 12 AND tin.TIN_Value IS NOT NULL THEN 0
            WHEN bdid.RegulationID IN (4,10) AND bdid.CountryID = 12 AND tin.TIN_Value IS NULL THEN 47 
            WHEN bdid.RegulationID IN (4,10) AND bdid.CountryID != 12 THEN 10
            ELSE 0
        END AS Tax_Withholding_Percent,

        -- Annual interest percent
        CASE 
            WHEN dc.EU = 1 AND bdid.PlayerLevelID IN (7,6) THEN 4.3
            WHEN dc.EU = 1 AND bdid.PlayerLevelID IN (2,3,5,1) THEN 3.5
            WHEN dc.EU = 0 AND bdid.PlayerLevelID = 7 THEN 4.3
            WHEN dc.EU = 0 AND bdid.PlayerLevelID = 6 THEN 4
            WHEN dc.EU = 0 AND bdid.PlayerLevelID = 2 THEN 3
            WHEN dc.EU = 0 AND bdid.PlayerLevelID = 3 THEN 1
            ELSE 0
        END AS Annual_Interest_Percent,

        -- Gross daily interest
        (bdid.Credit - bdid.Interest) *
        (
            CASE 
                WHEN dc.EU = 1 AND bdid.PlayerLevelID IN (7,6) THEN 4.3
                WHEN dc.EU = 1 AND bdid.PlayerLevelID IN (2,3,5,1) THEN 3.5
                WHEN dc.EU = 0 AND bdid.PlayerLevelID = 7 THEN 4.3
                WHEN dc.EU = 0 AND bdid.PlayerLevelID = 6 THEN 4
                WHEN dc.EU = 0 AND bdid.PlayerLevelID = 2 THEN 3
                WHEN dc.EU = 0 AND bdid.PlayerLevelID = 3 THEN 1
                ELSE 0
            END / 100.0 / 365.0
        ) AS Gross_Daily_Interest,

        -- Net payment amount
        ((bdid.Credit - bdid.Interest) *
        (
            CASE 
                WHEN dc.EU = 1 AND bdid.PlayerLevelID IN (7,6) THEN 4.3
                WHEN dc.EU = 1 AND bdid.PlayerLevelID IN (2,3,5,1) THEN 3.5
                WHEN dc.EU = 0 AND bdid.PlayerLevelID = 7 THEN 4.3
                WHEN dc.EU = 0 AND bdid.PlayerLevelID = 6 THEN 4
                WHEN dc.EU = 0 AND bdid.PlayerLevelID = 2 THEN 3
                WHEN dc.EU = 0 AND bdid.PlayerLevelID = 3 THEN 1
                ELSE 0
            END / 100.0 / 365.0
        )) * 
        (1 - 
        (
            CASE 
                WHEN bdid.RegulationID IN (1,9,11,12) THEN 0
                WHEN bdid.RegulationID = 2 THEN 20
                WHEN bdid.RegulationID IN (4,10) AND bdid.CountryID = 12 AND tin.TIN_Value IS NOT NULL THEN 0
                WHEN bdid.RegulationID IN (4,10) AND bdid.CountryID = 12 AND tin.TIN_Value IS NULL THEN 47 
                WHEN bdid.RegulationID IN (4,10) AND bdid.CountryID != 12 THEN 10
                ELSE 0
            END / 100.0
        )) AS Net_Payment_Amount

    FROM [BI_DB_dbo].BI_DB_InterestDaily bdid (nolock)
    JOIN [DWH_dbo].[Dim_Country] dc (nolock)
        ON dc.CountryID = bdid.CountryID
    JOIN #InterestConsent ic
        ON bdid.CID = ic.CID
        AND bdid.DayOfInterest >= ic.ValidFrom
        AND bdid.DayOfInterest < ic.ValidTo
        AND ic.ConsentStatusID = 1
    LEFT JOIN (
        SELECT CID, MAX(TIN_Value) AS TIN_Value
        FROM BI_DB_dbo.BI_DB_Tax_Compliance_TIN (nolock)
        GROUP BY CID
    ) tin
        ON tin.CID = bdid.CID
    WHERE bdid.DayOfInterest >= <[Parameters].[Parameter 1]>  --  Parameter
      AND bdid.DayOfInterest <= <[Parameters].[Parameter 2]>     --  Parameter
) AS Calculation
GROUP BY CID