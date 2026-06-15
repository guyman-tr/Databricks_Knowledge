SELECT
	[CID]					as [CID], 
	[PEPStatus] 			as [PEPStatus] ,
	[FirstName] 			as [FirstName] ,
	[LastName] 				as [LastName] ,
	[Gender] 				as [Gender] ,
	[BirthDate] 			as [BirthDate] ,
	[PlayerStatus] 			as [PlayerStatus] ,
	[Country] 				as [Country] ,
	[FTD] 					as [FTD] ,
	[WorldCheckID] 			as [WorldCheckID] ,
	[VerificationLevelID] 	as [VerificationLevelID] ,
	[DocumentStatusName] 	as [DocumentStatusName] ,
	Getdate()				as [UpdateDate],
	[GatewayApp]			as [GatewayApp]
FROM #verified v