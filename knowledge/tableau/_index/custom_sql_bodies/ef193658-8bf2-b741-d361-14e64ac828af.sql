SELECT 'Yesterday' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_Yesterday ('20240413',0) 
UNION ALL 
SELECT 'ThisWeek' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_ThisWeek ('20240413',0) 
UNION ALL 
SELECT 'ThisMonth' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_ThisMonth ('20240413',0) 
UNION ALL 
SELECT 'ThisQuarter' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_ThisQuarter ('20240413',0) 
UNION ALL 
SELECT 'ThisYear' AS TimeRange, *
FROM BI_DB_dbo.Function_DDR_Aggregation_ThisYear  ('20240413',0)