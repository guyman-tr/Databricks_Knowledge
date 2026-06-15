SELECT distinct us.Id 
      ,us.Username
      ,CONCAT_WS(' ', us.FirstName, us.LastName)  as Name
      ,us.Department
      ,us.Title
      ,us.AccountManagerID
      ,us.ServiceLevel
      ,us.Desk
   --   ,c.ServiceDesk
      ,us.DummyUser as IsDummy
   --   ,us.SupportUser as IsSupportUser
      ,us.CS_Desk as CSDesk
      ,us.Assignable as IsAssignable
   --   ,us.SubDepartment
      ,us.ReportsTo
      ,us.Site
    --  ,us.IsOutsource
      ,us.SubRole
      ,us.Team
      ,us.Position
	  ,us1.Username UsernameManager
	  ,CONCAT_WS(' ', us1.FirstName, us1.LastName)as NameManager
	  ,us1.Department DepartmentManager
	  ,us1.Title TitleManager
	  ,us1.AccountManagerID AccountManagerIDManager
	  ,us1.ServiceLevel ServiceLevelManager
	  ,us1.Desk DeskManager
	 -- ,us1.ServiceDesk ServiceDeskManager
	  ,us1.CS_Desk CSDeskManager
	--  ,us1.SubDepartment SubDepartmentManager
	  ,us1.DeskHiBOB DeskHiBOBManager
	  ,us1.Site SiteManager
	  ,us1.SubRole SubRoleManager
	  ,us1.Team TeamManager
	  ,us1.Position PositionManager
    ,CONCAT_WS(' ', us2.FirstName, us2.LastName)as SecondLevel_Manager
  FROM main.bi_output.bi_output_customer_customer_support_agent_user us
  left join main.bi_output.bi_output_customer_customer_support_agent_user us1  ON us.ReportsTo = us1.Id AND YEAR(us1.ToDate) = '9999'
  left join main.bi_output.bi_output_customer_customer_support_agent_user us2  ON us1.ReportsTo = us2.Id AND YEAR(us2.ToDate) = '9999'
  --  LEFT JOIN main.bi_output.bi_output_customer_customer_support_case c on c.OwnerId=us.Id 
  
  WHERE YEAR(us.ToDate) = '9999'
  --and us.Department='CS'