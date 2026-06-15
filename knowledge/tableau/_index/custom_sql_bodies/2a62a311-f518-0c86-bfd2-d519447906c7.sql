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
    WHERE CreatedDate >= current_date - interval '12 months' and createddate>='2025-04-02'
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
      ms.CreatedDate as CreatedDate_MessagingSession, 
      Desk__c as Desk_c_MessagingSession, 
      EndTime as EndTime_MessagingSession, 
      EndUserAccountId as EndUserAccountId_MessagingSession, 
      EndUserMessageCount as EndUserMessageCount_MessagingSession, 
      ms.Id as Id_MessagingSession, 
      MessagingEndUserId as MessagingEndUserId_MessagingSession, 
      ms.Name as Name_MessagingSession, 
      Origin as Origin_MessagingSession, 
      OwnerId as OwnerId_MessagingSession, 
      Routing_Reason__c as Routing_Reason_c_MessagingSession, 
      Status as Status_MessagingSession, 
      Termination_Reason__c as Termination_Reason_c_MessagingSession, 
      MessagingChannelId as MessagingChannelId_MessagingSession
  FROM main.crm.silver_crm_messagingsession ms
  join main.crm.silver_crm_messagingchannel mc
     ON ms.messagingchannelid = mc.Id
  WHERE ms.CreatedDate >= current_date - INTERVAL '12 months' and ms.createddate>='2025-04-02' and date(ms.CreatedDate)<>'2025-05-28' and mc.MasterLabel = "Customer Service Web Chat" 
),
LiveChat AS (
  select *
  from
  main.crm.silver_crm_livechattranscript t
    WHERE t.CreatedDate >= current_date - interval '12 months' and (t.visitormessagecount>0 or t.visitormessagecount is null)
)
SELECT 
    fc.*,
    COALESCE(dc.IsDeflected, false) AS IsDeflected,
    ms.*,
    lc.id as id_LiveChat,
    lc.visitormessagecount as VisitorMessageCount_LiveChat,
    lc.createddate as createddate_LiveChat,
    lc.Bot_Eligible__c AS Bot_Eligible__c_chat
    --,aw.*
FROM FilteredCases fc
LEFT JOIN DeflectedCases dc 
  ON fc.casenumber_case = dc.casenumber_case
full outer JOIN MessagingSessionFiltered ms 
  ON fc.id_case = ms.caseid_MessagingSession
full outer join LiveChat lc
  ON lc.caseid = fc.id_case