SELECT  b.Is_eTM
       ,COUNT(*) AS Clients
	   ,AVG(b.Risk_Final_Result) AS AVG_Risk_Final_Result
	   ,MAX(b.Risk_Final_Result) AS MAX_Risk_Final_Result
	   ,MIN(b.Risk_Final_Result) AS MIN_Risk_Final_Result
	   ,MAX(c.[0.25_Percentile_Risk_Final_Result])AS [0.25_Percentile_Risk_Final_Result]
	   ,MAX(c.[0.5_Percentile_Risk_Final_Result]) AS [0.5_Percentile_Risk_Final_Result]
	   ,MAX(c.[0.75_Percentile_Risk_Final_Result])AS [0.75_Percentile_Risk_Final_Result]
	   ,MAX(c.[0.9_Percentile_Risk_Final_Result]) AS [0.9_Percentile_Risk_Final_Result]
FROM (
SELECT a.CID
      ,a.Risk_Final_Result
	  ,CASE WHEN a.eTM_AccountID IS NULL THEN 'Not eTM' ELSE 'eTM' END AS Is_eTM 
FROM eMoney_dbo.eMoney_Customer_Risk_Assessment a ) b
LEFT JOIN (
SELECT DISTINCT b.Is_eTM
	   ,PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Risk_Final_Result) OVER (PARTITION BY b.Is_eTM) AS '0.25_Percentile_Risk_Final_Result'
	   ,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Risk_Final_Result) OVER (PARTITION BY b.Is_eTM) AS '0.5_Percentile_Risk_Final_Result'
	   ,PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Risk_Final_Result) OVER (PARTITION BY b.Is_eTM) AS '0.75_Percentile_Risk_Final_Result'
	   ,PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY Risk_Final_Result) OVER (PARTITION BY b.Is_eTM) AS '0.9_Percentile_Risk_Final_Result'
FROM (
SELECT a.CID
      ,a.Risk_Final_Result
	  ,CASE WHEN a.eTM_AccountID IS NULL THEN 'Not eTM' ELSE 'eTM' END AS Is_eTM 
FROM eMoney_dbo.eMoney_Customer_Risk_Assessment a ) b) c ON c.Is_eTM=b.Is_eTM
GROUP BY b.Is_eTM

UNION ALL


SELECT
    'Total' AS Is_eTM,
    COUNT(a.CID) AS Clients,
    AVG(a.Risk_Final_Result) AS AVG_Risk_Final_Result,
    MAX(a.Risk_Final_Result) AS MAX_Risk_Final_Result,
    MIN(a.Risk_Final_Result) AS MIN_Risk_Final_Result,
    MAX(c.[0.25_Percentile_Risk_Final_Result]) AS [0.25_Percentile_Risk_Final_Result],
    MAX(c.[0.5_Percentile_Risk_Final_Result]) AS [0.5_Percentile_Risk_Final_Result],
    MAX(c.[0.75_Percentile_Risk_Final_Result]) AS [0.75_Percentile_Risk_Final_Result],
    MAX(c.[0.9_Percentile_Risk_Final_Result]) AS [0.9_Percentile_Risk_Final_Result]
FROM
    eMoney_dbo.eMoney_Customer_Risk_Assessment a
LEFT JOIN (
    SELECT DISTINCT
        'Total' AS Is_eTM,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Risk_Final_Result) OVER () AS [0.25_Percentile_Risk_Final_Result],
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Risk_Final_Result) OVER () AS [0.5_Percentile_Risk_Final_Result],
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Risk_Final_Result) OVER () AS [0.75_Percentile_Risk_Final_Result],
        PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY Risk_Final_Result) OVER () AS [0.9_Percentile_Risk_Final_Result]
    FROM
        eMoney_dbo.eMoney_Customer_Risk_Assessment
) c ON 'Total' = c.Is_eTM