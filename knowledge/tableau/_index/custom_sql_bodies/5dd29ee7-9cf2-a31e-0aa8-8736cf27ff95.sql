SELECT CID
      ,CitizenshipCountry [Citizenship]
      ,[IdentifierType] [eToro Identifier]
      ,cast (VerificationLevel3Date as date) V3_Date
 FROM [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[RegTech_Gold_TR_MIFIR_PIN_Check]
 Where  CitizenshipCountry = 'N/A'