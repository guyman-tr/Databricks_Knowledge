select 
	   [Date]
      ,[ChatID]
      ,[OwnerID]
      ,[ChatName]
      ,[ChatVisitorID]
      ,[AccountID]
      ,[SkillID]
      ,[RequestTime]
      ,[StartTime]
      ,[EndTime]
      ,[EndedBy]
      ,[AverageResponseTimeVisitor]
      ,[AverageResponseTimeOperator]
      ,[OperatorMessageCount]
      ,[VisitorMessageCount]
      ,[MaxResponseTimeOperator]
      ,[MaxResponseTimeVisitor]
      ,[ChatDuration]
      ,[WaitTime]
      ,[TimeAbondoned]
      ,[IsChatbot]
      ,[SystemModstamp]
      ,[LiveChatButtonID]
      ,[IsMissedChat]
      ,[IsBotEligible]
      ,[IsTimeOut]
      ,[IsConfused]
      ,[Platform]
,casetable.*
from (
SELECT bdssmc.CaseID
      ,bdssmc.CaseNumber
      ,bdssmc.CID
      ,bdssmc.Lead_FTD
      ,bdssmc.CreatedDate
      ,bdssmc.ClosedDate
      ,bdssmc.OwnerId
      ,bdssmc.CaseOwnerTitle
      ,bdssmc.ServiceDesk
      ,bdssmc.MIMORoleQueue
      ,bdssmc.OwnerRoleName
      ,bdssmc.OwnerSubRole
      ,bdssmc.OwnerTeam
      ,bdssmc.AccountId
      ,bdssmc.ParentID
      ,bdssmc.RecordTypeID
      ,bdssmc.CustomerStatus
      ,bdssmc.ClubLevel
      ,bdssmc.Regulation
      ,bdssmc.Status
      ,bdssmc.StatusReason
      ,bdssmc.Origin
      ,bdssmc.Phase
      ,bdssmc.CaseSkills
      ,bdssmc.Subject
      ,bdssmc.Priority
      ,bdssmc.ServiceLanguage
      ,bdssmc.ServiceLanguageEmails
      ,bdssmc.Category
      ,bdssmc.Type
      ,bdssmc.Sub_Type
      ,bdssmc.Sub_Type_2
      ,bdssmc.Product
      ,bdssmc.AML_Stat
      ,bdssmc.AML_Status
      ,bdssmc.IsEscalated
      ,bdssmc.IsClosedOnCreate
      ,bdssmc.SlaStartDate
      ,bdssmc.SlaExitDate
      ,bdssmc.MilestoneStatus
      ,bdssmc.IsSupervisorCall
      ,bdssmc.IsT3Case
      ,bdssmc.IsTechnicalTeamCase
      ,bdssmc.IsPPReport
      ,bdssmc.IsOfficialComplaint
      ,bdssmc.IsTmail
      ,bdssmc.IsCOCall
      ,bdssmc.IsCHBCase
      ,bdssmc.IsCOCASE
      ,bdssmc.IsSpam
      ,bdssmc.IsInternalCase
      ,bdssmc.IsMIMOForOps
      ,bdssmc.IsKYCMonitoring
      ,bdssmc.IsJointCorporate
      ,bdssmc.IsReopened
      ,bdssmc.WithdrawalID
      ,bdssmc.DepositID
      ,bdssmc.PositionID
      ,bdssmc.MirrorID
      ,bdssmc.NumberOfIncomingEmailMessages
      ,bdssmc.NumberOfOutboundEmailMessages
      ,bdssmc.NumberOfInternalCaseComments
      ,bdssmc.NumberOfPublicCaseComments
      ,bdssmc.AttachmentsOnCaseComments
      ,bdssmc.NumberOfUpdates
      ,bdssmc.IsOneTouch
      ,bdssmc.X1stResponseDateTime
      ,bdssmc.TimeTo1stResponse
      ,bdssmc.FullResolutionTime
      ,bdssmc.ResolutionTimeFrom1stResponse
      ,bdssmc.SLABreached1stResponse
      ,bdssmc.VerificationLevel
      ,bdssmc.IsPI
      ,bdssmc.ChatScore
      ,bdssmc.SLAScore
      ,bdssmc.Score
      ,bdssmc.CounterRouting
      ,bdssmc.NumberOfPPRequests
      ,bdssmc.TotalTimeToResolve
      ,bdssmc.NumberOfTouches
      ,bdssmc.UpdateDate
      ,bdssmc.Country 
      ,CASE WHEN oa.CID IS NOT NULL THEN 1 ELSE 0 END IsDeflected
FROM BI_DB.dbo.BI_DB_SF_STG_M_Case bdssmc
OUTER APPLY
(
SELECT c.CreatedDate,c.CID,c.Category
FROM BI_DB.dbo.BI_DB_SF_STG_M_Case c
WHERE c.Origin = 'Portal'
AND c.CID = bdssmc.CID
AND c.Category = bdssmc.Category
AND DATEDIFF(HOUR,c.CreatedDate,bdssmc.CreatedDate) <=24 
)oa ) casetable
left join BI_DB.dbo.BI_DB_SF_M_LiveChatTranscript chattable
on casetable.CaseNumber = chattable.CaseNumber