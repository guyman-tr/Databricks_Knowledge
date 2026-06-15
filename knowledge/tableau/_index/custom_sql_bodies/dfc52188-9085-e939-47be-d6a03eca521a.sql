select *
FROM OPENQUERY([SYNAPSE-DWH-PROD-SERVERLESS],
'SELECT 

    gcid AS GCID
   ,[Status]

   ,[CreatedOn]
   ,[UpdatedOn]
   ,ROW_NUMBER()OVER (PARTITION BY gcid ORDER BY cast(UpdatedOn as date) DESC) AS RN


FROM [data_views].[dbo].[VideoIdentDb_VideoIdent_New] a
--where  [CreatedOn]>=DATEADD(month,-4,GETDATE())
'
)
where RN=1