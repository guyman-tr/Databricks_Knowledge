SELECT  ProcedureName,FrequencySP, max(LastDate) LastUpdated	
FROM [DE_dbo].[ObjectsStatusHistory]
where ObjectStatus=2  and LastDate >= DATEADD(month, DATEDIFF(month, 0, getdate()), 0)
and ProcedureName like '%SP%'
--and FrequencySP='Daily'
group by ProcedureName,FrequencySP