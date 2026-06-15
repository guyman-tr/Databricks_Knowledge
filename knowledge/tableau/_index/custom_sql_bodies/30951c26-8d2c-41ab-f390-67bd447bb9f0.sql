select top 100 
t.Id ,RunningStatus,DatabaseName,SchemaName,TableName, BusinessGroup, NextExecution,LastProcessDate,LastUpdateDate,TriggerDescription,FrequencyUnit,DatalakeContainer, CURRENT_TIMESTAMP as CurrentTime ,DATEDIFF(minute,LastUpdateDate,CURRENT_TIMESTAMP) AS DateDiff
FROM [dbo].[SQLSourcesMapping] m
left join  [dbo].[SQLSourcesObjectType] obt
on obt.Id = m.ObjectTypeId
left join  [dbo].[SQLSourcesDatalakeCopyStrategy] cs
on cs.Id = m.DataLakeCopyId
left join [dbo].[SQLSourcesFileType] ft
on ft.Id = m.DatalakeFileTypeId
left join [dbo].[SQLSourcesID] s
on s.Id = m.Id
left join [dbo].[SQLSourcesTriggerStatus] t
on s.Id = t.Id


order by LastUpdateDate desc