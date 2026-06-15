-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.crm_case_v
-- Captured: 2026-05-19T15:04:56Z
-- ==========================================================================

WITH deflection AS (
    SELECT DISTINCT
        date_trunc('month', c.CreatedDate) AS Month,
        c.Case_Id_18__c                   AS CaseId,
        'Chatbot'                         AS Type,
        CASE
            WHEN wcs.SessionId IS NOT NULL THEN 'MessagingSession'
            WHEN bec.Id IS NOT NULL THEN 'LiveChat'
        END                               AS BotPlatform
        -- COALESCE(wcs.SessionId, bec.Id)   AS BotSessionId
    FROM main.crm.gold_crm_case_tiny c
    LEFT JOIN (
        SELECT CaseId, SessionId
        FROM main.crm.gold_crm_web_chat_sessions
        WHERE CreatedDate >= current_date - INTERVAL '12 months'
          AND date(CreatedDate) <> '2025-05-28'
    ) wcs ON c.Case_Id_18__c = wcs.CaseId
    LEFT JOIN (
        SELECT Id, CaseId
        FROM main.crm.gold_crm_bot_eligible_chats
        WHERE CreatedDate >= current_date - INTERVAL '12 months'
    ) bec ON c.Case_Id_18__c = bec.CaseId
    WHERE c.Origin = 'Chatbot'
      AND (wcs.SessionId IS NOT NULL OR bec.Id IS NOT NULL)
      AND NOT EXISTS (
          SELECT 1 FROM main.crm.gold_crm_case_tiny f
          WHERE f.CID__c      = c.CID__c
            AND f.Category__c  = c.Category__c
            AND f.CreatedDate  > c.CreatedDate
            AND f.CreatedDate  <= c.CreatedDate + INTERVAL '24 hours'
            AND f.Origin IN ('Email', 'Portal')
      )
),
DeEscalation AS (
    SELECT CaseId
    FROM (
        SELECT CaseId, CreatedDate, IsDeEscalation,
               ROW_NUMBER() OVER (PARTITION BY CaseId ORDER BY CreatedDate DESC) RN
        FROM main.crm.gold_crm_case_deescalation
    )
    WHERE RN = 1
      AND IsDeEscalation = 0
),
Solved AS (
    SELECT CaseID, EventID, DoneBy, Touches, FromDate
    FROM (
        SELECT ROW_NUMBER() OVER (PARTITION BY CaseID ORDER BY FromDate DESC) AS rn,
               CaseID, DoneBy, Touches, EventID, FromDate
        FROM main.bi_output.bi_output_vg_case_event
        WHERE EventType = 'Status Update'
          AND NewStatus = 'Solved'
    )
    WHERE rn = 1
)
SELECT Id                                    AS CaseID
      ,CID__c                                AS CID
      ,CreatedDate
      ,CaseNumber
      ,Status
      ,Origin
      ,Subject
      ,Priority
      ,OwnerId
      ,Case_Owner_Title__c                   AS CaseOwnerTitle
      ,Solved__c                             AS IsSolved
      ,ClosedDate
      ,IsClosedOnCreate
      ,Service_Language__c                   AS ServiceLanguage
      ,Product__c                            AS Product
      ,Category__c                           AS Category
      ,Type__c                               AS CaseType
      ,Sub_Type__c                           AS SubType
      ,Sub_Type_2__c                         AS SubType2
      ,Withdrawal_ID__c                      AS WithdrawalID
      ,Deposit_ID__c                         AS DepositID
      ,Position_ID__c                        AS PositionID
      ,Mirror_ID__c                          AS MirrorID
      ,Phase__c                              AS Phase
      ,Official_Complaint__c                 AS IsOfficialComplaint
      ,Re_Opened__c                          AS IsReOpened
      ,Case_Created_By_Role__c               AS CaseCreatedByRole
      ,Number_of_Incoming_Email_Messages__c  AS IncomingEmailCount
      ,Number_of_Outbound_Email_Messages__c  AS OutboundEmailCount
      ,Number_of_Internal_Case_Comments__c   AS InternalCommentCount
      ,X1st_Response_Date_Time__c            AS FirstResponseDateTime
      ,Time_to_1st_Response__c               AS TimeToFirstResponse
      ,Resolution_Time_From_1st_Response__c  AS ResolutionTimeFromFirstResponse
      ,Total_time_to_Resolve_reports__c      AS TotalTimeToResolve
      ,Number_of_touches__c                  AS TouchCount
      ,Technical_Refund__c                   AS TechnicalRefund
      ,Owner_Sub_Role__c                     AS OwnerSubRole
      ,Jira_ID__c                            AS JiraID
      ,Goodwill_Gesture__c                   AS GoodwillGesture
      ,AML_State__c                          AS AMLState
      ,QC_Survey__c                          AS QCSurvey
      ,CaseSkillSet__c                       AS CaseSkillSet
      ,Regulation_on_Creation__c             AS Regulation
      ,Club_Level_on_Creation__c             AS ClubLevel
      ,Escalated_By__c                       AS EscalatedBy
      ,Escalation_Date__c                    AS EscalationDate
      ,CASE WHEN COALESCE(Escalation_Date__c,'1900-01-01T01:01:01.000+00:00') < '2025-01-01T01:01:01.000+00:00'
              AND Origin NOT IN ('Email','Manually','Chatbot')
              AND Case_Owner_Title__c <> 'OPS'
        THEN 1 ELSE 0 END                    AS IsEscalated
      ,Escalation_Status__c                  AS EscalationStatus
      ,Final_Escalation_Response_Date__c     AS FinalEscalationResponseDate
      ,CASE WHEN Owner_Sub_Role__c IN ('Escalation - eToro','Technical - eToro','Tier 1 - eToro','Tier 2 - eToro','Tier 3 - eToro') THEN 'CS' ELSE 'OPS' END AS CS_OPS
      ,CASE WHEN def.CaseId IS NULL THEN 0 ELSE 1 END AS IsDeflected
      ,CASE WHEN q1.CaseId IS NULL THEN 0 ELSE 1 END AS IsDeEscalated
      ,Closed_By__c                          AS ClosedBy
      ,slv.EventID
      ,slv.DoneBy
      ,slv.Touches
      ,slv.FromDate                          AS SolvedDate
FROM main.crm.silver_crm_case c
LEFT JOIN DeEscalation q1 ON c.Id = q1.CaseId
LEFT JOIN deflection def ON c.Id = def.CaseId
LEFT JOIN Solved slv ON c.Id = slv.CaseId
