SELECT a.*
        ,dc.RealCID
		,dc.GCID
	    ,bdfa.FirstAction_Detailed
	    ,dc.VerificationLevelID
	    ,bdcd.realizedEquity
	    ,cast (CreatedAtdt as date) as 'CreateBI'
FROM 
OPENQUERY([SYNAPSE-DWH-PROD-SERVERLESS],
'SELECT distinct[CompleteAt]
      ,[CreatedAt]
      ,LEFT(CreatedAt, 19) CreatedAtdt
      ,[GlobalStatus]
      ,[GlobalStatusId]
      ,[LastFailureReason]
	  ,[SendSMS1Counter]
      ,[TotalProcessTime]
      
      ,[gcid]*1 as gcid
	  ,ROW_NUMBER() OVER (PARTITION BY gcid ORDER BY TotalProcessTime desc ) AS RN
	  ,COUNT(gcid)OVER (PARTITION BY gcid) AS BankIdentattempts
  FROM data_views.[dbo].[SolarisBankIdentDb_SolarisBankIdent]') AS a 

LEFT JOIN  DWH.dbo.Dim_Customer dc WITH (NOLOCK) ON dc.GCID=a.gcid
LEFT JOIN BI_DB..BI_DB_First5Actions bdfa WITH (NOLOCK) ON bdfa.CID=dc.RealCID
LEFT JOIN BI_DB.dbo.BI_DB_Client_Balance_CID_Level_New  bdcd WITH (NOLOCK) ON dc.RealCID = bdcd.CID 
           AND bdcd.DateID=convert(CHAR(8),DATEADD(DAY,-1,GETDATE()),112)
           AND bdcd.TransferDirection=1
WHERE a.RN=1