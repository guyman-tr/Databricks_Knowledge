SELECT ProcedureName,os.ObjectStatus,  DateParam, Duration,ErrorMessage,FrequencySP,
case when os.ObjectStatus=10 then 'Pending in Queue'
else ObjectStatusDesc end as Status,LastDate 
,case when FrequencySP='Daily' or FrequencySP='Hourly' then 1
when DATEPART(day,getdate())=1 and FrequencySP='Monthly' then 1
	WHEN DATENAME(WEEKDAY,getdate())='Sunday' and FrequencySP='Weekly Sunday'then 1
	WHEN DATENAME(WEEKDAY,getdate())='Monday' and FrequencySP='Weekly Monday'then 1
	WHEN DATENAME(WEEKDAY,getdate())='Tuesday' and FrequencySP='Weekly Tuesday'then 1
	else 0
	END AS Display
 FROM [DE_dbo].[ObjectsStatus] os with (nolock)
  left join  [DE_dbo].[ObjectsStatusDic] d on os.ObjectStatus=d.ObjectStatus
  WHERE IsActive=1 and Priority <>99
  and (ProcessName in ('SB_Daily' ,'SB_Hourly'))
and ProcedureName like '%SP%'