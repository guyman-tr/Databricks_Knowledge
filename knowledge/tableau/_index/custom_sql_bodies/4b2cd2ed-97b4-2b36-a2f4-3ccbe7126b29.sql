SELECT 'Yesterday' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_Yesterday (<[Parameters].[Parameter 2]>,0) 
UNION ALL 
SELECT 'ThisWeek' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_ThisWeek (<[Parameters].[Parameter 2]>,0) 
UNION ALL 
SELECT 'ThisMonth' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_ThisMonth (<[Parameters].[Parameter 2]>,0) 
UNION ALL 
SELECT 'ThisQuarter' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_ThisQuarter (<[Parameters].[Parameter 2]>,0) 
UNION ALL 
SELECT 'ThisYear' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_ThisYear  (<[Parameters].[Parameter 2]>,0)