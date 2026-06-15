SELECT
    SUM(cbbil.RealizedCommission) AS MetricAmount,
    'RealizedCommission' AS Metric,
    cbbil.Regulation,
    CASE 
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 0 THEN 'CFDStocks'
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 1 THEN 'RealStocks'
        ELSE cbbil.InstrumentType 
    END AS InstrumentType,
    cbbil.DateID,
    NULL AS IsFuture
FROM BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level cbbil
WHERE cbbil.DateID BETWEEN 
    CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 4]>, 120), 112) AS INT)
    AND CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 5]>, 120), 112) AS INT)
    AND cbbil.IsCreditReportValidCB = 1
GROUP BY 
    cbbil.Regulation,
    cbbil.DateID,
    CASE 
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 0 THEN 'CFDStocks'
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 1 THEN 'RealStocks'
        ELSE cbbil.InstrumentType 
    END

UNION ALL

SELECT
    SUM(cbbil.RealizedCommission) + SUM(cbbil.CommissionCloseAdjustment) AS MetricAmount,
    'EntityReportedCommission' AS Metric,
    cbbil.Regulation,
    CASE 
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 0 THEN 'CFDStocks'
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 1 THEN 'RealStocks'
        ELSE cbbil.InstrumentType 
    END AS InstrumentType,
    cbbil.DateID,
    NULL AS IsFuture
FROM BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level cbbil
WHERE cbbil.DateID BETWEEN 
    CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 4]>, 120), 112) AS INT)
    AND CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 5]>, 120), 112) AS INT)
    AND cbbil.IsCreditReportValidCB = 1
GROUP BY 
    cbbil.Regulation,
    cbbil.DateID,
    CASE 
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 0 THEN 'CFDStocks'
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 1 THEN 'RealStocks'
        ELSE cbbil.InstrumentType 
    END

UNION ALL

SELECT
    SUM(cbbil.RealizedFullCommission) + SUM(cbbil.FullCommissionCloseAdjustment) AS MetricAmount,
    'FullCommission(IncAdj)' AS Metric,
    cbbil.Regulation,
    CASE 
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 0 THEN 'CFDStocks'
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 1 THEN 'RealStocks'
        ELSE cbbil.InstrumentType 
    END AS InstrumentType,
    cbbil.DateID,
    NULL AS IsFuture
FROM BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level cbbil
WHERE cbbil.DateID BETWEEN 
    CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 4]>, 120), 112) AS INT)
    AND CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 5]>, 120), 112) AS INT)
    AND cbbil.IsCreditReportValidCB = 1
GROUP BY 
    cbbil.Regulation,
    cbbil.DateID,
    CASE 
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 0 THEN 'CFDStocks'
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 1 THEN 'RealStocks'
        ELSE cbbil.InstrumentType 
    END

UNION ALL

SELECT
    SUM(cbbil.RealizedFullCommission) AS MetricAmount,
    'RealizedFullCommission' AS Metric,
    cbbil.Regulation,
    CASE 
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 0 THEN 'CFDStocks'
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 1 THEN 'RealStocks'
        ELSE cbbil.InstrumentType 
    END AS InstrumentType,
    cbbil.DateID,
    NULL AS IsFuture
FROM BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level cbbil
WHERE cbbil.DateID BETWEEN 
    CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 4]>, 120), 112) AS INT)
    AND CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 5]>, 120), 112) AS INT)
    AND cbbil.IsCreditReportValidCB = 1
GROUP BY 
    cbbil.Regulation,
    cbbil.DateID,
    CASE 
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 0 THEN 'CFDStocks'
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 1 THEN 'RealStocks'
        ELSE cbbil.InstrumentType 
    END

UNION ALL

SELECT
    SUM(cbbil.CommissionCloseAdjustment) AS MetricAmount,
    'CommissionCloseAdjustment' AS Metric,
    cbbil.Regulation,
    CASE 
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 0 THEN 'CFDStocks'
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 1 THEN 'RealStocks'
        ELSE cbbil.InstrumentType 
    END AS InstrumentType,
    cbbil.DateID,
    NULL AS IsFuture
FROM BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level cbbil
WHERE cbbil.DateID BETWEEN 
    CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 4]>, 120), 112) AS INT)
    AND CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 5]>, 120), 112) AS INT)
    AND cbbil.IsCreditReportValidCB = 1
