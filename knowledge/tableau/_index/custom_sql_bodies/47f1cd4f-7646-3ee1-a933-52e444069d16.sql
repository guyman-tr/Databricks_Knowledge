-- 1. Feedback from Messaging Sessions (WhatsApp & Some Web)
SELECT 
    -- If it's WhatsApp, match to the MessagingSession Id. Otherwise, match to the Case Id.
    CASE 
        WHEN ms.ChannelType = 'WhatsApp' THEN ms.Id
        ELSE ms.CaseId 
    END AS Interaction_ID,
    aise.User_Feedback__c,
    aise.Id AS Feedback_Entry_ID,
    aise.CreatedDate AS Feedback_Date
FROM main.crm.silver_crm_ai_session__c ais
JOIN main.crm.silver_crm_messagingsession ms
  ON ais.messaging_session__c = ms.id
JOIN main.crm.silver_crm_ai_session_entry__c aise
  ON ais.id = aise.AI_Session__c
-- Dynamic Date: Beginning of Last Year
WHERE ais.CreatedDate >= date_trunc('year', current_date) - interval '1 year' 
  AND date(ais.createddate) >= '2025-04-02'

UNION ALL

-- 2. Feedback from Live Chat Transcripts (Legacy Web)
SELECT 
    t.CaseId AS Interaction_ID,
    aise.User_Feedback__c,
    aise.Id AS Feedback_Entry_ID,
    aise.CreatedDate AS Feedback_Date
FROM main.crm.silver_crm_ai_session__c ais
JOIN main.crm.silver_crm_livechattranscript t
  ON ais.Chat_Transcript__c = t.id
JOIN main.crm.silver_crm_ai_session_entry__c aise
  ON ais.id = aise.AI_Session__c
-- Dynamic Date: Beginning of Last Year
WHERE ais.CreatedDate >= date_trunc('year', current_date) - interval '1 year'