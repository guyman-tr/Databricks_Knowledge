select * from [BI_DB_dbo].[BI_DB_AssignmentToolVolumes]
where CreateDate>=dateadd(month,DATEDIFF(Month,0,dateadd(month,-2,getdate())),0)