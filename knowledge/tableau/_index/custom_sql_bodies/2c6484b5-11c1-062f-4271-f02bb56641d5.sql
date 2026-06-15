SELECT stg.CaseID
	  ,stg.CaseNumber
	  ,stg.CID
	  ,stg.Lead_FTD
	  ,stg.CreatedDate
	  ,stg.ClosedDate
	  ,stg.OwnerId
	  ,stg.CaseOwnerTitle
	  ,stg.MIMORoleQueue
	  ,stg.OwnerRoleName
	  ,stg.OwnerSubRole
	  ,stg.OwnerTeam
	  ,stg.AccountId
	  ,stg.ParentID
	  ,stg.RecordTypeID
	  ,stg.CustomerStatus
	  ,stg.ClubLevel
	  ,stg.Regulation
	  ,stg.Status
	  ,stg.StatusReason
	  ,stg.Origin
	  ,stg.Phase
	  ,stg.CaseSkills
	  ,stg.Subject
	  ,stg.Priority
	  ,stg.ServiceLanguage
	  ,stg.ServiceLanguageEmails
	  ,stg.Category
	  ,stg.Type
	  ,stg.Sub_Type
	  ,stg.Sub_Type_2
	  ,stg.Product
	  ,stg.AML_Stat
	  ,stg.AML_Status
	  ,stg.IsEscalated
	  ,stg.IsClosedOnCreate
	  ,stg.SlaStartDate
	  ,stg.SlaExitDate
	  ,stg.MilestoneStatus	
	  ,stg.IsInternalCase
	  ,stg.IsMIMOForOps
	  ,stg.IsKYCMonitoring
	  ,stg.IsJointCorporate
	  ,stg.IsReopened
	  ,stg.WithdrawalID
	  ,stg.DepositID
	  ,stg.PositionID
	  ,stg.MirrorID
	  ,stg.NumberOfIncomingEmailMessages
	  ,stg.NumberOfOutboundEmailMessages
	  ,stg.NumberOfInternalCaseComments
	  ,stg.NumberOfPublicCaseComments
	  ,stg.AttachmentsOnCaseComments
	  ,stg.NumberOfUpdates
	  ,stg.IsOneTouch
	  ,stg.X1stResponseDateTime
	  ,stg.TimeTo1stResponse
	  ,stg.FullResolutionTime
	  ,stg.ResolutionTimeFrom1stResponse
	  ,stg.SLABreached1stResponse
	  ,stg.VerificationLevel
	  ,stg.IsPI
	  ,stg.ChatScore
	  ,stg.SLAScore
	  ,stg.Score
	  ,stg.CounterRouting
	  ,stg.NumberOfPPRequests
	  ,stg.TotalTimeToResolve
	  ,stg.NumberOfTouches
	  ,stg.UpdateDate
	  ,stg.Country
	  ,stg.CreatedByID
	  ,bdsmu.Id
	  ,bdsmu.Username
	  ,bdsmu.Name
	  ,bdsmu.Department
	  ,bdsmu.Title
	  ,bdsmu.Email
	  ,bdsmu.Alias
	  ,bdsmu.IsActive
	  ,bdsmu.AccountManagerID
	  ,bdsmu.ServiceLevel
	  ,bdsmu.Desk
	  ,bdsmu.ServiceDesk
	  ,bdsmu.IsDummy
	  ,bdsmu.IsSupportUser
	  ,bdsmu.CSDesk
	  ,bdsmu.IsAssignable
	  ,bdsmu.SubDepartment
	  ,bdsmu.ReportsTo
	  ,bdsmu.DeskHiBOB
	  ,bdsmu.Site
	  ,bdsmu.IsOutsource
	  ,bdsmu.SubRole
	  ,bdsmu.Team
	  ,bdsmu.Position
	  ,bdsmu.IsSuperUser
	  ,bdsmu.IsWhatsappEligible
	  ,bdsmu.ChecksumID
	  ,bdsmu.FromDate
	  ,bdsmu.ToDate
	  ,ROW_NUMBER()OVER(PARTITION BY bdsmu.Id ORDER BY bdsmu.ToDate DESC) AS RN
	  ,bdscp.LastStatusDate
	  ,bdscp.TicketStatus
	  ,bdscp.TicketID
	  ,bdscp.HistoryID_AtOpen
	  ,bdscp.IsVisitor_Atopen
	  ,bdscp.DepositorType_AtOpen
	  ,bdscp.Regulation_AtOpen
	  ,bdscp.ClubTier_AtOpen
	  ,bdscp.Role_AtOpen
	  ,bdscp.SubRole_AtOpen
	  ,bdscp.ServiceLanguage_AtOpen
	  ,bdscp.ServiceDesk_AtOpen
	  ,bdscp.Phase_AtOpen
	  ,bdscp.Source_AtOpen
	  ,bdscp.Priority_AtOpen
	  ,bdscp.Product_AtOpen
	  ,bdscp.Type_AtOpen
	  ,bdscp.ActionType_AtOpen
	  ,bdscp.SubType_AtOpen
	  ,bdscp.SubType2_AtOpen
	  ,bdscp.Country_AtOpen
	  ,bdscp.PlayerStatus_AtOpen
	  ,bdscp.AccountManagerID_AtOpen
	  ,bdscp.ActiveAgentID_Atopen
	  ,bdscp.Owner_Atopen
	  ,bdscp.CID_Last
	  ,bdscp.HistoryID_Last
	  ,bdscp.IsVisitor_Last
	  ,bdscp.DepositorType_Last
	  ,bdscp.Regulation_Last
	  ,bdscp.ClubTier_Last
	  ,bdscp.Role_Last
	  ,bdscp.SubRole_Last
	  ,bdscp.ServiceLanguage_Last
	  ,bdscp.ServiceDesk_Last
	  ,bdscp.Phase_Last
	  ,bdscp.Source_Last
	  ,bdscp.Priority_Last
	  ,bdscp.Product_Last
	  ,bdscp.Type_Last
	  ,bdscp.ActionType_Last
	  ,bdscp.SubType_Last
	  ,bdscp.SubType2_Last
	  ,bdscp.Country_Last
	  ,bdscp.PlayerStatus_Last
	  ,bdscp.AccountManagerID_Last
	  ,bdscp.ActiveAgentID_Last
	  ,bdscp.Owner_Last
	  ,bdscp.FirstCSAT
	  ,bdscp.LastCSAT
	  ,bdscp.IsT3
	  ,bdscp.IsTechnicalTeam
	  ,bdscp.IsTmail
	  ,bdscp.IsCOCall
	  ,bdscp.IsCHBCase
	  ,bdscp.IsCOCase
	  ,bdscp.IsRisk
	  ,bdscp.IsOfficial
	  ,bdscp.IsSpam	
	  ,bdscp.IsInternal
	  ,bdscp.IsKYcMonitoring
	  ,bdscp.IsTechnicalRefund
	  ,bdscp.IsSocial
	  ,bdscp.IsGoodwill
	  ,bdscp.NumberOfTocuhes
	  ,bdscp.FirstResponse
	  ,bdscp.TotalTimeSpent
	  ,bdscp.NumberIncomingMessages
	  ,bdscp.NumberOutgoingMessages	  
	  ,bdscp.CloseDateTime
	  ,bdscp.IsNormal
	  ,bdscp.IsComplaint
	  ,bdscp.IsPhase2
	  ,bdscp.IsPhase3
	  ,bdscp.VerificationLevelID_AtOpen
	  ,bdscp.VerificationLevelID_Last
	  ,bdscp.DaysToReplyEmail
FROM [BI_DB].[dbo].[BI_DB_SF_STG_M_Case] stg
JOIN BI_DB.dbo.BI_DB_SF_M_Users bdsmu ON bdsmu.Id = stg.CreatedByID AND bdsmu.Name IN ('Krasimira Ivanova', 'Sarah Johnston','Ravit Lotan','Thomas Kelly')
JOIN BI_DB.dbo.BI_DB_SF_Cases_Panel bdscp ON bdscp.CaseNumber = stg.CaseNumber