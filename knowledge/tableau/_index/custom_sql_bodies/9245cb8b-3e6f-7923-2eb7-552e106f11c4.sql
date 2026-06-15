SELECT [ProviderName]      ,[FileName]      ,[FileDate]      ,[IsUntrustedLoaded]      ,[UntrustedDateCreated]      ,[IsTrustedLoaded],[TrustedDateCreated]      ,[IsDLBronzeLoaded]      ,[DLBronzeDateCreated]      ,[IsDLSilverLoaded]      ,[DLSilverDateCreated]     
FROM [dbo].[FilesProcessingLog]
WHERE   FileDate >= CAST(DATEADD(DAY, -5, GETDATE()) AS DATE)