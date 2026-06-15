SELECT [ManagerID]
      ,[FirstName]
      ,[LastName]
      ,[IsActive]
      ,[IsTeamLeader]
      ,[SFManagerID]
      ,CASE WHEN UPPER(manager_type) = 'NULL' THEN 'Others' ELSE manager_type END manager_type
  FROM [DWH].[dbo].[Dim_Manager] dm1
  LEFT JOIN [BI_DB].[dbo].[Syn_gsheets.customer_managers] syn
  ON dm1.ManagerID = syn.manager_id