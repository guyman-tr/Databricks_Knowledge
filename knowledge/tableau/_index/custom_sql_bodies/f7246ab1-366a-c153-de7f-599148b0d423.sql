--Workbook User Level Permissions

SELECT

CAST ('Workbook' as varchar) as object, --Set to either workbook or datasource

p.name as project, --project where item sits

s.name as Site_name,

w.name as Object_Name, --Workbook or datasource name

w.revision as Version, --Version where applicable

CAST ('User' as varchar) as Grantee_type, --means permission given to user or inherited from group

su.name as User_or_group_Name, --User name

c.name as Permission_type, --Type of permission

CASE

  WHEN ngp.permission = 1 THEN 'Allow by Group'

  WHEN ngp.permission = 2 THEN 'Deny by Group'

  WHEN ngp.permission = 3 THEN 'Allow to User'

  WHEN ngp.permission = 4 THEN 'Deny to User'

END as Granted_Denied --This shows if restriction is applied to user or group

FROM public.next_gen_permissions ngp

JOIN public.workbooks w ON ngp.authorizable_id=w.id

JOIN public.users u ON ngp.grantee_id=u.id

JOIN public.system_users su ON u.system_user_id=su.id

JOIN public.capabilities c ON ngp.capability_id=c.id

JOIN public.projects p ON w.project_id=p.id

JOIN public.sites s ON w.site_id=s.id

WHERE ngp.authorizable_type = 'Workbook'

AND ngp.grantee_type = 'User'

AND su.name <> 'guest'

UNION ALL

--Workbook Group Level Permissions

SELECT

CAST ('Workbook' as varchar) as object,

p.name as project,

s.name as Site_name,

w.name as Object_Name,

w.revision as Version,

CAST ('Group' as varchar) as Grantee_type,

u.name as User_or_group_Name,

c.name as Permission_type,

CASE

  WHEN ngp.permission = 1 THEN 'Allow by Group'

  WHEN ngp.permission = 2 THEN 'Deny by Group'

  WHEN ngp.permission = 3 THEN 'Allow to User'

  WHEN ngp.permission = 4 THEN 'Deny to User'

END as Granted_Denied

FROM public.next_gen_permissions ngp

JOIN public.workbooks w ON ngp.authorizable_id=w.id

JOIN public.groups u ON ngp.grantee_id=u.id

JOIN public.capabilities c ON ngp.capability_id=c.id

JOIN public.projects p ON w.project_id=p.id

JOIN public.sites s ON w.site_id=s.id

WHERE ngp.authorizable_type = 'Workbook'

AND ngp.grantee_type = 'Group'

UNION ALL

--Datasource User Level Permissions

SELECT

CAST ('Datasource' as varchar) as object,

p.name as project,

s.name as Site_name,

ds.name as Object_Name,

ds.revision as Version,

CAST ('User' as varchar) as Grantee_type,

su.name as User_or_group_Name,

c.name as Permission_type,

CASE

  WHEN ngp.permission = 1 THEN 'Allow by Group'

  WHEN ngp.permission = 2 THEN 'Deny by Group'

  WHEN ngp.permission = 3 THEN 'Allow to User'

  WHEN ngp.permission = 4 THEN 'Deny to User'

END as Granted_Denied

FROM public.next_gen_permissions ngp

JOIN public.datasources ds ON ngp.authorizable_id=ds.id

JOIN public.projects p ON ds.project_id=p.id

JOIN public.users u ON ngp.grantee_id=u.id

JOIN public.system_users su ON u.system_user_id=su.id

JOIN public.capabilities c ON ngp.capability_id=c.id

JOIN public.sites s on ds.site_id=s.id

WHERE ngp.authorizable_type = 'Datasource'

AND ngp.grantee_type = 'User'

AND su.name <> 'guest'

UNION ALL

--Datasource Group Level Permissions

SELECT

CAST ('Datasource' as varchar) as object,

p.name as project,

s.name as Site_name,

ds.name as Object_Name,

ds.revision as Version,

CAST ('Group' as varchar) as Grantee_type,

g.name as User_or_group_Name,

c.name as Permission_type,

CASE

  WHEN ngp.permission = 1 THEN 'Allow by Group'

  WHEN ngp.permission = 2 THEN 'Deny by Group'

  WHEN ngp.permission = 3 THEN 'Allow to User'

  WHEN ngp.permission = 4 THEN 'Deny to User'

END as Granted_Denied

FROM public.next_gen_permissions ngp

JOIN public.datasources ds ON ngp.authorizable_id=ds.id

JOIN public.projects p ON ds.project_id=p.id

JOIN public.groups g ON ngp.grantee_id=g.id

JOIN public.capabilities c ON ngp.capability_id=c.id

JOIN public.sites s on ds.site_id=s.id

WHERE ngp.authorizable_type = 'Datasource'

AND ngp.grantee_type = 'Group'