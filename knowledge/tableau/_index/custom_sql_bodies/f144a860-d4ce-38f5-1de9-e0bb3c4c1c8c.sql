SELECT [ProviderName], [FileName], [FileDate], [IsCreated] AS [ParquetFileCreated], DateCreated  AS [FileDateCreated], ToSynapse AS [LoadToSynapse], 
       IsLoadedToSynapse, [DateLoaded] AS [LoadToSynapseDate], [ExecutionStatus], [ErrorLoggedTime], [ErrorDescription]
FROM [ExternalFileToParquetProcessLog]