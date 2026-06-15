SELECT [CID]
      ,[CitizenshipCountry]
      ,cast([VerificationLevel3Date]as date)[V3_Date]
      ,[IdentifierType]
      ,([Priority_1])
      ,([Priority_2])
      ,([Priority_3])
 FROM [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[RegTech_Gold_TR_MIFIR_PIN_Check]
  where [EU] = '1'
  and [IdentifierType] <> Priority_1
  and Priority_1 <> 'CONCAT'
  and IdentifierType <> Priority_2
  and IdentifierType <> Priority_3