SELECT
	l.CID							as [CID] ,
   'No_PEP_Check' 					as [PEPStatus] ,
   l.FirstName						as [FirstName] ,
   l.LastName						as [LastName] ,
   l.Gender							as [Gender] ,
   l.BirthDate						as [BirthDate] ,
   l.PlayerStatus					as [PlayerStatus] ,
   l.Country						as [Country] ,
   l.IsDepositor					as [IsDepositor] ,
   l.WorldCheckID					as [WorldCheckID] ,
   l.VerificationLevelID			as [VerificationLevelID] ,
   l.DocumentStatusName				as [DocumentStatusName] ,
   GETDATE() 			as [UpdateDate] ,
   [GatewayApp]						as [GatewayApp]
FROM #splunkLogins l
WHERE VerificationLevelID = 2
UNION
SELECT 
	v.CID							as [CID] ,
   v.PEPStatus						as [PEPStatus] ,
   v.FirstName						as [FirstName] ,
   v.LastName						as [LastName] ,
   v.Gender							as [Gender] ,
   v.BirthDate						as [BirthDate] ,
   v.PlayerStatus					as [PlayerStatus] ,
   v.Country						as [Country] ,
   IsDepositor						as [IsDepositor] ,
   v.WorldCheckID					as [WorldCheckID] ,
   v.VerificationLevelID			as [VerificationLevelID] ,
   v.DocumentStatusName				as [DocumentStatusName] ,
   GETDATE() 			as [UpdateDate] ,
   [GatewayApp]						as [GatewayApp]
FROM #XloginsLeads v
WHERE PEPStatus = 'No_PEP_Check'