select distinct  
row_number() over (partition by p.ProcedureName ,d.FullDate order  by d.FullDate) as  RN
--row_number() over (partition by d.FullDate,p.ProcedureName order  by p.ProcedureName) as  RN_DEP
,d.FullDate
,p.ProcedureName 
,coalesce(SP_History_Status,0) SP_History_Status 
,coalesce(h.SP_Status_Description,'Not running') as SP_Status_Description
,p.Dependencies_Table
,OS_Dep2.TableName as Dependency_History_Table_Name
,OS_Dep2.ObjectStatus as Dependency_Table_Status
,coalesce(di2.ObjectStatusDesc,'Not running') as  Dependency_Table_Status_Description
,OS_Dep2.StartDate as Dependency_Table_StartDate 
,OS_Dep2.EndDate as Dependency_Table_EndDate
from  (
select  FullDate from
[dbo].[Dim_Date]
where  FullDate >= Dateadd(day,-<[Parameters].[Parameter 1]>,cast(getdate()as  date)) and FullDate <= Dateadd(day,-1,cast(getdate()as  date))
)d left join
(
select  distinct  
Dateadd(day,-2,cast(getdate()as  date)) DateParam ,
OS.ProcedureName --as ObjectsStatus_ProcedureName
-- ,HH.FullDate
--,History_Object_ProcedureName
,OS.ObjectStatus as SP_Status
,di.ObjectStatusDesc as  SP_Status_Description
,isnull(DPS.TableName,'N/A') as Dependencies_Table
,cast(OS.CreatedDate as  date) as CreatedDate
FROM  [dbo].ObjectsStatus OS WITH (nolock)
 left  join  [dbo].ObjectsStatusDic di  WITH (nolock)
on  OS.ObjectStatus= di.ObjectStatus
left  join  
 [dbo].[ProcedureDependencies] DPS WITH (nolock)
on OS.ProcedureName= DPS.[ProcedureName]
where (substring(OS.ProcedureName,1,11) ='Dealing_dbo'
or OS.ProcedureName='Dealing_staging.SP_Copy_PriceLog_History_CurrencyPrice')
and  OS.FrequencySP='Daily' and OS.IsActive=1
) p on d.FullDate <= p.DateParam
left join
(
select
--Row_number() over (partition by History_Object_ProcedureName  order  by  DateParam asc) as RN
*  from  (
select distinct  
HH.ProcedureName  as History_Object_ProcedureName
,HH.ObjectStatus as SP_History_Status
,HH.DateParam
,HH.EndDate
,di.ObjectStatusDesc as  SP_Status_Description
,max(HH.EndDate)over(Partition by HH.ProcedureName,HH.DateParam) as MX_EndDate
from   [dbo].ObjectsStatusHistory HH WITH (nolock)
 left  join  [dbo].ObjectsStatusDic di  WITH (nolock)
on  HH.ObjectStatus= di.ObjectStatus
where (substring(HH.ProcedureName,1,11) ='Dealing_dbo'
or HH.ProcedureName='Dealing_staging.SP_Copy_PriceLog_History_CurrencyPrice')
and  HH.DateParam >= Dateadd(day,-<[Parameters].[Parameter 1]>,cast(getdate()as  date))
and HH.DateParam <cast(getdate()as  date))P
)h
on d.FullDate = h.DateParam
and  p.ProcedureName= h.History_Object_ProcedureName
left  join 
[dbo].[ObjectsStatusHistory] OS_Dep2 WITH (nolock)
on p.Dependencies_Table=OS_Dep2.TableName
and d.FullDate= OS_Dep2.DateParam
 left  join  [dbo].ObjectsStatusDic di2  WITH (nolock)
on  OS_Dep2.ObjectStatus= di2.ObjectStatus
where (h.History_Object_ProcedureName is null  or  SP_History_Status<>2)
and p.CreatedDate <= d.FullDate
and  d.FullDate<  cast(getdate()  as  date)