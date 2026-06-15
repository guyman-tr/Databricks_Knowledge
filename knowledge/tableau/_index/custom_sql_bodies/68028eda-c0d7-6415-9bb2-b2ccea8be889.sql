SELECT [ManagerID]
      ,[FirstName]
      ,[LastName]
      ,[IsActive]
      ,[IsTeamLeader]
      ,[SFManagerID]
	  ,syn.manager_id
  FROM [DWH].[dbo].[Dim_Manager] dm1
  LEFT JOIN [BI_DB].[dbo].[Syn_gsheets.customer_managers] syn
  ON dm1.ManagerID = syn.manager_id