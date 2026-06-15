select  bdsmu.AccountManagerID
		,CONCAT(bdsmu.FirstName, ' ', bdsmu.LastName) Name
		,bdsmu.Team
		,bdsmu.IsActive
		,bdsmu.Position
		,bdsmu.ID
        ,CAST(trunc(CONVERT_TIMEZONE(TimeZoneSidKey, 'GMT', SurveyTakerDate), 'MM') AS DATE) ActiveDate
	    ,cast (CONVERT_TIMEZONE(TimeZoneSidKey, 'GMT', SurveyTakerDate) as date)  Date
        ,sum(ComplianceScore) ComplianceScore
        ,sum(QualityScore) QualityScore
	,avg(QualityScore)+sum(ComplianceScore) QCscore
from agent bdsmu
left join survey sv 
on bdsmu.ID = sv.AgentUnderAssesment
where IsCompleted='true'
and ClubLevel in ('Platinum', 'Gold', 'Silver')
group by bdsmu.AccountManagerID
		,CONCAT(bdsmu.FirstName, ' ', bdsmu.LastName) 
		,bdsmu.Team
		,bdsmu.IsActive
		,bdsmu.Position
		,bdsmu.ID
        ,CAST(trunc(CONVERT_TIMEZONE(TimeZoneSidKey, 'GMT', SurveyTakerDate), 'MM') AS DATE) 
	    ,cast (CONVERT_TIMEZONE(TimeZoneSidKey, 'GMT', SurveyTakerDate) as date)