select bdsmu.AccountManagerID
		,CONCAT(bdsmu.FirstName, ' ', bdsmu.LastName) Name
		,bdsmu.Team
		,bdsmu.IsActive
		,bdsmu.Position
		,bduts.ActionType
		,bdsmu.ID
		 ,CAST(trunc(CONVERT_TIMEZONE(TimeZoneSidKey, 'GMT', Date), 'MM') AS DATE) ActiveDate
	  ,cast (CONVERT_TIMEZONE(TimeZoneSidKey, 'GMT', Date) as date)  Date
	,CAST(DATE_FORMAT(bduts.etr_ymd, 'yyyyMMdd') AS INT)   DateID 
        ,count(*) NumOfCall
from agent bdsmu
left join agent_engagement bduts
on bduts.CreatedByID = bdsmu.ID
AND etr_ymd>='2025-03-01'
WHERE bdsmu.ToDate = '9999-12-31T00:00:00.000Z'
group by bdsmu.AccountManagerID
		,CONCAT(bdsmu.FirstName, ' ', bdsmu.LastName) 
		,bdsmu.Team
		,bdsmu.IsActive
		,bdsmu.Position
		,bduts.ActionType
		,bdsmu.ID
		 ,CAST(trunc(CONVERT_TIMEZONE(TimeZoneSidKey, 'GMT', Date), 'MM') AS DATE)
	  ,cast (CONVERT_TIMEZONE(TimeZoneSidKey, 'GMT', Date) as date) 
	,CAST(DATE_FORMAT(bduts.etr_ymd, 'yyyyMMdd') AS INT)