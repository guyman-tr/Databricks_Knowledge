SELECT Count (1) Count
,CitizenshipCountry
      ,[IdentifierType]
      ,([Priority_1])
      ,([Priority_2])
      ,([Priority_3])
 FROM [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[RegTech_Gold_TR_MIFIR_PIN_Check]
  where CitizenshipCountry = 'Hungary'
  and [IdentifierType] <> Priority_1
  and IdentifierType <> Priority_2
  and IdentifierType <> Priority_3
  Group By CitizenshipCountry,
      [IdentifierType]
      ,([Priority_1])
      ,([Priority_2])
      ,([Priority_3])