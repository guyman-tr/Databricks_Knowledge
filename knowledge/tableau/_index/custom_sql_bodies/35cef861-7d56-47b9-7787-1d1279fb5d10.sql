select  bdsmu.AccountManagerID
	,CONCAT(bdsmu.FirstName, ' ', bdsmu.LastName) Name
	,bdsmu.Team
	,bdsmu.IsActive
	,bdsmu.Position
	,bdsmu.ID
	,ClubLevel
        ,CAST(trunc(CONVERT_TIMEZONE(TimeZoneSidKey, 'GMT', SurveyTakerDate), 'MM') AS DATE) ActiveDate
	 ,cast (CONVERT_TIMEZONE(TimeZoneSidKey, 'GMT', SurveyTakerDate) as date)  Date
	,ComplianceScore
	,QualityScore
        ,SurveyTakerID
	,CID
	,TypeOfComminication
        ,CommentsCompliance
        ,CommentsQuality

from agent bdsmu
left join survey sv 
on bdsmu.ID = sv.AgentUnderAssesment
where IsCompleted='true'