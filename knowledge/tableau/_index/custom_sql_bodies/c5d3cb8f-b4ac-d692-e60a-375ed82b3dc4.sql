SELECT 
  ms.createddate as CreatedDate_MessagingSession,
  ms.id as id_MessagingSession,
  ms.Name as Name_MessagingSession,
  ms.ChannelName as ChannelName_MessagingSession,
  ms.EndUserLanguage as EndUserLanguage_MessagingSession,
  ms.EndUserMessageCount as EndUserMessageCount_MessagingSession,
  ms.Translation_Feedback_Comment__c as Translation_Feedback_Comment__c_MessagingSession,
  ms.Translation_Feedback_Score__c as Translation_Feedback_Score__c_MessagingSession
FROM crm.silver_crm_messagingsession ms
WHERE createddate>= current_date - interval '12 months'
-- we are doing it like that because there are no related cases to whatsapp chats