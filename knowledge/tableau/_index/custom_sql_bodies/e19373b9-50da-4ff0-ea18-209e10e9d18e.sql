SELECT *
FROM (
    -- 1. Match by Full Name and DOB
    SELECT
        dc.RealCID AS CID,
        dc.FirstName,
        dc.LastName,
        dc.MiddleName,
        dc.Address,
        dc.BuildingNumber,
        dc.Zip,
        dc.City,
        CAST(dc.BirthDate AS DATE) AS BirthDate,
        dr.Name AS Regulation,
        dc.VerificationLevelID,
        dpl.Name AS Club,
        dps.Name AS PlayerStatus,
        a.Value AS SSN,
        aa.Value AS TIN_Value, -- העמודה שהוספת
        'Full Name and DOB' AS Indication
    FROM DWH_dbo.Dim_Customer dc
    JOIN DWH_dbo.Dim_Regulation dr ON dr.DWHRegulationID = dc.RegulationID
    JOIN DWH_dbo.Dim_PlayerStatus dps ON dc.PlayerStatusID = dps.PlayerStatusID
    JOIN DWH_dbo.Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
    JOIN BI_DB_dbo.External_Fivetran_google_sheets_us_314_a_person pp
        ON LOWER(dc.FirstName) = LOWER(pp.first_name)
        AND LOWER(dc.LastName) = LOWER(pp.last_name)
        AND CAST(dc.BirthDate AS DATE) = CAST(pp.dob AS DATE)
    LEFT JOIN [BI_DB_dbo].[External_UserApiDB_Customer_ExtendedUserField] a ON dc.GCID = a.GCID AND a.FieldId = 6 AND a.CountryId = 219
    LEFT JOIN [BI_DB_dbo].[External_UserApiDB_Customer_ExtendedUserField] aa ON dc.GCID = aa.GCID AND aa.FieldId = 3 AND aa.CountryId = 219 -- תיקנתי ל-FieldId

    UNION ALL

    -- 2. Match by Address
    SELECT
        dc.RealCID AS CID,
        dc.FirstName,
        dc.LastName,
        dc.MiddleName,
        dc.Address,
        dc.BuildingNumber,
        dc.Zip,
        dc.City,
        CAST(dc.BirthDate AS DATE) AS BirthDate,
        dr.Name AS Regulation,
        dc.VerificationLevelID,
        dpl.Name AS Club,
        dps.Name AS PlayerStatus,
        a.Value AS SSN,
        NULL AS TIN_Value, -- חייב להופיע כדי לשמור על מבנה אחיד
        'Address' AS Indication
    FROM DWH_dbo.Dim_Customer dc
    JOIN DWH_dbo.Dim_Regulation dr ON dr.DWHRegulationID = dc.RegulationID
    JOIN DWH_dbo.Dim_PlayerStatus dps ON dc.PlayerStatusID = dps.PlayerStatusID
    JOIN DWH_dbo.Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
    JOIN BI_DB_dbo.External_Fivetran_google_sheets_us_314_a_person pp
        ON UPPER(dc.Address) = UPPER(pp.street)
        AND UPPER(dc.City) = UPPER(pp.city)
        AND UPPER(dc.Zip) = UPPER(pp.zip)
    LEFT JOIN [BI_DB_dbo].[External_UserApiDB_Customer_ExtendedUserField] a ON dc.GCID = a.GCID AND a.FieldId = 6 AND a.CountryId = 219

    UNION ALL

    -- 3. Match by POI value
    SELECT
        dc.RealCID AS CID,
        dc.FirstName,
        dc.LastName,
        dc.MiddleName,
        dc.Address,
        dc.BuildingNumber,
        dc.Zip,
        dc.City,
        CAST(dc.BirthDate AS DATE) AS BirthDate,
        dr.Name AS Regulation,
        dc.VerificationLevelID,
        dpl.Name AS Club,
        dps.Name AS PlayerStatus,
        a.Value AS SSN,
        NULL AS TIN_Value,
        'POI Match' AS Indication
    FROM BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField uce
    JOIN BI_DB_dbo.External_Fivetran_google_sheets_us_314_a_person pp
        ON uce.Value = pp.number COLLATE Latin1_General_100_BIN
    JOIN DWH_dbo.Dim_Customer dc ON dc.GCID = uce.GCID
    JOIN DWH_dbo.Dim_Regulation dr ON dr.DWHRegulationID = dc.RegulationID
    JOIN DWH_dbo.Dim_PlayerStatus dps ON dc.PlayerStatusID = dps.PlayerStatusID
    JOIN DWH_dbo.Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
    LEFT JOIN [BI_DB_dbo].[External_UserApiDB_Customer_ExtendedUserField] a ON dc.GCID = a.GCID AND a.FieldId = 6 AND a.CountryId = 219

    UNION ALL

    -- 4. Match by TIN
    SELECT
        dc.RealCID AS CID,
        dc.FirstName,
        dc.LastName,
        dc.MiddleName,
        dc.Address,
        dc.BuildingNumber,
        dc.Zip,
        dc.City,
        CAST(dc.BirthDate AS DATE) AS BirthDate,
        dr.Name AS Regulation,
        dc.VerificationLevelID,
        dpl.Name AS Club,
        dps.Name AS PlayerStatus,
        a.Value AS SSN, -- החזרתי לשם העמודה SSN כדי שיהיה אחיד
        euadceuf.Value AS TIN_Value,
        'TIN' AS Indication
    FROM DWH_dbo.Dim_Customer dc
    JOIN BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField euadceuf ON dc.GCID = euadceuf.GCID
    JOIN DWH_dbo.Dim_ExtendedUserField deuf ON euadceuf.FieldId = deuf.FieldID 
    JOIN BI_DB_dbo.External_Fivetran_google_sheets_us_314_a_person pp 
        ON euadceuf.Value = pp.number COLLATE Latin1_General_100_BIN
    JOIN DWH_dbo.Dim_Regulation dr ON dr.DWHRegulationID = dc.RegulationID
    JOIN DWH_dbo.Dim_PlayerStatus dps ON dc.PlayerStatusID = dps.PlayerStatusID
    JOIN DWH_dbo.Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
    LEFT JOIN [BI_DB_dbo].[External_UserApiDB_Customer_ExtendedUserField] a ON dc.GCID = a.GCID AND a.FieldId = 6 AND a.CountryId = 219
    WHERE deuf.FieldTypeID = 3 AND euadceuf.CountryId = 219

    UNION ALL

    -- 5. Match by SSN
    SELECT
        dc.RealCID AS CID,
        dc.FirstName,
        dc.LastName,
        dc.MiddleName,
        dc.Address,
        dc.BuildingNumber,
        dc.Zip,
        dc.City,
        CAST(dc.BirthDate AS DATE) AS BirthDate,
        dr.Name AS Regulation,
        dc.VerificationLevelID,
        dpl.Name AS Club,
        dps.Name AS PlayerStatus,
        a.Value AS SSN,
        NULL AS TIN_Value,
        'SSN' AS Indication
    FROM BI_DB_dbo.BI_DB_USA_FinanceReport_forTax cc
    JOIN DWH_dbo.Dim_Customer dc ON cc.RealCID = dc.RealCID
    JOIN DWH_dbo.Dim_Regulation dr ON dr.DWHRegulationID = dc.RegulationID
    JOIN DWH_dbo.Dim_PlayerStatus dps ON dc.PlayerStatusID = dps.PlayerStatusID
    JOIN DWH_dbo.Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
    JOIN BI_DB_dbo.External_Fivetran_google_sheets_us_314_a_person pp
        ON cc.SSN = pp.number COLLATE Latin1_General_100_BIN
    LEFT JOIN [BI_DB_dbo].[External_UserApiDB_Customer_ExtendedUserField] a ON dc.GCID = a.GCID AND a.FieldId = 6 AND a.CountryId = 219
) AS CombinedMatches