SELECT 
    bc.RealCID,
    bc.VerificationLevelID,
    dc.Name as Country,
    ev.EvMatchStatusName as EvMatchStatus,
    ps.Name as PlayerStatus,
    ds.Name as RiskStatus,
    bc.IsAddressProof as POA,
    bc.IsIDProof as POI,
    dr.Name as Regulation,
    pc.PendingClosureStatusName,
    [VerificationLevel3Date],
    fd.RealizedEquity,
    at1.Name as AccountType,
    dc.RiskGroupID,
    MAX(CASE WHEN dt.DocumentID IS NOT NULL THEN 1 ELSE 0 END) as ProofOfIncome,
    MAX(CASE WHEN dt1.DocumentID IS NOT NULL THEN 1 ELSE 0 END) as [Selfie (Liveliness or Motion)]
FROM DWH_dbo.Dim_Customer bc
LEFT JOIN DWH_dbo.Dim_Country dc ON dc.CountryID = bc.CountryID
LEFT JOIN DWH_dbo.Dim_PlayerStatus ps ON bc.PlayerStatusID = ps.PlayerStatusID
LEFT JOIN DWH_dbo.Dim_Regulation dr ON bc.RegulationID = dr.ID
LEFT JOIN DWH_dbo.Dim_RiskStatus ds ON bc.RiskStatusID = ds.RiskStatusID
LEFT JOIN DWH_dbo.Dim_PendingClosureStatus pc ON bc.PendingClosureStatusID = pc.PendingClosureStatusID
LEFT JOIN DWH_dbo.Dim_EvMatchStatus ev ON bc.EvMatchStatus = ev.EvMatchStatusID
LEFT JOIN BI_DB_dbo.BI_DB_CIDFirstDates fd ON fd.CID = bc.RealCID
LEFT JOIN DWH_dbo.Dim_AccountType at1 ON at1.AccountTypeID = bc.AccountTypeID
LEFT JOIN BI_DB_dbo.External_etoro_BackOffice_CustomerDocument bcd ON bcd.CID = bc.RealCID
LEFT JOIN BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType dt ON dt.DocumentID = bcd.DocumentID AND dt.DocumentTypeID = 7 -- proof of income
LEFT JOIN BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType dt1 ON dt1.DocumentID = bcd.DocumentID AND dt1.DocumentTypeID IN (18, 23) -- SelfieLiveliness, Selfie Motion
WHERE 
    bc.IsValidCustomer = 1
    AND bc.AccountTypeID NOT IN (15, 6)  -- Affiliates
    AND bc.VerificationLevelID = 3 
    AND EvMatchStatusName NOT IN ('Verified') 
    AND [VerificationLevel3Date] >= '2024-01-01'
    AND bc.PlayerStatusID NOT IN (9)
GROUP BY 
    bc.RealCID,
    ps.Name,
    dc.Name,
    bc.VerificationLevelID,
    dr.Name,
    PendingClosureStatusName,
    ev.EvMatchStatusName,
    ds.Name,
    [VerificationLevel3Date],
    bc.IsAddressProof,
    bc.IsIDProof,
    fd.RealizedEquity,
    at1.Name,
    dc.RiskGroupID
HAVING 
    (
        dc.RiskGroupID <> 3 
        AND (
            MAX(CASE WHEN bc.IsAddressProof IN (1) THEN 1 ELSE 0 END) = 0 
            OR MAX(CASE WHEN bc.IsIDProof IN (1) THEN 1 ELSE 0 END) = 0
        )
    )
    OR
    (
        dc.RiskGroupID = 3 
        AND (
            MAX(CASE WHEN bc.IsAddressProof IN (1) THEN 1 ELSE 0 END) = 0 
            OR MAX(CASE WHEN bc.IsIDProof IN (1) THEN 1 ELSE 0 END) = 0
            OR MAX(CASE WHEN dt.DocumentID IS NOT NULL THEN 1 ELSE 0 END) = 0
            OR MAX(CASE WHEN dt1.DocumentID IS NOT NULL THEN 1 ELSE 0 END) = 0
        )
    )