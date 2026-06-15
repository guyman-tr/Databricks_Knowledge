WITH FilteredCases AS (
    SELECT
        c.id AS CaseId,
        c.CaseNumber,
        c.CID__c,
        to_timestamp(c.CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') AS CreatedDate,
        c.SystemModstamp,
        c.OwnerId AS CaseOwnerId,
        c.Service_Desk__c,
        c.Owner_role_name__c,
        c.Owner_Sub_Role__c,
        c.Club_Level_on_Creation__c,
        c.Regulation__c,
        c.Status,
        --c.Status_Reason__c,
        c.Origin,
        --c.Phase__c,
        --c.CaseSkills__c,
        c.Subject,
        c.Category__c,
        c.Type__c,
        c.Sub_Type__c,
        --c.Product__c,
        c.One_Touch__c,
        c.Time_to_1st_Response__c,
        c.Full_Resolution_Time__c,
        --c.Resolution_Time_From_1st_Response__c,
        c.Verification_Level__c,
        c.Chat_Score__c,
        c.SLA_Score__c,
        c.Score__c,
        --c.Counter_Routing__c,
        c.Number_of_touches__c,
        c.Country__c,
        c.Lead_or_FTD__c
    FROM main.crm.silver_crm_case c
    LEFT JOIN main.crm.silver_crm_livechattranscript t
        on c.id = t.caseid
    WHERE c.CreatedDate >= current_date - interval '12 months' and (t.visitormessagecount>0 or t.visitormessagecount is null)
),
PortalCases AS (
    SELECT *
        FROM FilteredCases
        Where Origin in ('Portal','Email')
),
DeflectedCases AS (
    SELECT
        c.casenumber,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM PortalCases p
                WHERE p.CID__c = c.CID__c
                      AND p.Category__c = c.Category__c
                      AND p.CreatedDate > c.CreatedDate
                      AND p.CreatedDate <= c.CreatedDate + INTERVAL '24 hour'
            ) THEN FALSE
            ELSE TRUE
        END AS IsDeflected
    FROM (
        SELECT DISTINCT
            CID__c,
            Category__c,
            CreatedDate,
            casenumber
        FROM FilteredCases
        WHERE origin ='Chatbot'
    ) c
)
SELECT
    case1.*,
    COALESCE(dc.IsDeflected, FALSE) AS IsDeflected,
    --chat.Abandoned AS Abandoned_chat,
    chat.AccountId AS AccountId_chat,
    chat.AverageResponseTimeOperator AS AverageResponseTimeOperator_chat,
    chat.AverageResponseTimeVisitor AS AverageResponseTimeVisitor_chat,
    chat.Body AS Body_chat,
    chat.Bot_Eligible__c AS Bot_Eligible__c_chat,
    chat.Browser AS Browser_chat,
    chat.BrowserLanguage AS BrowserLanguage_chat,
    chat.CaseId AS CaseId_chat,
    chat.ChatDuration AS ChatDuration_chat,
    --chat.ChatKey AS ChatKey_chat,
    --chat.ContactId AS ContactId_chat,
    chat.CreatedById AS CreatedById_chat,
    chat.CreatedDate AS CreatedDate_chat,
    chat.Created_Date_Time__c AS Created_Date_Time__c_chat,
    chat.Email__c AS Email__c_chat,
    --chat.EndTime AS EndTime_chat,
    chat.EndedBy AS EndedBy_chat,
    chat.Id AS Id_chat,
    chat.IsChatbotSession AS IsChatbotSession_chat,
    chat.LastModifiedById AS LastModifiedById_chat,
    --chat.LastModifiedDate AS LastModifiedDate_chat,
    --chat.LastReferencedDate AS LastReferencedDate_chat,
    --chat.LastViewedDate AS LastViewedDate_chat,
    chat.LeadId AS LeadId_chat,
    chat.LiveChatButtonId AS LiveChatButtonId_chat,
    --chat.LiveChatDeploymentId AS LiveChatDeploymentId_chat,
    --chat.LiveChatVisitorId AS LiveChatVisitorId_chat,
    chat.MaxResponseTimeOperator AS MaxResponseTimeOperator_chat,
    chat.MaxResponseTimeVisitor AS MaxResponseTimeVisitor_chat,
    chat.Name AS Name_chat,
    chat.OperatorMessageCount AS OperatorMessageCount_chat,
    chat.OwnerId AS OwnerId_chat,
    chat.Platform AS Platform_chat,
    chat.PlatformType__c AS PlatformType__c_chat,
    --chat.ReferrerUri AS ReferrerUri_chat,
    chat.SiteLanguage__c AS SiteLanguage__c_chat,
    chat.SkillId AS SkillId_chat,
    chat.Status AS Status_chat,
    --chat.SupervisorTranscriptBody AS SupervisorTranscriptBody_chat,
    --chat.SystemModstamp AS SystemModstamp_chat,
    --chat.UserAgent AS UserAgent_chat,
    chat.VisitorMessageCount AS VisitorMessageCount_chat,
    --chat.WaitTime AS WaitTime_chat,
    --chat.etr_y AS etr_y_chat,
    --chat.etr_ym AS etr_ym_chat,
    --chat.etr_ymd AS etr_ymd_chat,
    chat.Current_User_is_Owner__c AS Current_User_is_Owner__c_chat,
    chat.Bot_Type__c AS Bot_Type__c_chat,
    chat.Desk__c AS Desk__c_chat,
    chat.Is_Account_PI__c AS Is_Account_PI__c_chat,
    chat.Is_US_Customer__c AS Is_US_Customer__c_chat,
    --chat.Number_of_Account_s_Open_Cases__c AS Number_of_Account_s_Open_Cases__c_chat,
    chat.Summary_For_Chat_Transfer__c AS Summary_For_Chat_Transfer__c_chat,
    chat.Bot_Language_Eligible__c AS Bot_Language_Eligible__c_chat,
    chat.Case_Opened_by_Bot__c AS Case_Opened_by_Bot__c_chat,
    --chat.Chat_Transfer_Counter__c AS Chat_Transfer_Counter__c_chat,
    chat.Current_Skillset__c AS Current_Skillset__c_chat,
    --chat.Previous_Owner__c AS Previous_Owner__c_chat,
    chat.CSAT_Score__c AS CSAT_Score__c_chat,
    chat.Chat_Resolution_Status__c,
    chat.GenAI_Bot_Disclaimer_Status__c AS Disclaimer_Status,
    chat.Touchpoint__c as Touchpoint_chat,
    chat.Bot_Language__c as Bot_Language_chat
FROM FilteredCases case1
LEFT JOIN DeflectedCases dc 
ON case1.casenumber = dc.casenumber
LEFT JOIN main.crm.silver_crm_livechattranscript chat 
    ON case1.CaseId = chat.CaseId