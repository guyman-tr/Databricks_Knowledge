WITH UnifiedChats AS (
    -- 1. LEGACY: LiveChatTranscript
    SELECT 
        lct.CaseId,
        lct.Touchpoint__c
    FROM main.crm.silver_crm_livechattranscript lct
    WHERE 
        lct.VisitorMessageCount > 0 
        AND lct.Touchpoint__c = 'webSiteChatCustomerServicePage'
        AND lct.CreatedDate > '2025-04-08'

    UNION ALL

    -- 2. MODERN: MessagingSession
    SELECT 
        ms.CaseId,
        ms.Touchpoint__c
    FROM main.crm.silver_crm_messagingsession ms
    WHERE 
        ms.EndUserMessageCount > 0 
        AND ms.Touchpoint__c = 'Help Center'
        -- Using Case CreatedDate downstream, so broad time filter here is fine
),

FilteredCases AS (
    SELECT
        c.id AS CaseId,
        c.CaseNumber,
        c.CID__c,
        to_timestamp(c.CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') AS CreatedDate,
        c.Club_Level_on_Creation__c,
        c.Regulation__c,
        c.Status,
        c.Origin,
        c.Subject,
        c.Category__c,
        c.Type__c,
        c.Sub_Type__c,
        c.One_Touch__c,
        c.Chat_Score__c,
        c.Score__c,
        c.Country__c,
        c.Lead_or_FTD__c,
        c.GCID__c,
        c.IsClosedOnCreate,
        c.description,
        c.Translated_Description_Summary__c,
        c.Sentiment__c,
        c.accountid as accountid_case
    FROM main.crm.silver_crm_case c
    -- JOIN CHANGED: Swapped 'relevantChats' for 'UnifiedChats'
    LEFT JOIN UnifiedChats t
        ON c.id = t.CaseId
    WHERE c.CreatedDate > '2025-04-08'
),

PortalCases AS (
    SELECT *
    FROM FilteredCases
    Where Origin in ('Portal','Email')
),

-- LOGIC PRESERVED EXACTLY AS REQUESTED
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
            fc.CID__c,
            fc.Category__c,
            fc.CreatedDate,
            fc.casenumber
        FROM FilteredCases fc
        WHERE origin = 'Chatbot' -- Original strict filter maintained
    ) c
),

-- LOGIC PRESERVED EXACTLY AS REQUESTED
IsFollowUpTicket AS (
    SELECT
       p.casenumber,
       CASE
            WHEN EXISTS (
                SELECT 1
                FROM FilteredCases fc
                WHERE p.CID__c = fc.CID__c
                    AND p.CreatedDate > fc.CreatedDate
                    AND p.CreatedDate <= fc.CreatedDate + INTERVAL '24 hour'
                    AND fc.Origin in ('Chatbot','Chat') -- Original strict filter maintained
            ) THEN true
            ELSE false
       END AS IsFollowUp
    FROM PortalCases p
)

SELECT
    case1.*,
    COALESCE(dc.IsDeflected, false) AS IsDeflected,
    COALESCE(IsFollowUpTicket.IsFollowUp, false) AS IsFollowUp,
    
    -- THE ONLY NEW FIELD
    chat.Touchpoint__c AS Touchpoint_chat

FROM FilteredCases case1
LEFT JOIN DeflectedCases dc 
    ON case1.casenumber = dc.casenumber
LEFT JOIN IsFollowUpTicket
    ON case1.casenumber = IsFollowUpTicket.casenumber
LEFT JOIN UnifiedChats chat 
    ON case1.CaseId = chat.CaseId