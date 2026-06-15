/* ============================
   Australia
   ============================ */
SELECT 
    'Australia'                               AS Country,
    e.Club,
    e.IsDepositor,
    e.NumberEligibleClients,
    ISNULL(a.NumberAccountsCreated, 0)       AS NumberAccountsCreated,
    CASE 
        WHEN e.NumberEligibleClients > 0 
            THEN CAST(a.NumberAccountsCreated AS FLOAT) / e.NumberEligibleClients 
        ELSE 0 
    END                                      AS RatioCreatedOutOfEligible
FROM 
(
    SELECT 
        dpl.Name AS Club,
        dc.IsDepositor,                       -- added
        COUNT(DISTINCT dc.RealCID) AS NumberEligibleClients
    FROM DWH_dbo.Dim_Customer dc
    JOIN DWH_dbo.Dim_PlayerLevel dpl
        ON dc.PlayerLevelID = dpl.PlayerLevelID
    WHERE dc.IsValidCustomer = 1
      AND dc.CountryID = 12
      AND dc.RegulationID in (10,5)
      AND dc.PlayerStatusID IN (1, 12, 5)
      AND dc.VerificationLevelID = 3
      AND dc.ScreeningStatusID = 1
      AND dc.AccountTypeID = 1
      AND dc.PhoneVerifiedID IN (1, 2)
      AND dc.POBCountryID IS NOT NULL
    GROUP BY dpl.Name, dc.IsDepositor        -- added
) e
LEFT JOIN 
(
    SELECT 
        dpl.Name AS Club,
        fsc.IsDepositor,                     -- added
        COUNT(DISTINCT mda.CID) AS NumberAccountsCreated
    FROM eMoney_dbo.eMoney_Dim_Account mda
    INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc
        ON mda.CID = fsc.RealCID
    INNER JOIN DWH_dbo.Dim_Range dr
        ON dr.DateRangeID = fsc.DateRangeID
        AND mda.AccountCreateDateID BETWEEN dr.FromDateID AND dr.ToDateID
    INNER JOIN DWH_dbo.Dim_PlayerLevel dpl
        ON fsc.PlayerLevelID = dpl.PlayerLevelID
    WHERE mda.GCID_Unique_Count = 1
      AND mda.IsValidETM = 1
      AND mda.IsTestAccount = 0
      AND mda.AccountSubProgramID IN (13, 14)
    GROUP BY dpl.Name, fsc.IsDepositor       -- added
) a
    ON e.Club = a.Club
   AND e.IsDepositor = a.IsDepositor         -- added


UNION ALL


/* ============================
   Denmark
   ============================ */
SELECT 
    'Denmark'                                AS Country,
    e.Club,
    e.IsDepositor,
    e.NumberEligibleClients,
    ISNULL(a.NumberAccountsCreated, 0)      AS NumberAccountsCreated,
    CASE 
        WHEN e.NumberEligibleClients > 0 
            THEN CAST(a.NumberAccountsCreated AS FLOAT) / e.NumberEligibleClients 
        ELSE 0 
    END                                     AS RatioCreatedOutOfEligible
FROM 
(
    SELECT 
        dpl.Name AS Club,
        dc.IsDepositor,                      -- added
        COUNT(DISTINCT dc.RealCID) AS NumberEligibleClients
    FROM DWH_dbo.Dim_Customer dc
    JOIN DWH_dbo.Dim_PlayerLevel dpl
        ON dc.PlayerLevelID = dpl.PlayerLevelID
    LEFT JOIN eMoney_dbo.eMoney_Dim_Account mda_bad
        ON dc.RealCID = mda_bad.CID
        AND mda_bad.GCID_Unique_Count = 1
        AND mda_bad.IsValidETM = 1
        AND mda_bad.IsTestAccount = 0
        AND mda_bad.AccountSubProgramID NOT IN (15,16)
    WHERE dc.IsValidCustomer = 1
      AND dc.CountryID = 57
      AND dc.RegulationID in (1,5)
      AND dc.PlayerStatusID IN (1, 12, 5)
      AND dc.VerificationLevelID = 3
      AND dc.ScreeningStatusID = 1
      AND dc.AccountTypeID = 1
      AND dc.PhoneVerifiedID IN (1, 2)
      AND dc.POBCountryID IS NOT NULL
      AND mda_bad.CID IS NULL
    GROUP BY dpl.Name, dc.IsDepositor       -- added
) e
LEFT JOIN 
(
    SELECT 
        dpl.Name AS Club,
        fsc.IsDepositor,                    -- added
        COUNT(DISTINCT mda.CID) AS NumberAccountsCreated
    FROM eMoney_dbo.eMoney_Dim_Account mda
    INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc
        ON mda.CID = fsc.RealCID
    INNER JOIN DWH_dbo.Dim_Range dr
        ON dr.DateRangeID = fsc.DateRangeID
        AND mda.AccountCreateDateID BETWEEN dr.FromDateID AND dr.ToDateID
    INNER JOIN DWH_dbo.Dim_PlayerLevel dpl
        ON fsc.PlayerLevelID = dpl.PlayerLevelID
    WHERE mda.GCID_Unique_Count = 1
      AND mda.IsValidETM = 1
      AND mda.IsTestAccount = 0
      AND mda.AccountSubProgramID IN (15, 16)
    GROUP BY dpl.Name, fsc.IsDepositor      -- added
) a
    ON e.Club = a.Club
   AND e.IsDepositor = a.IsDepositor        -- added