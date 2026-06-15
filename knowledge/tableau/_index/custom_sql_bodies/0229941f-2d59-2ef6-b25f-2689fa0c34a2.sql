select * from [dbo].[BI_DB_Operations_Monthly_KPIs_Wires]
where ModificationDate>=dateadd(month,-5,dateadd(month,datediff(month,0,getdate()),0))