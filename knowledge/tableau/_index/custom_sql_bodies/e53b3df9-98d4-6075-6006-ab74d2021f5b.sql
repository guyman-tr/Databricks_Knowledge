select bm.FirstName+' '+bm.LastName as Manager
       ,bm.ManagerID
	   ,sf.ActionName
	   ,COUNT(CreatedDate_SF) as CountActions
from [dbo].[BI_DB_UsageTracking_SF] sf
left join DWH.dbo.Dim_Manager bm
on bm.ManagerID = sf.CreatedByManagerID
where CAST(CreatedDate_SF as Date) = cast(getdate() as date)
group by bm.FirstName+' '+bm.LastName 
       ,bm.ManagerID
	   ,sf.ActionName