select us.ID AS Id
      ,us.Username
      ,concat(us.FirstName,' ',us.LastName) Name 
      ,us.Department
      ,us.Title
      ,us.AccountManagerID
      ,us.ServiceLevel
      ,us.Desk
      ,us.ReportsTo
      ,us.Site
      ,us.SubRole
      ,us.Team
      ,us.Position
      ,us.IsActive
      ,us1.Username AS UsernameManager
      ,concat(us1.FirstName,' ',us1.LastName) AS NameManager 
      ,us1.Department AS DepartmentManager
      ,us1.Title as TitleManager
      ,us1.AccountManagerID AS AccountManagerIDManager
      ,us1.ServiceLevel AS ServiceLevelManager
      ,us1.Desk AS DeskManager
      ,us1.Site AS SiteManager
      ,us1.SubRole AS SubRoleManager
      ,us1.Team AS TeamManager
      ,us1.Position AS PositionManager
from bi_output.bi_output_customer_customer_support_agent_user us
left join bi_output.bi_output_customer_customer_support_agent_user us1 
on us.ReportsTo = us1.ID
AND us1.ToDate = '9999-12-31T00:00:00.000Z'
where us.ToDate = '9999-12-31T00:00:00.000Z'