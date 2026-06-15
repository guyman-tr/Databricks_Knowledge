SELECT 

       cast([id] as int) AS GCID
      ,[Status]

   ,[CreatedOn]
   ,[UpdatedOn]
   ,ROW_NUMBER()OVER (PARTITION BY id ORDER BY [UpdatedOn] DESC) AS 'RN'
   ,bdfa.FirstAction
   ,bdfa.Revenue30days
   ,bdfa.FirstDepositDate
   ,dc.IsDepositor

FROM [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[VideoIdentDb_VideoIdent] a
INNER JOIN DWH..Dim_Customer dc on dc.GCID=a.id and dc.VerificationLevelID=3
LEFT JOIN BI_DB..BI_DB_First5Actions bdfa ON dc.RealCID=bdfa.CID
where  [CreatedOn]>=DATEADD(WEEK,-16,GETDATE())