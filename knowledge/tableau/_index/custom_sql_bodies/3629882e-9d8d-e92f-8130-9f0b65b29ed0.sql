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
	  ,bdsmst.TypeOfComminication 'Type Of Comminication'
	  ,bdsmst.AgentUnderAssessment_Team
	  ,bdsmst.AgentUnderAssessmentSubrole
	  ,bdsmst.AgentUnderAssessmentPosition
	  ,bdsmst.UpdateDate 
	  ,bdsmu.Username
	  ,bdsmu.FirstName +' '+ LastName AS Name 
	  ,bdsmu.Department
	  ,bdsmu.Title
	  ,bdsmu.IsActive
	  ,bdsmu.AccountManagerID
	  ,bdsmu.Desk
	  ,NULL AS CSDesk
	  ,bdsmu.ReportsTo
	  ,bdsmu.Site
	  ,bdsmu.Team
	  ,bdsmu.Position
	  ,bdsmu.ToDate
FROM BI_DB_dbo.External_BI_OUTPUT_Customer_Customer_Support_Agent_User bdsmu
Left JOIN [BI_DB_dbo].[External_BI_OUTPUT_Customer_Facing_Survey_Taker] bdsmst
ON bdsmst.AgentUnderAssesment = bdsmu.ID
and bdsmst.TypeOfComminication in ('Phone Call','Zoom Call','Email','WhatsApp')
AND bdsmst.SurveyTakerDate>= EOMONTH(DATEADD(MONTH,-4,GETDATE()))
WHERE bdsmu.ToDate = '9999-12-31T00:00:00.000Z'