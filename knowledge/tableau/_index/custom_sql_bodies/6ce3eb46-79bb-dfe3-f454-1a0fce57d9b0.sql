--Previous days
-- select d.FullDate,h.DateParam, p.ProcedureName , SP_History_Status ,History_Object_ProcedureName from (
select Row_number() over (partition by d.FullDate order  by d.FullDate   ) as  RN
,d.FullDate, p.ProcedureName , coalesce(SP_History_Status,0) SP_History_Status ,coalesce(h.SP_Status_Description,'Not running')SP_Status_Description
from  (
select  FullDate from
[dbo].[Dim_Date]
where  FullDate >= Dateadd(day,-<[Parameters].[Parameter 1]>,cast(getdate()as  date)) and FullDate <= Dateadd(day,0,cast(getdate()as  date))
)d left join
(
select  distinct  
Dateadd(day,-1,cast(getdate()as  date)) DateParam ,
OS.ProcedureName --as ObjectsStatus_ProcedureName
-- ,HH.FullDate
--,History_Object_ProcedureName
,OS.ObjectStatus as SP_Status
,di.ObjectStatusDesc as  SP_Status_Description
,cast(OS.CreatedDate as  date) as CreatedDate
FROM  [dbo].ObjectsStatus OS WITH (nolock)
 left  join  [dbo].ObjectsStatusDic di  WITH (nolock)
on  OS.ObjectStatus= di.ObjectStatus
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
,max(EndDate)over(Partition by ProcedureName,DateParam) as MX_EndDate
from   [dbo].ObjectsStatusHistory HH WITH (nolock)
 left  join  [dbo].ObjectsStatusDic di  WITH (nolock)
on  HH.ObjectStatus= di.ObjectStatus
where (substring(ProcedureName,1,11) ='Dealing_dbo'
or ProcedureName='Dealing_staging.SP_Copy_PriceLog_History_CurrencyPrice')
and (HH.CreatedDate is null  or HH.DateParam>=cast(HH.CreatedDate as  date))
 and HH.DateParam >= Dateadd(day,-<[Parameters].[Parameter 1]>,cast(getdate()as  date))
and HH.DateParam <cast(getdate()as  date))P
where  EndDate=MX_EndDate)h
on d.FullDate = h.DateParam
and  p.ProcedureName= h.History_Object_ProcedureName

where (h.History_Object_ProcedureName is null  or  SP_History_Status<>2)
and p.CreatedDate <= d.FullDate
and  d.FullDate<  cast(getdate()  as  date)
--and p.ProcedureName= 'Dealing_dbo.SP_SelfCopyingPI'