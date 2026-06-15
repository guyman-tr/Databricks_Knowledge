WITH PortalCases AS (
    SELECT
        CID__c,
        Category__c,
        to_timestamp(CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') AS CreatedDate,
        ROW_NUMBER() OVER (PARTITION BY CID__c, Category__c ORDER BY SystemModstamp DESC) AS rn
    FROM main.crm.silver_crm_case
    WHERE Origin = 'Portal'
),
DeflectedCases AS (
    SELECT
        c.CID__c,
        c.Category__c,
        c.CreatedDate,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM main.crm.silver_crm_case p
                WHERE p.Origin = 'Portal'
                      AND p.CID__c = c.CID__c
                      AND p.Category__c = c.Category__c
                      AND p.CreatedDate >> c.CreatedDate
                      AND p.CreatedDate <<= c.CreatedDate + INTERVAL '24 hour'
            ) THEN 1
            ELSE 0
        END AS IsDeflected
    FROM (
        SELECT DISTINCT
            CID__c,
            Category__c,
            to_timestamp(CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') AS CreatedDate
        FROM main.crm.silver_crm_case
    ) c
)
SELECT
    case1.id AS CaseId,
    case1.CaseNumber,
    case1.CID__c,
    to_timestamp(case1.CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') AS CreatedDate,
    case1.SystemModstamp,
    case1.OwnerId AS CaseOwnerId,
    case1.Service_Desk__c,
    case1.Owner_role_name__c,
    case1.Owner_Sub_Role__c,
    case1.Club_Level_on_Creation__c,
    case1.Regulation__c,
    case1.Status,
    case1.Status_Reason__c,
    case1.Origin,
    case1.Phase__c,
    case1.CaseSkills__c,
    case1.Subject,
    case1.Category__c,
    case1.Type__c,
    case1.Sub_Type__c,
    case1.Product__c,
    case1.One_Touch__c,
    case1.Time_to_1st_Response__c,
    case1.Full_Resolution_Time__c,
    case1.Resolution_Time_From_1st_Response__c,
    case1.Verification_Level__c,
    case1.Chat_Score__c,
    case1.SLA_Score__c,
    case1.Score__c,
    case1.Counter_Routing__c,
    case1.Number_of_touches__c,
    case1.Country__c,
    COALESCE(dc.IsDeflected, 0) AS IsDeflected,
    chat.Abandoned AS Abandoned_chat,
    chat.AccountId AS AccountId_chat,
    chat.AverageResponseTimeOperator AS AverageResponseTimeOperator_chat,
    chat.AverageResponseTimeVisitor AS AverageResponseTimeVisitor_chat,
    chat.Body AS Body_chat,
    chat.Bot_Eligible__c AS Bot_Eligible__c_chat,
    chat.Browser AS Browser_chat,
    chat.BrowserLanguage AS BrowserLanguage_chat,
    chat.CaseId AS CaseId_chat,
    chat.ChatDuration AS ChatDuration_chat,
    chat.ChatKey AS ChatKey_chat,
    chat.ContactId AS ContactId_chat,
    chat.CreatedById AS CreatedById_chat,
    chat.CreatedDate AS CreatedDate_chat,
    chat.Created_Date_Time__c AS Created_Date_Time__c_chat,
    chat.Email__c AS Email__c_chat,
    chat.EndTime AS EndTime_chat,
    chat.EndedBy AS EndedBy_chat,
    chat.Id AS Id_chat,
    chat.IsChatbotSession AS IsChatbotSession_chat,
    chat.LastModifiedById AS LastModifiedById_chat,
    chat.LastModifiedDate AS LastModifiedDate_chat,
    chat.LastReferencedDate AS LastReferencedDate_chat,
    chat.LastViewedDate AS LastViewedDate_chat,
    chat.LeadId AS LeadId_chat,
    chat.LiveChatButtonId AS LiveChatButtonId_chat,
    chat.LiveChatDeploymentId AS LiveChatDeploymentId_chat,
    chat.LiveChatVisitorId AS LiveChatVisitorId_chat,
    chat.MaxResponseTimeOperator AS MaxResponseTimeOperator_chat,
    chat.MaxResponseTimeVisitor AS MaxResponseTimeVisitor_chat,
    chat.Name AS Name_chat,
    chat.OperatorMessageCount AS OperatorMessageCount_chat,
    chat.OwnerId AS OwnerId_chat,
    chat.Platform AS Platform_chat,
    chat.PlatformType__c AS PlatformType__c_chat,
    chat.ReferrerUri AS ReferrerUri_chat,
    chat.SiteLanguage__c AS SiteLanguage__c_chat,
    chat.SkillId AS SkillId_chat,
    chat.Status AS Status_chat,
    chat.SupervisorTranscriptBody AS SupervisorTranscriptBody_chat,
    chat.SystemModstamp AS SystemModstamp_chat,
    chat.UserAgent AS UserAgent_chat,
    chat.VisitorMessageCount AS VisitorMessageCount_chat,
    chat.WaitTime AS WaitTime_chat,
    chat.etr_y AS etr_y_chat,
    chat.etr_ym AS etr_ym_chat,
    chat.etr_ymd AS etr_ymd_chat,
    chat.Current_User_is_Owner__c AS Current_User_is_Owner__c_chat,
    chat.Bot_Type__c AS Bot_Type__c_chat,
    chat.Desk__c AS Desk__c_chat,
    chat.Is_Account_PI__c AS Is_Account_PI__c_chat,
    chat.Is_US_Customer__c AS Is_US_Customer__c_chat,
    chat.Number_of_Account_s_Open_Cases__c AS Number_of_Account_s_Open_Cases__c_chat,
    chat.Summary_For_Chat_Transfer__c AS Summary_For_Chat_Transfer__c_chat,
    chat.Bot_Language_Eligible__c AS Bot_Language_Eligible__c_chat,
    chat.Case_Opened_by_Bot__c AS Case_Opened_by_Bot__c_chat,
    chat.Chat_Transfer_Counter__c AS Chat_Transfer_Counter__c_chat,
    chat.Current_Skillset__c AS Current_Skillset__c_chat,
    chat.Previous_Owner__c AS Previous_Owner__c_chat,
    chat.CSAT_Score__c AS CSAT_Score__c_chat,
    chat.Touchpoint__c AS Touchpoint__c_chat,
    chat.Bot_Language__c AS Bot_Language__c_chat
FROM main.crm.silver_crm_case case1
LEFT JOIN DeflectedCases dc ON case1.CID__c = dc.CID__c
                             AND case1.Category__c = dc.Category__c
                             AND case1.CreatedDate = dc.CreatedDate
LEFT JOIN main.crm.silver_crm_livechattranscript chat ON case1.id = chat.CaseId
WHERE 
    case1.SystemModstamp IN (
        SELECT MAX(SystemModstamp)
        FROM main.crm.silver_crm_case
        WHERE CID__c = case1.CID__c
          AND Category__c = case1.Category__c
          AND CaseNumber = case1.CaseNumber
    )
    AND case1.CreatedDate >>= date_trunc('year', current_date - interval '1 year')