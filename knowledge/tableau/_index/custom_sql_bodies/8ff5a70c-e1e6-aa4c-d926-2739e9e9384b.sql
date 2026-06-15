SELECT 
    s.id as id_s,
    s.name as name_s,
    s.createddate as createddate_s,
    s.Chat_Transcript__c as Chat_Transcript__c_s,
    se.id as id_se,
    se.name as name_se,
    se.CreatedDate as CreatedDate_se,
    se.message__c as message_se,
    se.type__c as type_se,
    se.sender__c as sender_se,
    se.Bot_Message__c as Bot_Message_se,
    se.User_Feedback__c as User_Feedback_se,
    ms.CaseId
FROM main.crm.silver_crm_ai_session__c s
JOIN main.crm.silver_crm_messagingsession ms
  on s.messaging_session__c = ms.id
LEFT JOIN main.crm.silver_crm_ai_session_entry__c se
    on s.id = se.AI_Session__c
WHERE s.CreatedDate > '2025-04-08'

UNION ALL
SELECT
    s.id as id_s,
    s.name as name_s,
    s.createddate as createddate_s,
    s.Chat_Transcript__c as Chat_Transcript__c_s,
    se.id as id_se,
    se.name as name_se,
    se.CreatedDate as CreatedDate_se,
    se.message__c as message_se,
    se.type__c as type_se,
    se.sender__c as sender_se,
    se.Bot_Message__c as Bot_Message_se,
    se.User_Feedback__c as User_Feedback_se,
    t.CaseId
FROM main.crm.silver_crm_ai_session__c s
JOIN main.crm.silver_crm_livechattranscript t
  on s.Chat_Transcript__c = t.id
LEFT JOIN main.crm.silver_crm_ai_session_entry__c se
    on s.id = se.AI_Session__c
WHERE s.CreatedDate > '2025-04-08'