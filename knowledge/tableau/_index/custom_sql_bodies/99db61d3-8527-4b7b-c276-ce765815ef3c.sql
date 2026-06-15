SELECT 
    ddr.*, 
    dcn.Name AS Country
FROM (
    SELECT * FROM BI_DB_dbo.Function_DDR_Aggregation_ThisMonth(CONVERT(VARCHAR(10), <[Parameters].[Parameter 1]>, 120), 1)
    UNION ALL
    SELECT * FROM BI_DB_dbo.Function_DDR_Aggregation_ThisMonth(CONVERT(VARCHAR(10), EOMONTH(DATEADD(month, -1, <[Parameters].[Parameter 1]>)), 120), 1)
    UNION ALL
    SELECT * FROM BI_DB_dbo.Function_DDR_Aggregation_ThisMonth(CONVERT(VARCHAR(10), EOMONTH(DATEADD(month, -2, <[Parameters].[Parameter 1]>)), 120), 1)
    UNION ALL
    SELECT * FROM BI_DB_dbo.Function_DDR_Aggregation_ThisMonth(CONVERT(VARCHAR(10), EOMONTH(DATEADD(month, -3, <[Parameters].[Parameter 1]>)), 120), 1)
    UNION ALL
    SELECT * FROM BI_DB_dbo.Function_DDR_Aggregation_ThisMonth(CONVERT(VARCHAR(10), EOMONTH(DATEADD(month, -4, <[Parameters].[Parameter 1]>)), 120), 1)
    UNION ALL
    SELECT * FROM BI_DB_dbo.Function_DDR_Aggregation_ThisMonth(CONVERT(VARCHAR(10), EOMONTH(DATEADD(month, -5, <[Parameters].[Parameter 1]>)), 120), 1)
) ddr
LEFT JOIN DWH_dbo.Dim_Country dcn ON ddr.CountryID = dcn.CountryID