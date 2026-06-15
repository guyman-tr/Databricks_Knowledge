select  
 P.ProcedureName
,P.IsActive
,Main_SP_Status
,Main_SP_Status_Description   
,Dependencies_Tables
,ROW_NUMBER () OVER (PARTITION BY P.[ProcedureName]order  by OS_Dep.ProcedureName, OS_Dep.EndDate asc ) AS RN
,isnull(OS_Dep.ProcedureName,'N/A') as Dependencies_ProcedureName
,isnull(OS_Dep.ObjectStatus,99) as Dependencies_SP_Status
,di2.ObjectStatusDesc as  Dep_SP_Status_Description
,OS_Dep.StartDate as Dependencies_StartDate
,OS_Dep.EndDate as Dependencies_EndDate
,OS_Dep.LastDate as Dependencies_LastRunDate
,SP_EndDate	
,SP_LastRunDate
,SP_StartDate	
,SP_Duration
,SP_End_Hour
,P.ErrorMessage
from  (
select  distinct OS.ProcedureName
,OS.IsActive
,OS.ObjectStatus as Main_SP_Status
,di.ObjectStatusDesc as  Main_SP_Status_Description     
,isnull(DPS.TableName,'N/A') as Dependencies_Tables
,OS.LastDate as SP_LastRunDate
,OS.StartDate as SP_StartDate	
,OS.EndDate as SP_EndDate	
,OS.Duration as SP_Duration
,DATEPART( hour, OS.EndDate )  as  SP_End_Hour
,OS.ErrorMessage

 FROM  [dbo].[ObjectsStatus] OS WITH (nolock)
left  join  
 [dbo].[ProcedureDependencies] DPS WITH (nolock)
on OS.ProcedureName= DPS.[ProcedureName]
left  join  [dbo].ObjectsStatusDic di
on  OS.ObjectStatus= di.ObjectStatus
where (substring(OS.ProcedureName,1,11) ='Dealing_dbo'
or OS.ProcedureName='Dealing_staging.SP_Copy_PriceLog_History_CurrencyPrice')
  and OS.LastDate>cast(getdate() as date)
and  OS.FrequencySP='Daily' and OS.IsActive=1)P
left  join [dbo].[ObjectsStatus] OS_Dep WITH (nolock)
on P.Dependencies_Tables=OS_Dep.TableName
left join  [dbo].ObjectsStatusDic di2
on  OS_Dep.ObjectStatus= di2.ObjectStatus