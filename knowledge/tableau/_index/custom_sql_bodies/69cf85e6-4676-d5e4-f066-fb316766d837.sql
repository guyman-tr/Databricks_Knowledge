SELECT Date, DateID, 
	YEAR([Date]) * 100 + DATEPART(qq, [Date]) AS Quarter, 
	ECBRate AS Rate
FROM 
 (
SELECT *,
	ROW_NUMBER () OVER (PARTITION BY DateID ORDER BY DateID DESC) AS RN
FROM BI_DB.python.BI_DB_ECB_RateExtractFromAPI
--WHERE Date <= '20201231'
) a
WHERE a.RN = 1