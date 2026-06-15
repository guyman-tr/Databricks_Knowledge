select views.name as ViewName
      ,views.sheettype
      ,workbooks.name ReportName
      ,workbooks.owner_id
      ,owners.friendly_name as  OwnerName
      ,workbooks.project_id
      ,projects.name FolderName
      ,projects.parent_project_id
     ,TopProjects.name TopFolderName 

     

from  public.projects projects
left join public.projects TopProjects on projects.parent_project_id=TopProjects.id
left JOIN public.workbooks workbooks  on workbooks.project_id=projects.id
left join public.views views on workbooks.id=views.workbook_id
left join  _users owners on owners.id= workbooks.owner_id
where projects.site_id=1