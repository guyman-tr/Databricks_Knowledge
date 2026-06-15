SELECT fpl.ProviderName, FileDate, FilesDetails_cnt,
COUNT([IsUntrustedLoaded]) [IsUntrustedLoaded], 
SUM(CAST([IsTrustedLoaded] AS INT)) [IsTrustedLoaded], 
SUM(CAST([IsDLBronzeLoaded] AS INT)) [IsDLBronzeLoaded], 
SUM(CAST([IsDLSilverLoaded] AS INT)) [IsDLSilverLoaded]
FROM [dbo].[FilesProcessingLog] fpl
JOIN (SELECT ProviderName, COUNT(DISTINCT ShortFileName) AS FilesDetails_cnt FROM dbo.FilesDetails
WHERE [CopyToUntrusted] = 1
GROUP BY ProviderName) fd ON fd.ProviderName = fpl.ProviderName
WHERE fpl.FileDate >= CAST(DATEADD(DAY, -14, GETDATE()) AS DATE)
GROUP BY fpl.ProviderName, FileDate, FilesDetails_cnt