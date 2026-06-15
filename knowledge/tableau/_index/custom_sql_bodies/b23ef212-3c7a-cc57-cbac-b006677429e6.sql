select * from [dbo].[BI_DB_Operations_Monthly_KPIs_Cashouts]
where RequestDate>=dateadd(month,-5,dateadd(month,datediff(month,0,getdate()),0))