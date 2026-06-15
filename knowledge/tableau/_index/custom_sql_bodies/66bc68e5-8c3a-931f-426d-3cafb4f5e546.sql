SELECT
    ais.Id as Id_AI_Session,
    ais.OwnerId as OwnerId_AI_Session,
    ais.CreatedDate as CreatedDate_AI_Session,
    ais.Name as Name_AI_Session,
    ais.Number_of_Messages__c as Number_of_Messages__c_AI_Session,
    ais.Case__c as Case__c_AI_Session,
    ais.Messaging_Session__c as Messaging_Session__c_AI_Session
    --Chat_Transcript__c as Chat_Transcript__c_AI_Session
    ,
    aise.Id as Id_AI_Session_Entry,
    aise.CreatedDate as CreatedDate_AI_Session_Entry,
    aise.IsDeleted as IsDeleted_AI_Session_Entry,
    aise.AI_Session__c as Al_Session__c_AI_Session_Entry,
    aise.Name as Name_AI_Session_Entry,
    aise.Message__c as Message__c_AI_Session_Entry,
    aise.Sender__c as Sender__c_AI_Session_Entry,
    aise.Type__c as Type__c_AI_Session_Entry,
    aise.User_Feedback__c as User_Feedback__c_AI_Session_Entry,
    aise.Bot_Message__c as Bot_Message__c_AI_Session_Entry
FROM main.crm.silver_crm_ai_session__c ais
LEFT JOIN main.crm.silver_crm_ai_session_entry__c aise
    on ais.id = aise.AI_Session__c
WHERE ais.CreatedDate >= curdate() - interval '1 year' and date(ais.createddate)>='2025-04-02'