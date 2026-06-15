SELECT 'Clients' AS KPI
       ,COUNT(a.CID) AS Measure
FROM eMoney_dbo.eMoney_Customer_Risk_Assessment a
UNION 
SELECT 'AVG_Risk_Final_Result' AS KPI
       ,AVG(a.Risk_Final_Result) AS Measure
FROM eMoney_dbo.eMoney_Customer_Risk_Assessment a
UNION
SELECT 'MAX_Risk_Final_Result' AS KPI
       ,MAX(a.Risk_Final_Result) AS Measure
FROM eMoney_dbo.eMoney_Customer_Risk_Assessment a
UNION
SELECT 'MIN_Risk_Final_Result' AS KPI
       ,MIN(a.Risk_Final_Result) AS Measure
FROM eMoney_dbo.eMoney_Customer_Risk_Assessment a
UNION
SELECT DISTINCT '0.1_Percentile_Risk_Final_Result' AS KPI
      ,PERCENTILE_CONT(0.1) WITHIN GROUP (ORDER BY Risk_Final_Result) OVER () AS Measure
FROM  eMoney_dbo.eMoney_Customer_Risk_Assessment
UNION
SELECT DISTINCT '0.2_Percentile_Risk_Final_Result' AS KPI
      ,PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY Risk_Final_Result) OVER () AS Measure
FROM  eMoney_dbo.eMoney_Customer_Risk_Assessment
UNION
SELECT DISTINCT '0.3_Percentile_Risk_Final_Result' AS KPI
      ,PERCENTILE_CONT(0.3) WITHIN GROUP (ORDER BY Risk_Final_Result) OVER () AS Measure
FROM  eMoney_dbo.eMoney_Customer_Risk_Assessment
UNION
SELECT DISTINCT '0.4_Percentile_Risk_Final_Result' AS KPI
      ,PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY Risk_Final_Result) OVER () AS Measure
FROM  eMoney_dbo.eMoney_Customer_Risk_Assessment
UNION
SELECT DISTINCT '0.5_Percentile_Risk_Final_Result' AS KPI
      ,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Risk_Final_Result) OVER () AS Measure
FROM  eMoney_dbo.eMoney_Customer_Risk_Assessment
UNION
SELECT DISTINCT '0.6_Percentile_Risk_Final_Result' AS KPI
      ,PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY Risk_Final_Result) OVER () AS Measure
FROM  eMoney_dbo.eMoney_Customer_Risk_Assessment
UNION
SELECT DISTINCT '0.7_Percentile_Risk_Final_Result' AS KPI
      ,PERCENTILE_CONT(0.7) WITHIN GROUP (ORDER BY Risk_Final_Result) OVER () AS Measure
FROM  eMoney_dbo.eMoney_Customer_Risk_Assessment
UNION
SELECT DISTINCT '0.8_Percentile_Risk_Final_Result' AS KPI
      ,PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY Risk_Final_Result) OVER () AS Measure
FROM  eMoney_dbo.eMoney_Customer_Risk_Assessment
UNION
SELECT DISTINCT '0.9_Percentile_Risk_Final_Result' AS KPI
      ,PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY Risk_Final_Result) OVER () AS Measure
FROM  eMoney_dbo.eMoney_Customer_Risk_Assessment
UNION
SELECT DISTINCT '0.95_Percentile_Risk_Final_Result' AS KPI
      ,PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY Risk_Final_Result) OVER () AS Measure
FROM  eMoney_dbo.eMoney_Customer_Risk_Assessment