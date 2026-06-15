SELECT 
      rr.RiskScore_Explanation
    , dr.Name AS Regulation
    , rr.PreviousRiskScore
    , rr.RiskScoreName
    , rr.GCID
    , rr.CID
    , dc.HasWallet
    , bdasec.AML_Sub_Entity
    , dc1.RiskGroupID
    , dc1.Name AS Country
    , dps.Name AS PlayerStatus
    , dpl.Name AS Club	  
    , dc.VerificationLevelID
    , SUM(vl.Liabilities + vl.ActualNWA) AS Equity
    , COALESCE(dep.Total_Deposits, 0) AS Total_Deposits
    , COALESCE(co.Total_CO, 0) AS Total_CO
FROM [BI_DB_dbo].[External_RiskClassification_dbo_V_RiskClassificationDataLake] rr
JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID = rr.CID
JOIN DWH_dbo.Dim_Regulation dr ON dr.DWHRegulationID = dc.RegulationID
JOIN DWH_dbo.Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
JOIN DWH_dbo.Dim_PlayerStatus dps ON dc.PlayerStatusID = dps.PlayerStatusID 
    AND dps.PlayerStatusID NOT IN (2,4)
JOIN DWH_dbo.Dim_Country dc1 ON dc1.DWHCountryID = dc.CountryID
LEFT JOIN BI_DB_dbo.BI_DB_AML_SubEntity_Categorization bdasec 
    ON dc.RealCID = bdasec.CID
LEFT JOIN DWH_dbo.V_Liabilities vl 
    ON vl.CID = dc.RealCID 
    AND vl.DateID = CAST(CONVERT(CHAR(8),GETDATE()-1,112) AS INT)

-- Replace CTEs with Subqueries in LEFT JOINs
LEFT JOIN (
    SELECT fca.RealCID AS CID, SUM(fca.Amount) AS Total_Deposits
    FROM DWH_dbo.Fact_CustomerAction fca
    WHERE fca.ActionTypeID = 7 -- Deposits
    GROUP BY fca.RealCID
) dep ON dep.CID = dc.RealCID

LEFT JOIN (
    SELECT fca.RealCID AS CID, SUM(fca.Amount) AS Total_CO
    FROM DWH_dbo.Fact_CustomerAction fca
    WHERE fca.ActionTypeID = 8 -- CO
    GROUP BY fca.RealCID
) co ON co.CID = dc.RealCID

WHERE dc.IsValidCustomer = 1
AND dc.IsDepositor = 1
AND dc.VerificationLevelID > 1
GROUP BY 
      rr.RiskScore_Explanation
    , dr.Name 
    , rr.PreviousRiskScore	  
    , rr.RiskScoreName
    , rr.GCID
    , rr.CID
    , dc.HasWallet
    , bdasec.AML_Sub_Entity
    , dc1.RiskGroupID
    , dc1.Name 
    , dps.Name
    , dpl.Name   
    , dc.VerificationLevelID
    , dep.Total_Deposits
    , co.Total_CO