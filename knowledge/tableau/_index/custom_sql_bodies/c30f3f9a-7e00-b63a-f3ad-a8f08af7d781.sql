SELECT us.[Id] COLLATE SQL_Latin1_General_CP1_CI_AS Id
      ,us.[Username]
      ,us.[Name]
      ,us.[Department]
      ,us.[Title]
      ,us.[AccountManagerID]
      ,us.[ServiceLevel]
      ,us.[Desk]
      ,us.[ServiceDesk]
      ,us.[IsDummy]
      ,us.[IsSupportUser]
      ,us.[CSDesk]
      ,us.[IsAssignable]
      ,us.[SubDepartment]
      ,us.[ReportsTo]
      ,us.[Site]
      ,us.[IsOutsource]
      ,us.[SubRole]
      ,us.[Team]
      ,us.[Position]
	  ,us1.Username UsernameManager
	  ,us1.Name NameManager
	  ,us1.Department DepartmentManager
	  ,us1.Title TitleManager
	  ,us1.AccountManagerID AccountManagerIDManager
	  ,us1.ServiceLevel ServiceLevelManager
	  ,us1.Desk DeskManager
	  ,us1.ServiceDesk ServiceDeskManager
	  ,us1.CSDesk CSDeskManager
	  ,us1.SubDepartment SubDepartmentManager
	  ,us1.DeskHiBOB DeskHiBOBManager
	  ,us1.Site SiteManager
	  ,us1.SubRole SubRoleManager
	  ,us1.Team TeamManager
	  ,us1.Position PositionManager
  FROM [BI_DB].[dbo].[BI_DB_SF_M_Users] us
  left join [BI_DB].[dbo].[BI_DB_SF_Users] usn
  on us.Id = usn.Id
  LEFT JOIN [BI_DB].[dbo].[BI_DB_SF_M_Users] us1
  ON usn.ManagerId = us1.Id
  AND us1.ToDate = '9999-12-31'
  WHERE us.ToDate = '9999-12-31'