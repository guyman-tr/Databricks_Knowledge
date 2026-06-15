SELECT [ProcessProviderName], [RunDate], [ProcessName], [LPFileName], [EtoroFileName], [EtoroDownloadDLDate], [EtoroUploadDate], [LPUploadDate], [UploadStatus], [UpdateDate], [StatusUpdateDate]
FROM dbo.DuCo_UploadProcessLog with (NOLOCK)
WHERE RunDate >= CAST(DATEADD(DAY, -5, GETDATE()) AS DATE)