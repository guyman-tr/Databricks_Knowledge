SELECT 
    pp.*,
    ISNULL(eq.Equity, 0) AS Equity,
    ISNULL(dp.Total_Deposits, 0) AS Total_Deposits,
    GETDATE() AS UpdateDate
FROM (
    SELECT 
        dc.RealCID AS CID,
        dr.Name AS Regulation,
        dc1.Name AS Country,
        dc2.Name AS CitizenshipCountry,
        dc3.Name AS POBCountry,
        dps.Name AS PlayerStatus,
        dpsr.Name AS PlayerStatusReason,
        dpssr.PlayerStatusSubReasonName,
        dpl.Name AS Club,
        bdrc.RiskScoreName,
        dss.Name AS ScreeningStatus,
        dat.Name AS AccountType,
        dems.EvMatchStatusName,
        dc.FirstDepositDate,
        dc.FirstDepositAmount,
        dc.RegisteredReal,
        dc.HasWallet,
        dc.VerificationLevelID
    FROM DWH_dbo.Dim_Customer dc
    JOIN DWH_dbo.Dim_Regulation dr 
        ON dr.DWHRegulationID = dc.RegulationID AND dr.DWHRegulationID = 11
    JOIN DWH_dbo.Dim_Country dc1 
        ON dc1.DWHCountryID = dc.CountryID
    JOIN DWH_dbo.Dim_PlayerStatus dps 
        ON dc.PlayerStatusID = dps.PlayerStatusID AND dps.PlayerStatusID NOT IN (2,4)
    JOIN DWH_dbo.Dim_PlayerLevel dpl 
        ON dc.PlayerLevelID = dpl.PlayerLevelID
    LEFT JOIN BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake bdrc 
        ON bdrc.CID = dc.RealCID
    LEFT JOIN DWH_dbo.Dim_ScreeningStatus dss 
        ON dss.ScreeningStatusID = dc.ScreeningStatusID
    LEFT JOIN DWH_dbo.Dim_AccountType dat 
        ON dc.AccountTypeID = dat.AccountTypeID
    LEFT JOIN DWH_dbo.Dim_EvMatchStatus dems 
        ON dems.EvMatchStatusID = dc.EvMatchStatus
    LEFT JOIN DWH_dbo.Dim_Country dc2 
        ON dc2.DWHCountryID = dc.CitizenshipCountryID
    LEFT JOIN DWH_dbo.Dim_Country dc3 
        ON dc3.DWHCountryID = dc.POBCountryID
    LEFT JOIN DWH_dbo.Dim_PlayerStatusReasons dpsr 
        ON dc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
    LEFT JOIN DWH_dbo.Dim_PlayerStatusSubReasons dpssr 
        ON dc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID
    WHERE dc.IsValidCustomer = 1
      AND dc.IsDepositor = 1
      AND dc.VerificationLevelID = 3
) pp
LEFT JOIN (
    SELECT 
        vl.CID,
        ISNULL(vl.Liabilities, 0) + ISNULL(vl.ActualNWA, 0) AS Equity
    FROM DWH_dbo.V_Liabilities vl
    WHERE vl.DateID = CAST(CONVERT(CHAR(8), GETDATE() - 1, 112) AS INT)
) eq ON pp.CID = eq.CID
LEFT JOIN (
    SELECT 
        fca.RealCID AS CID,
        SUM(fca.Amount) AS Total_Deposits
    FROM DWH_dbo.Fact_CustomerAction fca
    WHERE fca.ActionTypeID = 7
    GROUP BY fca.RealCID
) dp ON pp.CID = dp.CID