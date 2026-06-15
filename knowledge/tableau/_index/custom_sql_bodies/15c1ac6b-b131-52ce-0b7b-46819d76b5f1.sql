select cast(max (UpdateDate) as datetime) [Update Time]
 FROM [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[RegTech_Gold_TR_MIFIR_PIN_Check]