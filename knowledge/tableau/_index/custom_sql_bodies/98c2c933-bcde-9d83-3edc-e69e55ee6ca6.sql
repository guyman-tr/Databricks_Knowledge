SELECT Count (1) Count
      ,[IdentifierType] [eToro Identifier]
 FROM [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[RegTech_Gold_TR_MIFIR_PIN_Check]
  where cast (VerificationLevel3Date as date) >= Cast (getdate () - <[Parameters].[Parameter 1]> as date)
and CitizenshipCountry = 'N/A'
  Group By CitizenshipCountry,
      [IdentifierType]
 union
 SELECT Count (1) Count
      ,'TOTAL' AS [eToro Identifier]
 FROM [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[RegTech_Gold_TR_MIFIR_PIN_Check]
  where cast (VerificationLevel3Date as date) >= Cast (getdate () - <[Parameters].[Parameter 1]> as date)
and CitizenshipCountry = 'N/A'
  Group By CitizenshipCountry