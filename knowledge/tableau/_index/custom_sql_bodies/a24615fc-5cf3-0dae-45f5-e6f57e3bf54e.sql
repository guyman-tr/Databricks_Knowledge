WITH relevantChats AS (
    SELECT *
    FROM main.crm.silver_crm_livechattranscript t
    WHERE t.visitormessagecount>>0 and createddate>> current_date - INTERVAL '1 year'
)
,FilteredCases AS (
    SELECT
        c.id AS CaseId_case,
        c.CaseNumber AS CaseNumber_case,
        c.CID__c AS CID__c_case,
        to_timestamp(c.CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') AS CreatedDate_case,
        c.Club_Level_on_Creation__c AS Club_Level_on_Creation__c_case,
        c.Regulation__c AS Regulation__c_case,
        c.Status AS Status_case,
        c.Origin AS Origin_case,
        c.Subject AS Subject_case,
        c.Category__c AS Category__c_case,
        c.Type__c AS Type__c_case,
        c.Sub_Type__c AS Sub_Type__c_case,
        c.One_Touch__c AS One_Touch__c_case,
        c.Chat_Score__c AS Chat_Score__c_case,
        c.Score__c AS Score__c_case,
        c.Country__c AS Country__c_case,
        c.Lead_or_FTD__c AS Lead_or_FTD__c_case,
        c.GCID__c AS GCID__c_case,
        c.IsClosedOnCreate AS IsClosedOnCreate_case
    FROM main.crm.silver_crm_case c
    LEFT JOIN relevantChats t
        ON c.id = t.caseid
    WHERE c.CreatedDate >>= current_date - INTERVAL '1 year'
),
PortalCases AS (
    SELECT *
        FROM FilteredCases
        Where Origin_case in ('Portal','Email')
),
DeflectedCases AS (
    SELECT
        c.casenumber,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM PortalCases p
                WHERE p.CID__c_case = c.CID__c
                    AND p.Category__c_case = c.Category__c
                    AND p.CreatedDate_case >> c.CreatedDate
                    AND p.CreatedDate_case <<= c.CreatedDate + INTERVAL '24 hour'
            ) THEN FALSE
            ELSE TRUE
        END AS IsDeflected
    FROM (
        SELECT DISTINCT
            fc.CID__c_case AS CID__c,
            fc.Category__c_case AS Category__c,
            fc.CreatedDate_case AS CreatedDate,
            fc.CaseNumber_case AS casenumber
        FROM FilteredCases fc
    WHERE Origin_case = 'Chatbot'
    ) c
),
IsFollowUpTicket AS (
    SELECT
        p.CaseNumber_case AS casenumber,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM FilteredCases fc
                WHERE p.CID__c_case = fc.CID__c_case
                    AND p.CreatedDate_case >> fc.CreatedDate_case
                    AND p.CreatedDate_case <<= fc.CreatedDate_case + INTERVAL '24 hour'
                    AND fc.Origin_case in ('Chatbot','Chat')
            ) THEN true
            ELSE false
        END AS IsFollowUp
    FROM PortalCases p
)
SELECT
    case1.*,
    COALESCE(dc.IsDeflected, false) AS IsDeflected,
    COALESCE(IsFollowUpTicket.IsFollowUp, false) AS IsFollowUp,
    chat.AccountId AS AccountId_chat,
    chat.Bot_Eligible__c AS Bot_Eligible__c_chat,
    chat.BrowserLanguage AS BrowserLanguage_chat,
    chat.CaseId AS CaseId_chat,
    chat.ChatDuration AS ChatDuration_chat,
    chat.CreatedDate AS CreatedDate_chat,
    chat.Created_Date_Time__c AS Created_Date_Time__c_chat,
    chat.Email__c AS Email__c_chat,
    chat.Id AS Id_chat,
    chat.IsChatbotSession AS IsChatbotSession_chat,
    chat.LiveChatButtonId AS LiveChatButtonId_chat,
    chat.Name AS Name_chat,
    chat.OwnerId AS OwnerId_chat,
    chat.Status AS Status_chat,
    chat.VisitorMessageCount AS VisitorMessageCount_chat,
    chat.Bot_Type__c AS Bot_Type__c_chat,
    chat.Is_US_Customer__c AS Is_US_Customer__c_chat,
    chat.Bot_Language_Eligible__c AS Bot_Language_Eligible__c_chat,
    chat.CSAT_Score__c AS CSAT_Score__c_chat,
    chat.Chat_Resolution_Status__c,
    chat.GenAI_Bot_Disclaimer_Status__c AS Disclaimer_Status,
    chat.Touchpoint__c as Touchpoint_chat
FROM FilteredCases case1
LEFT JOIN DeflectedCases dc
    ON case1.CaseNumber_case = dc.casenumber
LEFT JOIN IsFollowUpTicket
    ON case1.CaseNumber_case = IsFollowUpTicket.casenumber
LEFT JOIN main.crm.silver_crm_livechattranscript chat
    ON case1.CaseId_case = chat.CaseId
order by CID__c_case, CreatedDate_case desc