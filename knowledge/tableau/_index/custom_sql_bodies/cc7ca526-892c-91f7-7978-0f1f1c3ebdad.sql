-- This query combines data from multiple tables and calculates fees.
-- It is structured as a single derived table to be used in a custom SQL query builder,
-- such as the one in Tableau.

SELECT 
    SUM(CombinedData.GrossAmount) AS GrossAmount,
    MAX(CombinedData.[GST/VAT rate]) AS Rate,
    CombinedData.[Key],
    CombinedData.Country,
    CombinedData.Regulation,
	CombinedData.DateID,
	CombinedData.IsSettled
FROM
    (
    -- The first part of the UNION ALL calculates the Gross Ticketing Fee.
    -- This section has 9 columns.
   ----------------------------------------------------------------------------------------------------
SELECT 
        frtf.DateID,
        frtf.RealCID,
        frtf.IsCreditReportValidCB,
        dr.Name AS Regulation,
        dc.Name AS Country,
        frtf.TicketFee * -1 AS GrossAmount,
        CASE 
            WHEN frtf.RegulationID IN (4, 10) AND frtf.CountryID = 12 THEN 0.1
            WHEN frtf.RegulationID IN (11) AND frtf.CountryID = 217 THEN 0.05
            WHEN frtf.RegulationID IN (13) AND frtf.CountryID = 183 THEN 0.09
            ELSE 0 
        END AS 'GST/VAT rate',
        'TicketFee' AS 'Key',
		IsSettled
    FROM 
       BI_DB_dbo.Function_Revenue_TicketFee(
    CAST(CONVERT(VARCHAR(8), TRY_CONVERT(date, <[Parameters].[Parameter 1]>), 112) AS INT),
    CAST(CONVERT(VARCHAR(8), TRY_CONVERT(date, <[Parameters].[Parameter 2]>),   112) AS INT),
    1
) frtf
	   JOIN DWH_dbo.Dim_Country dc on dc.CountryID = frtf.CountryID
	   JOIN DWH_dbo.Dim_Regulation dr on dr.DWHRegulationID =  frtf.RegulationID

Union ALL 

SELECT 
        frtf.DateID,
        frtf.RealCID,
        frtf.IsCreditReportValidCB,
        dr.Name AS Regulation,
        dc.Name AS Country,
        frtf.TicketFeeByPercent * -1 AS GrossAmount,
        CASE 
            WHEN frtf.RegulationID IN (4, 10) AND frtf.CountryID = 12 THEN 0.1
            WHEN frtf.RegulationID IN (11) AND frtf.CountryID = 217 THEN 0.05
            WHEN frtf.RegulationID IN (13) AND frtf.CountryID = 183 THEN 0.09
            ELSE 0 
        END AS 'GST/VAT rate',
        'TicketFeeByPercent' AS 'Key',
		IsSettled
    FROM 
       BI_DB_dbo.Function_Revenue_TicketFeeByPercent(
    CAST(CONVERT(VARCHAR(8), TRY_CONVERT(date, <[Parameters].[Parameter 1]>), 112) AS INT),
    CAST(CONVERT(VARCHAR(8), TRY_CONVERT(date, <[Parameters].[Parameter 2]>),   112) AS INT),
    1
) frtf
	   JOIN DWH_dbo.Dim_Country dc on dc.CountryID = frtf.CountryID
	   JOIN DWH_dbo.Dim_Regulation dr on dr.DWHRegulationID =  frtf.RegulationID
	   --------------------------------------------------------------------------------------

    UNION ALL

    -- The following subquery aggregates the Dorman, Islamic, and Cashout fees.
    -- Each subsequent UNION ALL will select from this aggregated data.
    SELECT
        CombinedFees.DateID,
        CombinedFees.RealCID,
        CombinedFees.[IsCreditValidReport],
        CombinedFees.Regulation,
        'Singapore' AS Country,
        CombinedFees.GrossAmount,
        CombinedFees.[GST/VAT rate],
        CombinedFees.[Key],
		Null AS 'IsSettled'
    FROM
        (
        SELECT
            SUM(a.TotalDormantFee) AS DormanFee,
            SUM(a.IslamicFee) AS IslamicFee,
            SUM(a.CashoutFee) AS CashoutFee,
            a.RealCID,
            a.Date,
            CAST(CONVERT(VARCHAR(8), a.Date, 112) AS INT) AS DateID,
            a.Regulation,
            CASE WHEN a.Regulation = 'MAS' THEN 0.09 ELSE 0 END AS 'GST/VAT rate',
            '1' AS 'IsCreditValidReport'
        FROM 
            BI_DB_dbo.BI_DB_GST_Report a
        WHERE 
            a.Date BETWEEN   <[Parameters].[Parameter 1]> AND <[Parameters].[Parameter 2]>
        GROUP BY
            a.RealCID,
            a.Date,
            a.Regulation
        ) AS Pop2
    UNPIVOT (
        GrossAmount FOR [Key] IN (DormanFee, IslamicFee, CashoutFee)
    ) AS CombinedFees
    ) AS CombinedData
GROUP BY 
    CombinedData.[Key], 
    CombinedData.Country, 
    CombinedData.Regulation, 
    CombinedData.DateID,
	CombinedData.IsSettled