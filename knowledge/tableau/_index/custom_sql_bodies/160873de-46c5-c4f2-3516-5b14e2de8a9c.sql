SELECT [Id] COLLATE SQL_Latin1_General_CP1_CI_AS Id
      ,[Username]
      ,[Name]
      ,[Department]
      ,[Title]
      ,[Email]
      ,[Alias]
      ,[IsActive]
      ,[AccountManagerID]
      ,[ServiceLevel]
      ,[Desk]
      ,[ServiceDesk]
      ,[IsDummy]
      ,[IsSupportUser]
      ,[CSDesk]
      ,[IsAssignable]
      ,[SubDepartment]
      ,[ReportsTo]
      ,[DeskHiBOB]
      ,[Site]
      ,[IsOutsource]
      ,[SubRole]
      ,[Team]
      ,[Position]
      ,[IsSuperUser]
      ,[IsWhatsappEligible]
      ,[CreatedDate]
      ,[ChecksumID]
      ,[FromDate]
      ,[ToDate]
      ,[UpdateDate]
  FROM [BI_DB].[dbo].[BI_DB_SF_M_Users]
  WHERE ToDate = '9999-12-31'