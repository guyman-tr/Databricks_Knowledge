SELECT bdsmst.SurveyTakerID
	  ,bdsmst.SurveyTakerName
	  ,bdsmst.SurveyTakerDate
	  ,bdsmst.CaseID
	  ,bdsmst.IsCompleted
	  ,bdsmst.Survey__c
	  ,bdsmst.QC_Agent
	  ,bdsmst.AgentUnderAssesment
	  ,bdsmst.CID
	  ,bdsmst.CommentsCompliance
	  ,bdsmst.CommentsQuality
	  ,bdsmst.ComplianceScore
	  ,bdsmst.QualityScore
	  ,bdsmst.TypeOfComminication
	  ,bdsmst.AgentUnderAssessment_Team
	  ,bdsmst.AgentUnderAssessmentSubrole
	  ,bdsmst.AgentUnderAssessmentPosition
	  ,bdsmst.UpdateDate 
	  ,bdsmu.Username
	  ,bdsmu.Name 
	  ,bdsmu.Department
	  ,bdsmu.Title
	  ,bdsmu.IsActive
	  ,bdsmu.AccountManagerID
	  ,bdsmu.Desk
	  ,bdsmu.CSDesk
	  ,bdsmu.ReportsTo
	  ,bdsmu.Site
	  ,bdsmu.Team
	  ,bdsmu.Position
FROM BI_DB_SF_M_Users bdsmu
Left JOIN BI_DB_SF_M_SurveyTaker bdsmst
ON bdsmst.AgentUnderAssesment = bdsmu.Id
and bdsmst.TypeOfComminication = 'Phone Call'
AND bdsmst.SurveyTakerDate>= EOMONTH(DATEADD(MONTH,-4,GETDATE()))
WHERE bdsmu.ToDate = '9999-12-31'