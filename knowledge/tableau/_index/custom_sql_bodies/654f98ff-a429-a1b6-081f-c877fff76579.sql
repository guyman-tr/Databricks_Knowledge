/********************************************
   PART 1 — Club-level rows
********************************************/
SELECT
    CASE dc.CountryID
        WHEN 74 THEN 'France'
        WHEN 191 THEN 'Spain'
    END AS Country,
    
    dpl.Name AS Club,

    COUNT(DISTINCT dc.RealCID) AS Number_Clients,
    COUNT(DISTINCT b.CID_int) AS Changed_Default,

    CAST(
        ROUND(
            1.0 * COUNT(DISTINCT b.CID_int)
            / NULLIF(COUNT(DISTINCT dc.RealCID), 0)
        , 2
        ) AS DECIMAL(10,4)
    ) AS Pct_Changed_Default

FROM DWH_dbo.Dim_Customer dc
JOIN eMoney_dbo.eMoney_Dim_Account mda
    ON mda.CID = dc.RealCID
   AND mda.GCID_Unique_Count = 1
   AND mda.IsValidETM = 1
JOIN (
        SELECT DISTINCT CID 
        FROM DWH_dbo.Dim_Position 
        WHERE OpenDateID >= 20251015
           OR CloseDateID >= 20251015
     ) gp
    ON gp.CID = dc.RealCID
JOIN DWH_dbo.Dim_PlayerLevel dpl
    ON dpl.PlayerLevelID = dc.PlayerLevelID
LEFT JOIN (
        SELECT TRY_CONVERT(INT, CID) AS CID_int
        FROM BI_DB_dbo.BI_DB_dbo_External_LC_Filter
        WHERE CID NOT LIKE '%[^0-9]%'
     ) b
    ON b.CID_int = dc.RealCID
WHERE dc.IsValidCustomer = 1
  AND dc.CountryID IN (74, 191)
GROUP BY
    dc.CountryID,
    dpl.Name


UNION ALL


/********************************************
   PART 2 — Country-level totals (Club = 'All')
********************************************/
SELECT
    CASE dc.CountryID
        WHEN 74 THEN 'France'
        WHEN 191 THEN 'Spain'
    END AS Country,
    
    'All' AS Club,

    COUNT(DISTINCT dc.RealCID) AS Number_Clients,
    COUNT(DISTINCT b.CID_int) AS Changed_Default,

    CAST(
        ROUND(
            1.0 * COUNT(DISTINCT b.CID_int)
            / NULLIF(COUNT(DISTINCT dc.RealCID), 0)
        , 2
        ) AS DECIMAL(10,4)
    ) AS Pct_Changed_Default

FROM DWH_dbo.Dim_Customer dc
JOIN eMoney_dbo.eMoney_Dim_Account mda
    ON mda.CID = dc.RealCID
   AND mda.GCID_Unique_Count = 1
   AND mda.IsValidETM = 1
JOIN (
        SELECT DISTINCT CID 
        FROM DWH_dbo.Dim_Position 
        WHERE OpenDateID >= 20251015
           OR CloseDateID >= 20251015
     ) gp
    ON gp.CID = dc.RealCID
LEFT JOIN (
        SELECT TRY_CONVERT(INT, CID) AS CID_int
        FROM BI_DB_dbo.BI_DB_dbo_External_LC_Filter
        WHERE CID NOT LIKE '%[^0-9]%'
     ) b
    ON b.CID_int = dc.RealCID
WHERE dc.IsValidCustomer = 1
  AND dc.CountryID IN (74, 191)
GROUP BY
    dc.CountryID