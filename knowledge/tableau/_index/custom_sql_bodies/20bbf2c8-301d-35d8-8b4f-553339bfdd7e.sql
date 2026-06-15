SELECT Date, DateID, 
	YEAR([Date]) * 100 + DATEPART(qq, [Date]) AS Quarter, 
	ECBRate AS Rate
FROM 
 (
SELECT *,
	ROW_NUMBER () OVER (ORDER BY DateID DESC) AS RN
FROM BI_DB_dbo.BI_DB_ECB_RateExtractFromAPI
WHERE Date <= <[Parameters].[Parameter 3]>
) a
WHERE a.RN = 1