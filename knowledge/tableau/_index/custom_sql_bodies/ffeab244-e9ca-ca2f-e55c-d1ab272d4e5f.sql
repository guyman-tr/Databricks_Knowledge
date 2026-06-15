SELECT 'DDRLag1Month' as Period,
    'BI_DB_DDR_Fact_Revenue_Generating_Actions' AS TableName,
    'Compare to Staking Results' AS Test,
    a.SourceMetric,
    b.NewDDRMetric,
    a.SourceMetric - b.NewDDRMetric AS MetricDiff
FROM (
    SELECT 
        SUM(so.TotalUSDDistributed) AS SourceMetric
    FROM BI_DB_dbo.Function_Revenue_StakingFee(
            CAST(FORMAT(
                DATEFROMPARTS(
                    YEAR(DATEADD(MONTH, -1, GETDATE())), 
                    MONTH(DATEADD(MONTH, -1, GETDATE())), 
                    1
                ),
                'yyyyMMdd'
            ) AS INT),
            CAST(FORMAT(
                DATEADD(DAY, -1, DATEADD(MONTH, -1, CAST(GETDATE() AS DATE))),
                'yyyyMMdd'
            ) AS INT)
        ) AS so
) AS a
cross JOIN (
    SELECT 
        SUM(ddr.Amount) AS NewDDRMetric
    FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions AS ddr
    WHERE 
        ddr.DateID >= CAST(
            FORMAT(
                DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1),
                'yyyyMMdd'
            ) AS INT
        )
        AND ddr.DateID <= CAST(
            FORMAT(
                CAST(GETDATE() AS DATE),
                'yyyyMMdd'
            ) AS INT
        )
        AND ddr.Metric LIKE '%Stakin%'
) AS b