GROUP BY 
    cbbil.Regulation,
    cbbil.DateID,
    CASE 
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 0 THEN 'CFDStocks'
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 1 THEN 'RealStocks'
        ELSE cbbil.InstrumentType 
    END

UNION ALL

SELECT
    SUM(cbbil.FullCommissionCloseAdjustment) AS MetricAmount,
    'FullCommissionCloseAdjustment' AS Metric,
    cbbil.Regulation,
    CASE 
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 0 THEN 'CFDStocks'
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 1 THEN 'RealStocks'
        ELSE cbbil.InstrumentType 
    END AS InstrumentType,
    cbbil.DateID,
    NULL AS IsFuture
FROM BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level cbbil
WHERE cbbil.DateID BETWEEN 
    CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 4]>, 120), 112) AS INT)
    AND CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 5]>, 120), 112) AS INT)
    AND cbbil.IsCreditReportValidCB = 1
GROUP BY 
    cbbil.Regulation,
    cbbil.DateID,
    CASE 
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 0 THEN 'CFDStocks'
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 1 THEN 'RealStocks'
        ELSE cbbil.InstrumentType 
    END

UNION ALL

SELECT
    SUM(cbbil.TicketFeeByPercentOnClose) AS MetricAmount,
    'TicketFeeByPercentOnClose' AS Metric,
    cbbil.Regulation,
    CASE 
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 0 THEN 'CFDStocks'
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 1 THEN 'RealStocks'
        ELSE cbbil.InstrumentType 
    END AS InstrumentType,
    cbbil.DateID,
    NULL AS IsFuture
FROM BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level cbbil
WHERE cbbil.DateID BETWEEN 
    CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 4]>, 120), 112) AS INT)
    AND CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 5]>, 120), 112) AS INT)
    AND cbbil.IsCreditReportValidCB = 1
GROUP BY 
    cbbil.Regulation,
    cbbil.DateID,
    CASE 
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 0 THEN 'CFDStocks'
        WHEN cbbil.InstrumentType = 'Stocks' AND cbbil.IsSettled = 1 THEN 'RealStocks'
        ELSE cbbil.InstrumentType 
    END

UNION ALL

SELECT 
    SUM(frtf.TicketFee) AS MetricAmount,
    'TicketFee' AS Metric,
    dr.Name AS Regulation,
    CASE 
        WHEN di.InstrumentType = 'Stocks' AND frtf.IsSettled = 0 THEN 'CFDStocks'
        WHEN di.InstrumentType = 'Stocks' AND frtf.IsSettled = 1 THEN 'RealStocks'
        ELSE di.InstrumentType 
    END AS InstrumentType,
    frtf.DateID,
    frtf.IsFuture
FROM BI_DB_dbo.Function_Revenue_TicketFee(
    CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 4]>, 120), 112) AS INT),
    CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 5]>, 120), 112) AS INT),
    1
) frtf
JOIN DWH_dbo.Dim_Regulation dr ON dr.DWHRegulationID = frtf.RegulationID
JOIN DWH_dbo.Dim_Instrument di ON frtf.InstrumentID = di.InstrumentID
WHERE frtf.IsCreditReportValidCB = 1
GROUP BY 
    dr.Name,
    CASE 
        WHEN di.InstrumentType = 'Stocks' AND frtf.IsSettled = 0 THEN 'CFDStocks'
        WHEN di.InstrumentType = 'Stocks' AND frtf.IsSettled = 1 THEN 'RealStocks'
        ELSE di.InstrumentType 
    END,
    frtf.DateID,
    frtf.IsFuture




union ALL 

SELECT 
    SUM(frtf.VolumeOpen) AS MetricAmount,
    'VolumeOpen' AS Metric,
    dr.Name AS Regulation,
    CASE 
        WHEN di.InstrumentType = 'Stocks' AND frtf.IsSettled = 0 THEN 'CFDStocks'
        WHEN di.InstrumentType = 'Stocks' AND frtf.IsSettled = 1 THEN 'RealStocks'
        ELSE di.InstrumentType 
    END AS InstrumentType,
    frtf.DateID,
    frtf.IsFuture
