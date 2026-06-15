SELECT --[GCID],[CID],
      [ApexID]
      ,[ApproverName]
      ,[ApexApprovedDate]
FROM [BI_DB_dbo].[BI_DB_US_Compliance_Apex_Clients]
GROUP BY       [ApexID]
      ,[ApproverName]
      ,[ApexApprovedDate]