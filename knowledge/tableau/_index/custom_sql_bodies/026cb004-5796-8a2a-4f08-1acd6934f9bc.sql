WITH FilteredCases AS (
    SELECT
        id AS id_Case,
        CaseNumber AS CaseNumber_Case,
        CID__c AS CID__c_Case,
        to_timestamp(CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') AS CreatedDate_Case,
        to_timestamp(ClosedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') AS ClosedDate_Case,
        SystemModstamp AS SystemModstamp_Case,
        OwnerId AS CaseOwnerId_Case,
        Service_Desk__c AS Service_Desk__c_Case,
        Owner_role_name__c AS Owner_role_name__c_Case,
        Owner_Sub_Role__c AS Owner_Sub_Role__c_Case,
        Club_Level_on_Creation__c AS Club_Level_on_Creation__c_Case,
        Regulation__c AS Regulation__c_Case,
        Status AS Status_Case,
        Status_Reason__c AS Status_Reason__c_Case,
        Origin AS Origin_Case,
        Phase__c AS Phase__c_Case,
        CaseSkills__c AS CaseSkills__c_Case,
        Subject AS Subject_Case,
        Category__c AS Category__c_Case,
        Type__c AS Type__c_Case,
        Sub_Type__c AS Sub_Type__c_Case,
        Product__c AS Product__c_Case,
        One_Touch__c AS One_Touch__c_Case,
        Time_to_1st_Response__c AS Time_to_1st_Response__c_Case,
        Full_Resolution_Time__c AS Full_Resolution_Time__c_Case,
        Resolution_Time_From_1st_Response__c AS Resolution_Time_From_1st_Response__c_Case,
        Verification_Level__c AS Verification_Level__c_Case,
        Chat_Score__c AS Chat_Score__c_Case,
        SLA_Score__c AS SLA_Score__c_Case,
        Score__c AS Score__c_Case,
        Counter_Routing__c AS Counter_Routing__c_Case,
        Number_of_touches__c AS Number_of_touches__c_Case,
        Country__c AS Country__c_Case,
        Lead_or_FTD__c AS Lead_or_FTD__c_Case,
        GCID__c AS GCID__c_Case
    FROM main.crm.silver_crm_case
    WHERE CreatedDate >= current_date - interval '12 months' AND CreatedDate >= '2025-04-02'
),
DeflectedCases AS (
    SELECT
        c.casenumber_case,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM FilteredCases p
                WHERE p.CID__c_Case = c.CID__c_Case
                      AND p.Category__c_Case = c.Category__c_Case
                      AND p.CreatedDate_Case > c.CreatedDate_Case
                      AND p.CreatedDate_Case <= c.CreatedDate_Case + INTERVAL '24 hour'
                      AND p.Origin_Case in ('Email','Portal')
            ) THEN false
            ELSE true
        END AS IsDeflected
    FROM (
        SELECT DISTINCT
            CID__c_Case,
            Category__c_Case,
            CreatedDate_Case,
            ClosedDate_Case,
            casenumber_case
        FROM FilteredCases
        WHERE origin_Case = 'Chatbot'
    ) c
),
IsFollowUpTicket AS (
    SELECT
       p.CaseNumber_Case,
       CASE
            WHEN EXISTS (
                SELECT 1
                FROM FilteredCases fc
                WHERE p.CID__c_Case = fc.CID__c_Case
                    AND p.CreatedDate_Case > fc.ClosedDate_Case
                    AND p.CreatedDate_Case <= fc.CreatedDate_Case + INTERVAL '24 hour'
                    AND fc.Origin_Case in ('Chatbot')
                    AND p.Origin_Case in ('Email','Portal')
                    AND p.Category__c_Case = fc.Category__c_Case
            ) THEN true
            ELSE false
        END AS IsFollowUp
    FROM FilteredCases p
),
MessagingSessionFiltered AS (
  SELECT 
      AcceptTime as AcceptTime_MessagingSession, 
      Account__c as Account_c_MessagingSession, 
      AgentMessageCount as AgentMessageCount_MessagingSession, 
      AgentType as AgentType_MessagingSession, 
      CaseId as CaseId_MessagingSession, 
      ChannelName as ChannelName_MessagingSession, 
      ChannelType as ChannelType_MessagingSession, 
      ConversationId as ConversationId_MessagingSession, 
      CreatedDate as CreatedDate_MessagingSession, 
      Desk__c as Desk_c_MessagingSession, 
      EndTime as EndTime_MessagingSession, 
      EndUserAccountId as EndUserAccountId_MessagingSession, 
      EndUserMessageCount as EndUserMessageCount_MessagingSession, 
      Id as Id_MessagingSession, 
      MessagingEndUserId as MessagingEndUserId_MessagingSession, 
      Name as Name_MessagingSession, 
      Origin as Origin_MessagingSession, 
      OwnerId as OwnerId_MessagingSession, 
      Routing_Reason__c as Routing_Reason_c_MessagingSession, 
      Status as Status_MessagingSession, 
      Termination_Reason__c as Termination_Reason_c_MessagingSession, 
      MessagingChannelId as MessagingChannelId_MessagingSession
  FROM main.crm.silver_crm_messagingsession ms
  WHERE CreatedDate >= current_date - INTERVAL '12 months' AND CreatedDate >= '2025-04-02' AND date(ms.CreatedDate)<>'2025-05-28'
),
MessagingChannelFiltered AS (
  SELECT
    Id as Id_MessagingChannel,
    CreatedById as CreatedById_MessagingChannel,
    CreatedDate as CreatedDate_MessagingChannel,
    IsoCountryCode as IsoCountryCode_MessagingChannel,
    IsActive as IsActive_MessagingChannel,
    IsRestrictedToBusinessHours as IsRestrictedToBusinessHours_MessagingChannel,
    MasterLabel as MasterLabel_MessagingChannel,
    MessageType as MessageType_MessagingChannel
  FROM main.crm.silver_crm_messagingchannel
),
conversationFiltered AS (
  SELECT
    Id as Id_conversation,
    Name as Name_conversation,
    CreatedDate as CreatedDate_conversation,
    StartTime as StartTime_conversation,
    EndTime as EndTime_conversation,
    ConversationChannelid as ConversationChannelid_conversation
  FROM main.crm.silver_crm_conversation
),
-- REMOVED conversationEntryFiltered CTE completely
MessagingSessionHistory AS (
    SELECT DISTINCT -- Added DISTINCT to prevent duplicate rows if multiple history events exist
    messagingsessionid
    FROM main.crm.silver_crm_messagingsessionhistory
    WHERE 
        field ='Status' and 
        OldValue = 'Inactive' and 
        newvalue ='Ended' and 
        CreatedDate >= current_date - INTERVAL '12 months' AND CreatedDate >= '2025-04-02'
)
SELECT 
    fc.*,
    COALESCE(dc.IsDeflected, false) AS IsDeflected,
    COALESCE(IsFollowUpTicket.IsFollowUp, false) AS IsFollowUp,
    
    -- Indicating if the session was ended due to inactivity
   CASE
        WHEN ms.Id_MessagingSession IS NOT NULL THEN 
            CASE
                WHEN msh.messagingsessionid IS NOT NULL THEN TRUE
                ELSE FALSE
            END
        ELSE NULL 
    END AS IsEndedDueToInactivity,
    
    ms.*,
    mc.*,
    conversation.*
    -- Removed conversationEntry.*
FROM FilteredCases fc
LEFT JOIN DeflectedCases dc 
  ON fc.casenumber_case = dc.casenumber_case
LEFT JOIN IsFollowUpTicket
    ON fc.CaseNumber_Case = IsFollowUpTicket.CaseNumber_Case
-- Including sessions without related cases (whatsapp as an example)
FULL OUTER JOIN MessagingSessionFiltered ms 
  ON fc.id_case = ms.caseid_MessagingSession
LEFT JOIN MessagingChannelFiltered mc
  ON ms.messagingchannelid_MessagingSession = mc.Id_MessagingChannel
LEFT JOIN conversationFiltered conversation
  on ms.conversationid_MessagingSession = conversation.Id_conversation
-- REMOVED LEFT JOIN conversationEntryFiltered
LEFT JOIN MessagingSessionHistory msh
    on msh.messagingsessionid = ms.Id_MessagingSession