SELECT 
    ca.RealCID,
    -ca.Amount as Amount,
    ca.DateID,
    ca.ActionTypeID,
    ca.IsFeeDividend,
    ca.DateOccurred,
    TRY_CAST(ca.InstrumentID AS INT) AS InstrumentID, -- Attempt to convert only numeric values
    di.Name AS Instrument,
    Description,
    dr1.Name AS Regulation,
    fsc.IsCreditReportValidCB,
    fsc.IsValidCustomer,
    'CAInCreditType14' AS IssueType
FROM 
(
    SELECT
        fca.RealCID,
        fca.Amount,
        fca.DateID,
        fca.[Description],
        fca.ActionTypeID,
        fca.IsFeeDividend,
        CAST(fca.Occurred AS DATE) AS DateOccurred,
        CASE 
            WHEN CHARINDEX('Instrument=', fca.[Description]) > 0 THEN 
                SUBSTRING(
                    fca.[Description], 
                    CHARINDEX('Instrument=', fca.[Description]) + LEN('Instrument='), 
                    CHARINDEX(':', fca.[Description] + ':', CHARINDEX('Instrument=', fca.[Description])) 
                        - CHARINDEX('Instrument=', fca.[Description]) - LEN('Instrument=')
                )
            ELSE NULL
        END AS InstrumentID
    FROM DWH_dbo.Fact_CustomerAction fca
    WHERE fca.DateID > 20240930 
      AND fca.DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE), 'yyyyMMdd') AS INT)   
                           AND CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE), 'yyyyMMdd') AS INT)
      AND LOWER(fca.[Description]) LIKE '%ca type%'
      AND LOWER(fca.[Description]) NOT LIKE '%dividen%'
) ca
JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON ca.RealCID = fsc.RealCID
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND ca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Regulation dr1 ON fsc.RegulationID = dr1.DWHRegulationID
JOIN DWH_dbo.Dim_Instrument di ON TRY_CAST(ca.InstrumentID AS INT) = di.InstrumentID

UNION ALL 

SELECT 
    ca.RealCID,
    -ca.Amount as Amount,    ca.DateID,
    ca.ActionTypeID,
    ca.IsFeeDividend,
    ca.DateOccurred,
    TRY_CAST(ca.InstrumentID AS INT) AS InstrumentID, -- Attempt to convert only numeric values
    di.Name AS Instrument,
    Description,
    dr1.Name AS Regulation,
    fsc.IsCreditReportValidCB,
    fsc.IsValidCustomer,
    'USRegWithOvernight' AS IssueType
FROM 
(
    SELECT
        fca.RealCID,
        fca.Amount,
        fca.DateID,
        fca.[Description],
        fca.ActionTypeID,
        fca.IsFeeDividend,
        CAST(fca.Occurred AS DATE) AS DateOccurred,
        CASE 
            WHEN CHARINDEX('Instrument=', fca.[Description]) > 0 THEN 
                SUBSTRING(
                    fca.[Description], 
                    CHARINDEX('Instrument=', fca.[Description]) + LEN('Instrument='), 
                    CHARINDEX(':', fca.[Description] + ':', CHARINDEX('Instrument=', fca.[Description])) 
                        - CHARINDEX('Instrument=', fca.[Description]) - LEN('Instrument=')
                )
            ELSE NULL
        END AS InstrumentID
    FROM DWH_dbo.Fact_CustomerAction fca
    WHERE fca.DateID > 20240930 
      AND fca.DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE), 'yyyyMMdd') AS INT)   
                           AND CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE), 'yyyyMMdd') AS INT)
      AND fca.ActionTypeID = 35
      AND (LOWER(fca.[Description]) LIKE '%over%' OR LOWER(fca.[Description]) LIKE '%weekend%')
) ca
JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON ca.RealCID = fsc.RealCID
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND ca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Regulation dr1 ON fsc.RegulationID = dr1.DWHRegulationID
LEFT JOIN DWH_dbo.Dim_Instrument di ON TRY_CAST(ca.InstrumentID AS INT) = di.InstrumentID
WHERE fsc.RegulationID IN (6, 7, 8)
  AND fsc.IsCreditReportValidCB = 1