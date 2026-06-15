SELECT 

  a.ActionType AS ActionType_AtOpen,
 a.ActionType AS ActionType_Last,
  a.CID AS CID_Last,
csat.Case_Number__c AS cSAT_Survey,
  a.CaseID AS CaseID,
a.Status AS Status,
  Users.CaseNumber AS CaseNumber_customquery,
  a.CaseNumber AS CaseNumber,
   a.CaseSkills as CaseSkills,
  Users.CaseOwner AS CaseOwner,
  a.ClosedDate AS CloseDateTime,
  a.ClubLevel AS ClubTier_AtOpen,
  a.ClubLevel AS ClubTier_Last,
hw.HasWallet,
a.Category,
  a.Country AS Country_AtOpen,
  a.Country AS Country_Last,
  a.CreatedDate AS CreatedDate,
  Users.Department AS Department,
  customquery.EventType_Internal AS EventType_Internal,
  customquery.EventType_Outbound AS EventType_Outbound,
  csat.Agent_Service__c AS AgentService,
    csat.Agent_Professionalism__c as AgentProffesionalism,
csat.Issue_Resolution__c as IssueResolution,
csat.Contact_Ease__c as ContactEase,
  a.X1stResponseDateTime AS FirstResponse,
  a.CHB_Case AS IsCHBCase,
  a.OfficialComplaint AS IsOfficial,
  a.GoodwillGesture AS IsGoodwill,
  a.InternalCase AS IsInternal,
  a.KYC_Monitoring AS IsKYcMonitoring,
  a.OneTouch AS IsOneTouch,
  a.PP_Report AS IsPPReport,
   Case when a.Phase='Normal' then 1 else 0 end as IsNormal,
   Case when a.Phase='Complaint' then 1 else 0 end as Complaint,
  Case when a.Phase='Phase 2' then 1 else 0 end as IsPhase2 ,
  Case when a.Phase='Phase 3' then 1 else 0 end as IsPhase3 ,
  a.Re_Opened AS IsReopened,
  a.Spam AS IsSpam,
  a.SupervisorCall AS IsSupervisorCall,
 a.T3Case AS IsT3,
  a.TechnicalRefund AS IsTechnicalRefund,
  a.TechnicalTeamCase AS IsTechnicalTeam,
  a.Tmail AS IsTmail,
  a.LastModifiedDate AS LastStatusDate,
  CONCAT(Users.FirstName, ' ', Users.LastName) AS Name,
  a.NumberOfIncomingEmailMessages AS NumberIncomingMessages,
  a.NumberOfTouches AS NumberOfTocuhes,
  a.NumberOfOutboundEmailMessages AS NumberOutgoingMessages,
  a.OwnerId AS Owner_Atopen,
  a.OwnerId AS Owner_Last,
  a.Phase AS Phase_AtOpen,
  a.Phase AS Phase_Last,
  a.CustomerStatus AS PlayerStatus_AtOpen,
  a.CustomerStatus AS PlayerStatus_Last,
  a.Priority AS Priority_AtOpen,
  a.Priority AS Priority_Last,
  a.Product AS Product_AtOpen,
  a.Product AS Product_Last,
  a.Regulation AS Regulation_AtOpen,
  a.Regulation AS Regulation_Last,
  a.OwnerSubRole AS Role_AtOpen,
  a.OwnerSubRole AS Role_Last,
  a.ServiceDesk AS ServiceDesk_AtOpen,
  a.ServiceDesk AS ServiceDesk_Last,
  a.ServiceLanguage AS ServiceLanguage_AtOpen,
  a.ServiceLanguage AS ServiceLanguage_Last,
  a.Origin AS Source_AtOpen,
  a.Origin AS Source_Last,
  a.OwnerRoleName AS SubRole_AtOpen,
  a.OwnerRoleName AS SubRole_Last,
  a.Sub_Type_2 AS SubType2_AtOpen,
  a.Sub_Type_2 AS SubType2_Last,
  a.Sub_Type AS SubType_AtOpen,
  a.Sub_Type AS SubType_Last,
  Users.Subrole_User AS Subrole_User,
  Users.Team AS Team,
  a.CaseID AS TicketID,
 a.Status AS TicketStatus,
  Users.Title AS Title,
  a.FullResolutionTime AS TotalTimeSpent,
  a.Type AS Type_AtOpen,
  a.Type AS Type_Last,
  a.VerificationLevel AS VerificationLevelID_AtOpen,
  a.VerificationLevel AS VerificationLevelID_Last,
  a.Product
FROM main.bi_output.bi_output_customer_customer_support_case a
left join crm.silver_crm_csat_survey_entry__c  csat on csat.Case_Number__c=a.CaseNumber and 
 (Issue_Resolution__c is not null or Agent_Service__c is not null or Agent_Professionalism__c is not null or Contact_Ease__c is not null)
  LEFT JOIN (
  SELECT bdsce.CaseID
  	  ,SUM(CASE WHEN bdsce.EventType = 'Outbound Email Message' THEN 1 ELSE 0   END) AS EventType_Outbound
  	  ,SUM(CASE WHEN bdsce.EventType = 'Internal Case Comment' THEN 1 ELSE 0   END) AS EventType_Internal  	
  FROM  main.bi_output.bi_output_customer_customer_support_case_event bdsce
  GROUP BY  bdsce.CaseID
) customquery ON (a.CaseID = customquery.CaseID)
  LEFT JOIN (
  SELECT bdscp.CaseNumber, 
 bdsmu.FirstName,
 bdsmu.LastName,
  bdsmu.Team, 
  bdsmu.Department, 
  bdsmu.Title, 
  bdsmu.SubRole as Subrole_User,
COALESCE(bdsmu.FirstName, 'Queue') AS CaseOwner
  FROM main.bi_output.bi_output_customer_customer_support_case bdscp
  LEFT JOIN main.bi_output.bi_output_customer_customer_support_agent_user bdsmu ON bdsmu.Id = bdscp.OwnerID AND YEAR(bdsmu.ToDate) = '9999'
) Users ON (a.CaseNumber = Users.CaseNumber)
left join (select RealCID,HasWallet from main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ) hw on hw.RealCID=a.CID