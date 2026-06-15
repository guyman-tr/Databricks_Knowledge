SELECT
    aa.GCID,
    aa.RealCID AS CID,
    aa.Email,
    aa.City,
    aa.Zip,
    fi.AccountNumber,
    fi.TaxIDNumber,
    fi.CodeDescription,
    fi.AccountName1 AS FullName,
    fi.AddressLine1,
    fi.AddressLine2,
    fi.State,
    fi.ZipCode,
    fi.EmailAddress,
    fi.DateOfBirth,
    pp.first_name,
    pp.last_name,
    pp.dob,
    pp.street,
    pp.city AS pp_city,
    pp.country,
    pp.zip AS pp_zip,
    'Full_Name_Gatsby' AS Indication
FROM BI_DB_dbo.External_Sodreconciliation_apex_EXT1034_NewAccountFinancialInformation fi
LEFT JOIN (
    SELECT op.GCID, dc.RealCID, op.OptionsApexID, dc.BirthDate, dc.Address, dc.City, dc.Zip, dc.Email
    FROM BI_DB_dbo.External_USABroker_Apex_Options op
    JOIN DWH_dbo.Dim_Customer dc ON op.GCID = dc.GCID
) aa ON fi.AccountNumber = aa.OptionsApexID
JOIN BI_DB_dbo.External_Fivetran_google_sheets_us_314_a_person pp 
    ON LOWER(pp.first_name) + ' ' + LOWER(pp.last_name) = LOWER(fi.AccountName1) COLLATE Latin1_General_100_BIN

UNION ALL

SELECT
    aa.GCID,
    aa.RealCID AS CID,
    aa.Email,
    aa.City,
    aa.Zip,
    fi.AccountNumber,
    fi.TaxIDNumber,
    fi.CodeDescription,
    fi.AccountName1 AS FullName,
    fi.AddressLine1,
    fi.AddressLine2,
    fi.State,
    fi.ZipCode,
    fi.EmailAddress,
    fi.DateOfBirth,
    pp.first_name,
    pp.last_name,
    pp.dob,
    pp.street,
    pp.city AS pp_city,
    pp.country,
    pp.zip AS pp_zip,
    'Full_Name_DOB_Gatsby' AS Indication
FROM BI_DB_dbo.External_Sodreconciliation_apex_EXT1034_NewAccountFinancialInformation fi
LEFT JOIN (
    SELECT op.GCID, dc.RealCID, op.OptionsApexID, dc.BirthDate, dc.Address, dc.City, dc.Zip, dc.Email
    FROM BI_DB_dbo.External_USABroker_Apex_Options op
    JOIN DWH_dbo.Dim_Customer dc ON op.GCID = dc.GCID
) aa ON fi.AccountNumber = aa.OptionsApexID
JOIN BI_DB_dbo.External_Fivetran_google_sheets_us_314_a_person pp 
    ON LOWER(pp.first_name) + ' ' + LOWER(pp.last_name) = LOWER(fi.AccountName1) COLLATE Latin1_General_100_BIN
    AND CAST(pp.dob AS DATE) = CAST(fi.DateOfBirth AS DATE)

UNION ALL

SELECT
    aa.GCID,
    aa.RealCID AS CID,
    aa.Email,
    aa.City,
    aa.Zip,
    fi.AccountNumber,
    fi.TaxIDNumber,
    fi.CodeDescription,
    fi.AccountName1 AS FullName,
    fi.AddressLine1,
    fi.AddressLine2,
    fi.State,
    fi.ZipCode,
    fi.EmailAddress,
    fi.DateOfBirth,
    pp.first_name,
    pp.last_name,
    pp.dob,
    pp.street,
    pp.city AS pp_city,
    pp.country,
    pp.zip AS pp_zip,
    'Address_1' AS Indication
FROM BI_DB_dbo.External_Sodreconciliation_apex_EXT1034_NewAccountFinancialInformation fi
LEFT JOIN (
    SELECT op.GCID, dc.RealCID, op.OptionsApexID, dc.BirthDate, dc.Address, dc.City, dc.Zip, dc.Email
    FROM BI_DB_dbo.External_USABroker_Apex_Options op
    JOIN DWH_dbo.Dim_Customer dc ON op.GCID = dc.GCID
) aa ON fi.AccountNumber = aa.OptionsApexID
JOIN BI_DB_dbo.External_Fivetran_google_sheets_us_314_a_person pp 
    ON LOWER(pp.street) = LOWER(fi.AddressLine1) COLLATE Latin1_General_100_BIN

UNION ALL

SELECT
    aa.GCID,
    aa.RealCID AS CID,
    aa.Email,
    aa.City,
    aa.Zip,
    fi.AccountNumber,
    fi.TaxIDNumber,
    fi.CodeDescription,
    fi.AccountName1 AS FullName,
    fi.AddressLine1,
    fi.AddressLine2,
    fi.State,
    fi.ZipCode,
    fi.EmailAddress,
    fi.DateOfBirth,
    pp.first_name,
    pp.last_name,
    pp.dob,
    pp.street,
    pp.city AS pp_city,
    pp.country,
    pp.zip AS pp_zip,
    'Address_2' AS Indication
FROM BI_DB_dbo.External_Sodreconciliation_apex_EXT1034_NewAccountFinancialInformation fi
LEFT JOIN (
    SELECT op.GCID, dc.RealCID, op.OptionsApexID, dc.BirthDate, dc.Address, dc.City, dc.Zip, dc.Email
    FROM BI_DB_dbo.External_USABroker_Apex_Options op
    JOIN DWH_dbo.Dim_Customer dc ON op.GCID = dc.GCID
) aa ON fi.AccountNumber = aa.OptionsApexID
JOIN BI_DB_dbo.External_Fivetran_google_sheets_us_314_a_person pp 
    ON LOWER(pp.street) = LOWER(fi.AddressLine2) COLLATE Latin1_General_100_BIN