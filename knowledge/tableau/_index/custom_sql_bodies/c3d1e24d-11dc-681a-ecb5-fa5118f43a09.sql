SELECT 
    dc.RealCID AS CID, 
    cr.CountryName,     
    dm.FirstName + ' ' + dm.LastName AS AM_FullName, 
    CASE 
        WHEN mda.CID IS NOT NULL AND mda.CurrencyBalanceStatusID IS NULL THEN 'Active'
        WHEN mda.CID IS NOT NULL AND mda.CurrencyBalanceStatusID IS NOT NULL THEN mda.CurrencyBalanceStatus
        WHEN mda.CID IS NULL THEN 'non-iban-holder'
    END AS CurrencyBalanceStatusDisplay, 
    CASE WHEN dc.GuruStatusID > 1 THEN 'PI' ELSE 'Not PI' END AS Validation_Field_Is_PI,
    last_instance_table.LastInstanceCreatedDate AS LastInstanceOrderDate, 
    last_instance_table.LastInstanceActivationDate, 
    last_instance_table.LastInstanceStatus, 
    CASE WHEN last_instance_table.LastInstanceCreatedDate IS NOT NULL THEN 'Yes' ELSE 'No' END AS Is_Card_Ordered, 
    CASE WHEN last_instance_table.LastInstanceStatus = 'Activated' AND last_instance_table.LastInstanceActivationDate IS NOT NULL THEN 'Yes' ELSE 'No' END AS Is_Card_Active, 
    dpl.Name AS Club
FROM DWH_dbo.Dim_Customer dc
JOIN (
    SELECT * 
    FROM eMoney_dbo.eMoney_Dim_Account a 
    WHERE a.AccountSubProgramID IN (5, 6, 7, 11, 12, 9) 
      AND a.IsValidETM = 1 
      AND a.GCID_Unique_Count = 1
) z 
    ON dc.RealCID = z.CID
JOIN DWH_dbo.Dim_PlayerLevel dpl 
    ON dc.PlayerLevelID = dpl.PlayerLevelID
INNER JOIN eMoney_dbo.eMoney_Dim_Country_Rollout cr 
    ON dc.CountryID = cr.CountryID
INNER JOIN DWH_dbo.Dim_Country dc1 
    ON dc.CountryID = dc1.CountryID    
    AND dc1.CountryID IN (
        SELECT 165 UNION ALL SELECT 112 UNION ALL SELECT 164 UNION ALL SELECT 168 UNION ALL SELECT 32 UNION ALL 
        SELECT 79 UNION ALL SELECT 143 UNION ALL SELECT 184 UNION ALL SELECT 185 UNION ALL SELECT 95 UNION ALL 
        SELECT 118 UNION ALL SELECT 55 UNION ALL SELECT 100 UNION ALL SELECT 72 UNION ALL SELECT 54 UNION ALL 
        SELECT 191 UNION ALL SELECT 82 UNION ALL SELECT 197 UNION ALL SELECT 52 UNION ALL SELECT 19 UNION ALL 
        SELECT 126 UNION ALL SELECT 102 UNION ALL SELECT 74 UNION ALL SELECT 13 UNION ALL SELECT 117 UNION ALL 
        SELECT 154 UNION ALL SELECT 196 UNION ALL SELECT 57 UNION ALL SELECT 67 UNION ALL SELECT 135 UNION ALL 
        SELECT 119 UNION ALL SELECT 94
    )
LEFT JOIN DWH_dbo.Dim_Manager dm 
    ON dc.AccountManagerID = dm.ManagerID
LEFT JOIN (
    SELECT * 
    FROM eMoney_dbo.eMoney_Dim_Account mda1 
    WHERE mda1.IsValidETM = 1 
      AND mda1.GCID_Unique_Count = 1  
      AND UPPER(mda1.BankAccountIBAN) NOT LIKE 'GB%'
) mda 
    ON dc.RealCID = mda.CID
LEFT JOIN (
    SELECT x.MaskedPAN, 
           x.CID, 
           x.DWH_CardInstanceId, 
           x.InstanceCreatedDate AS LastInstanceCreatedDate, 
           x.InstanceActivationDate AS LastInstanceActivationDate,
           x.InstanceStatus AS LastInstanceStatus 
    FROM (
        SELECT ROW_NUMBER() OVER (PARTITION BY CID ORDER BY InstanceCreatedDate DESC) AS rnk_instance_desc, *  
        FROM eMoney_dbo.eMoney_Card_Instance_Summary 
    ) x 
    WHERE x.rnk_instance_desc = 1 
) last_instance_table 
    ON dc.RealCID = last_instance_table.CID
WHERE 
    dc.AccountTypeID = 1                -- Private account
    AND dc.PlayerLevelID IN (6, 7)      -- Diamond Club / Plat Plus 
    AND dc.IsValidCustomer = 1          -- Eligible definition 
    AND (dc.GuruStatusID < 1 OR dc.GuruStatusID IS NULL) -- Exclude PI customers
    AND DATEDIFF(DAY, CAST(dc.FirstDepositDate AS DATE), GETDATE() - 1) > 14