FROM BI_DB_dbo.Function_Trading_Volume(
    CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 4]>, 120), 112) AS INT),
    CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 5]>, 120), 112) AS INT),
    1
) frtf
inner join DWH_dbo.Fact_SnapshotCustomer fsc
ON fsc.RealCID = frtf.CID
INNER join DWH_dbo.Dim_Range dr1 ON dr1.DateRangeID = fsc.DateRangeID
AND frtf.DateID BETWEEN dr1.FromDateID AND dr1.ToDateID
JOIN DWH_dbo.Dim_Regulation dr ON dr.DWHRegulationID = fsc.RegulationID
JOIN DWH_dbo.Dim_Instrument di ON frtf.InstrumentID = di.InstrumentID
WHERE fsc.IsCreditReportValidCB = 1
GROUP BY 
    dr.Name,
    CASE 
        WHEN di.InstrumentType = 'Stocks' AND frtf.IsSettled = 0 THEN 'CFDStocks'
        WHEN di.InstrumentType = 'Stocks' AND frtf.IsSettled = 1 THEN 'RealStocks'
        ELSE di.InstrumentType 
    END,
    frtf.DateID,
    frtf.IsFuture

-- (Same change applies for the Function_Trading_Volume parts that follow)



union ALL 

SELECT 
    SUM(frtf.VolumeClose) AS MetricAmount,
    'VolumeClose' AS Metric,
    dr.Name AS Regulation,
    CASE 
        WHEN di.InstrumentType = 'Stocks' AND frtf.IsSettled = 0 THEN 'CFDStocks'
        WHEN di.InstrumentType = 'Stocks' AND frtf.IsSettled = 1 THEN 'RealStocks'
        ELSE di.InstrumentType 
    END AS InstrumentType,
    frtf.DateID,
    frtf.IsFuture
FROM BI_DB_dbo.Function_Trading_Volume(
    CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 4]>, 120), 112) AS INT),
    CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 5]>, 120), 112) AS INT),
    1
) frtf
inner join DWH_dbo.Fact_SnapshotCustomer fsc
ON fsc.RealCID = frtf.CID
INNER join DWH_dbo.Dim_Range dr1 ON dr1.DateRangeID = fsc.DateRangeID
AND frtf.DateID BETWEEN dr1.FromDateID AND dr1.ToDateID
JOIN DWH_dbo.Dim_Regulation dr ON dr.DWHRegulationID = fsc.RegulationID
JOIN DWH_dbo.Dim_Instrument di ON frtf.InstrumentID = di.InstrumentID
WHERE fsc.IsCreditReportValidCB = 1
GROUP BY 
    dr.Name,
    CASE 
        WHEN di.InstrumentType = 'Stocks' AND frtf.IsSettled = 0 THEN 'CFDStocks'
        WHEN di.InstrumentType = 'Stocks' AND frtf.IsSettled = 1 THEN 'RealStocks'
        ELSE di.InstrumentType 
    END,
    frtf.DateID,
    frtf.IsFuture

union ALL 

SELECT 
    SUM(frtf.TotalVolume) AS MetricAmount,
    'TotalVolume' AS Metric,
    dr.Name AS Regulation,
    CASE 
        WHEN di.InstrumentType = 'Stocks' AND frtf.IsSettled = 0 THEN 'CFDStocks'
        WHEN di.InstrumentType = 'Stocks' AND frtf.IsSettled = 1 THEN 'RealStocks'
        ELSE di.InstrumentType 
    END AS InstrumentType,
    frtf.DateID,
    frtf.IsFuture
FROM BI_DB_dbo.Function_Trading_Volume(
    CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 4]>, 120), 112) AS INT),
    CAST(CONVERT(varchar(8), CONVERT(datetime, <[Parameters].[Parameter 5]>, 120), 112) AS INT),
    1
) frtf
inner join DWH_dbo.Fact_SnapshotCustomer fsc
ON fsc.RealCID = frtf.CID
INNER join DWH_dbo.Dim_Range dr1 ON dr1.DateRangeID = fsc.DateRangeID
AND frtf.DateID BETWEEN dr1.FromDateID AND dr1.ToDateID
JOIN DWH_dbo.Dim_Regulation dr ON dr.DWHRegulationID = fsc.RegulationID
JOIN DWH_dbo.Dim_Instrument di ON frtf.InstrumentID = di.InstrumentID
WHERE fsc.IsCreditReportValidCB = 1
GROUP BY 
    dr.Name,
    CASE 
        WHEN di.InstrumentType = 'Stocks' AND frtf.IsSettled = 0 THEN 'CFDStocks'
        WHEN di.InstrumentType = 'Stocks' AND frtf.IsSettled = 1 THEN 'RealStocks'
        ELSE di.InstrumentType 
    END,
    frtf.DateID,
    frtf.IsFuture