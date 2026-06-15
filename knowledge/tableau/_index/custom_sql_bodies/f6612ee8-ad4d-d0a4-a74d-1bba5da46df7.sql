WITH FilteredCases AS (
    SELECT
        c.id AS CaseId,
        c.CaseNumber,
        c.CID__c,
        to_timestamp(c.CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') AS CreatedDate,
        c.Origin,
        c.Category__c,
        c.Type__c,
        c.Initial_Sub_Type__c,
        c.Initial_Sub_Type_2__c,
        c.Sub_Type__c,
        c.Sub_Type_2__c,
        c.Country__c,
        c.IsClosedOnCreate,
        dictc.name as Registration_country,
        CASE 
            WHEN (c.initial_sub_type__c in ("2FA")
                  AND c.Initial_Sub_Type_2__c in ("2FA -Other", "Cannot activate", "Code not working", "Did not receive voice call", "Didn't receive SMS")) THEN "2FA"
            WHEN c.initial_sub_type__c in ("General question - Other", "Account details - Other", "My Profile") THEN 'General Question Cases'
            WHEN c.initial_sub_type__c in ("Cannot withdraw", "Withdrawal - Other", "Status of withdrawal") THEN 'Withdrawal Cases'
            WHEN c.initial_sub_type__c = "Login issues" THEN "Login Issue Cases"
            WHEN c.sub_type__c = "Phone Verification" THEN "Phone Verification Cases"
            WHEN (c.initial_sub_type__c ="Detail Change" AND c.Initial_Sub_Type_2__c ="Phone") THEN "Phone Detail Change Cases"
            WHEN (c.initial_sub_type__c = "Detail Change" AND c.Initial_Sub_Type_2__c in ("Details change - Other", "Email", "Address")) THEN 'Detail Change Cases'
            -- WHEN c.initial_sub_type__c = 'Trade cannot be opened' AND dictc.name='Germany' THEN 'Trade Cannot Be Opened'
            -- WHEN c.initial_sub_type__c ='Trade cannot be closed' AND dictc.name='Germany' THEN 'Trade Cannot Be Closed'
            WHEN c.Initial_Sub_Type__c = 'General technical issues - Other' then 'General Tech Issue'
            ELSE NULL
        END AS classification
        -- ,CASE WHEN c.initial_sub_type__c = "Trading options and/or limitations" then "Trading Options Cases" END -- Moved from classification logic
    FROM main.crm.silver_crm_case c
    LEFT JOIN main.crm.silver_crm_livechattranscript t
        ON c.id = t.caseid
    LEFT JOIN general.bronze_etoro_customer_customer_masked cm
        ON c.cid__c = cm.cid
    LEFT JOIN general.bronze_etoro_dictionary_country dictc
        ON cm.countryID = dictc.countryID
    WHERE c.CreatedDate >= '2018-01-01' and 
    (t.visitormessagecount<>0 or t.visitormessagecount is null)
    and (t.Bot_Eligible__c<>False or t.Bot_Eligible__c is null)
),
TemplateDeflectedCases AS (
    SELECT
        c.casenumber,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM FilteredCases p
                WHERE p.CID__c = c.CID__c
                      AND (p.Category__c = c.Category__c OR p.origin IN ('Chatbot','Chat'))
                      -- AND p.Category__c = c.Category__c
                      AND p.CreatedDate > c.CreatedDate
                      AND p.CreatedDate <= c.CreatedDate + INTERVAL '24 hour'
                      -- AND p.origin in ('Portal','Email')
            ) THEN FALSE
            ELSE TRUE
        END AS TemplateDeflected
    FROM (
        SELECT DISTINCT
            CID__c,
            Category__c,
            CreatedDate,
            casenumber
        FROM FilteredCases
        WHERE origin in ('Portal','Email') AND classification IS NOT NULL AND NOT (Registration_country = 'United States') AND CreatedDate >= '2024-11-23'
    ) c
),
ChatbotDeflectedCases AS (
    SELECT
        c.casenumber,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM FilteredCases p
                WHERE p.CID__c = c.CID__c
                      AND p.Category__c = c.Category__c
                      AND p.CreatedDate > c.CreatedDate
                      AND p.CreatedDate <= c.CreatedDate + INTERVAL '24 hour'
                      AND p.origin in ('Portal','Email') 
                      -- AND P.Origin in ('Chat','Chatbot','Email','Portal')
                      -- currently we are going with the lighter logic which checks only for follow up tickets without chats
            ) THEN FALSE
            ELSE TRUE
        END AS ChatbotDeflected
    FROM (
        SELECT DISTINCT
            CID__c,
            Category__c,
            CreatedDate,
            casenumber
        FROM FilteredCases
        WHERE origin = 'Chatbot'
    ) c
)
SELECT
    case1.CaseId,
    case1.CaseNumber,
    case1.CID__c,
    case1.CreatedDate,
    case1.Origin,
    case1.Category__c,
    case1.Type__c,
    case1.Initial_Sub_Type__c,
    case1.Initial_Sub_Type_2__c,
    case1.Sub_Type__c,
    case1.Sub_Type_2__c,
    case1.Country__c,
    case1.IsClosedOnCreate,
    case1.classification,
    case1.Registration_country,
    COALESCE(tdc.TemplateDeflected, FALSE) AS TemplateDeflected,
    COALESCE(cdc.ChatbotDeflected, FALSE) AS ChatbotDeflected--,
    -- chat.Abandoned AS Abandoned_chat,
    -- chat.AccountId AS AccountId_chat,
    -- chat.Bot_Eligible__c AS Bot_Eligible__c_chat,
    -- chat.BrowserLanguage AS BrowserLanguage_chat,
    -- chat.CaseId AS CaseId_chat,
    -- chat.ChatDuration AS ChatDuration_chat,
    -- chat.CreatedById AS CreatedById_chat,
    -- chat.CreatedDate AS CreatedDate_chat,
    -- chat.Created_Date_Time__c AS Created_Date_Time__c_chat,
    -- chat.Email__c AS Email__c_chat,
    -- chat.Id AS Id_chat,
    -- chat.IsChatbotSession AS IsChatbotSession_chat,
    -- chat.LiveChatButtonId AS LiveChatButtonId_chat,
    -- chat.Name AS Name_chat,
    -- chat.Status AS Status_chat,
    -- chat.VisitorMessageCount AS VisitorMessageCount_chat,
    -- chat.Current_User_is_Owner__c AS Current_User_is_Owner__c_chat,
    -- chat.Bot_Type__c AS Bot_Type__c_chat,
    -- chat.Is_US_Customer__c AS Is_US_Customer__c_chat,
    -- chat.Bot_Language_Eligible__c AS Bot_Language_Eligible__c_chat,
    -- chat.Case_Opened_by_Bot__c AS Case_Opened_by_Bot__c_chat,
    -- chat.CSAT_Score__c AS CSAT_Score__c_chat,
    -- chat.Chat_Resolution_Status__c
FROM FilteredCases case1
LEFT JOIN TemplateDeflectedCases tdc 
    ON case1.casenumber = tdc.casenumber
LEFT JOIN ChatbotDeflectedCases cdc 
    ON case1.casenumber = cdc.casenumber
LEFT JOIN main.crm.silver_crm_livechattranscript chat 
    ON case1.CaseId = chat.CaseId