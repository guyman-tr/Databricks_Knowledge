SELECT Count (1) [Count]
      ,CitizenshipCountry
      ,[IdentifierType]
      ,([Priority_1])
      ,([Priority_2])
      ,([Priority_3])
 FROM [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[RegTech_Gold_TR_MIFIR_PIN_Check]
  where cast (VerificationLevel3Date as date) >= Cast (getdate () - <[Parameters].[Parameter 1]> as date)
  and [EU] = '1'
  and Priority_1 <> 'CONCAT'
  and (Priority_2 = 'CONCAT' or Priority_3 = 'CONCAT')
  and [IdentifierType] <> Priority_1
  and IdentifierType <> Priority_2
  and IdentifierType <> Priority_3
  Group By CitizenshipCountry,
      [IdentifierType]
      ,([Priority_1])
      ,([Priority_2])
      ,([Priority_3])

 union

 SELECT Count (1) Count
      ,'TOTAL' as CitizenshipCountry
	  ,'-' AS [eToro Identifier]
      , '-' as [Priority_1]
      , '-' as [Priority_2]
      , '-' as [Priority_3]
 FROM [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[RegTech_Gold_TR_MIFIR_PIN_Check]
  where cast (VerificationLevel3Date as date) >= Cast (getdate () - <[Parameters].[Parameter 1]> as date)
  and [EU] = '1'
  and Priority_1 <> 'CONCAT'
  and (Priority_2 = 'CONCAT' or Priority_3 = 'CONCAT')
  and [IdentifierType] <> Priority_1
  and [IdentifierType] <> Priority_2
  and [IdentifierType] <> Priority_3