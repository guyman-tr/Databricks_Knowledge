SELECT * FROM BI_DB..BI_DB_Zero_Daily_Finance_Report with (NOLOCK)
WHERE DateID BETWEEN 
CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 1]>, 112) AS INT)
 AND 
CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 2]>, 112) AS INT)