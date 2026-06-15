select views.name as ViewName
      ,views.sheettype
      ,workbooks.name ReportName
      ,owner_name as  OwnerName
      ,project_name as FolderName

from  public.views views 
JOIN _workbooks workbooks on workbooks.id=views.workbook_id