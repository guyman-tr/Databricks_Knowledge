WITH 
-- ==============================================================================
-- 1. WEB CHAT BOT LOGIC
-- ==============================================================================
Web_FilteredCases AS (
    SELECT
        case.id AS id_Case,
        case.CaseNumber AS CaseNumber_Case,
        case.CID__c AS CID__c_Case,
        to_timestamp(case.CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') AS CreatedDate_Case,
        to_timestamp(case.ClosedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') AS ClosedDate_Case,
        case.Service_Desk__c AS Service_Desk__c_Case,
        case.Club_Level_on_Creation__c AS Club_Level_on_Creation__c_Case,
        case.Regulation__c AS Regulation__c_Case,
        case.Origin AS Origin_Case,
        case.Country__c AS Country__c_Case,
        case.Lead_or_FTD__c AS Lead_or_FTD__c_Case,
        case.Category__c AS Category__c_Case, 
        t.Id AS Id_chattranscript, 
        t.Bot_Eligible__c AS Bot_Eligible__c_chattranscript
    FROM main.crm.silver_crm_case case
    LEFT JOIN main.crm.silver_crm_livechattranscript t
        ON t.caseid = case.id
    WHERE case.CreatedDate >= date_trunc('year', current_date) - interval '1 year'
    AND (t.visitormessagecount <> 0 OR t.visitormessagecount IS NULL)
    AND (t.Bot_Eligible__c <> False OR t.Bot_Eligible__c IS NULL)
),
Web_DeflectedCases AS (
    SELECT
        c.casenumber_case,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM Web_FilteredCases p
                WHERE p.CID__c_Case = c.CID__c_Case
                      AND p.Category__c_Case = c.Category__c_Case 
                      AND p.CreatedDate_Case > c.CreatedDate_Case
                      AND p.CreatedDate_Case <= c.CreatedDate_Case + INTERVAL '24 hour'
                      AND p.Origin_Case IN ('Email','Portal')
            ) THEN false
            ELSE true
        END AS IsDeflected
    FROM (
        SELECT DISTINCT CID__c_Case, Category__c_Case, CreatedDate_Case, casenumber_case
        FROM Web_FilteredCases
        WHERE Origin_Case = 'Chatbot'
    ) c
),
Web_MessagingSessionFiltered AS (
  SELECT DISTINCT
      CaseId AS CaseId_MessagingSession
  FROM main.crm.silver_crm_messagingsession ms
  WHERE ms.CreatedDate >= date_trunc('year', current_date) - interval '1 year' 
    AND date(ms.CreatedDate) <> '2025-05-28' 
),
Web_Final AS (
    SELECT 
        fc.id_Case AS Interaction_ID,
        fc.CreatedDate_Case AS Interaction_Date,
        'Web Chat' AS Channel,
        fc.CID__c_Case AS Customer_CID,
        fc.Country__c_Case AS Country,
        fc.Regulation__c_Case AS Regulation,
        fc.Club_Level_on_Creation__c_Case AS Club_Level,
        fc.Service_Desk__c_Case AS Service_Desk,
        fc.Lead_or_FTD__c_Case AS Lead_or_FTD,
        COALESCE(dc.IsDeflected, false) AS Is_Deflected,
        TRUE AS Is_Eligible,
        1 AS Total_Interactions
    FROM Web_FilteredCases fc
    LEFT JOIN Web_DeflectedCases dc 
      ON fc.casenumber_case = dc.casenumber_case
    LEFT JOIN Web_MessagingSessionFiltered ms 
      ON fc.id_case = ms.CaseId_MessagingSession
    WHERE fc.Origin_Case IN ('Chat', 'Chatbot')
        AND (COALESCE(fc.Origin_Case, '') <> 'Chat'
       OR fc.Id_chattranscript IS NOT NULL 
       OR ms.CaseId_MessagingSession IS NOT NULL)
),

-- ==============================================================================
-- 2. WHATSAPP LOGIC
-- ==============================================================================
WA_target_whatsapp_sessions AS (
    SELECT 
        ms.Id AS Id_MS_Inbound,
        ms.EndUserAccountId,
        ms.CreatedDate AS CreatedDate_MS_Inbound,
        ms.AgentType AS AgentType_MS,
        ms.Route_to_another_AM__c AS Route_to_another_AM__c_MS,
        ms.Country__c AS Country__c_MS,
        ms.Regulation__c AS Regulation__c_MS,
        ms.Customer_Level__c AS Customer_Level__c_MS,
        ms.Desk__c AS Desk__c_MS,
        amp.GCID__c AS GCID_MS,
        amp.Customer_Unique_ID_CID__c AS CID_MS
    FROM main.crm.silver_crm_messagingsession ms
    LEFT JOIN main.crm.silver_crm_accountidmappingtable amp 
        ON ms.EndUserAccountId = amp.Id
    WHERE ms.ChannelType = 'WhatsApp'
      AND ms.CreatedDate >= '2026-02-10'
      AND ms.EndUserMessageCount > 0 
      AND ms.Origin <> 'TriggeredOutbound'
      AND ms.AgentType IN ('Bot', 'BotToAgent') 
),
WA_calendly_matched AS (
    SELECT 
        b.Id_MS_Inbound,
        cal.Id AS Calendly_Event_Id,
        ROW_NUMBER() OVER(PARTITION BY b.Id_MS_Inbound ORDER BY cal.EventCreatedAt__c ASC) as rnk_cal
    FROM WA_target_whatsapp_sessions b
    JOIN main.pii_data.bronze_etoro_customer_customer cust
        ON CAST(b.GCID_MS AS STRING) = CAST(cust.GCID AS STRING)
    JOIN main.crm.silver_crm_calendlyaction__c cal
        ON cal.InviteeEmail__c = cust.Email
        AND cal.EventCreatedAt__c >= b.CreatedDate_MS_Inbound
        AND cal.EventCreatedAt__c <= b.CreatedDate_MS_Inbound + INTERVAL 14 DAY
),
WA_task_matched AS (
    SELECT 
        b.Id_MS_Inbound,
        tk.Id AS Offline_Task_Id,
        ROW_NUMBER() OVER(PARTITION BY b.Id_MS_Inbound ORDER BY tk.CreatedDate ASC) as rnk_task
    FROM WA_target_whatsapp_sessions b
    JOIN main.crm.silver_crm_task tk
        ON b.EndUserAccountId = tk.AccountId
        AND tk.Type = 'Missed Whatsapp'
        AND tk.CreatedDate >= b.CreatedDate_MS_Inbound
        AND tk.Description LIKE CONCAT('%', b.Id_MS_Inbound, '%') 
),
WA_ticket_matched AS (
    SELECT 
        b.Id_MS_Inbound,
        c.Id AS Case_Id,
        ROW_NUMBER() OVER(PARTITION BY b.Id_MS_Inbound ORDER BY c.CreatedDate ASC) as rnk_ticket
    FROM WA_target_whatsapp_sessions b
    JOIN main.crm.silver_crm_case c
        ON c.CID__c = b.CID_MS
        AND c.CreatedDate >= b.CreatedDate_MS_Inbound
        AND c.CreatedDate <= b.CreatedDate_MS_Inbound + INTERVAL '24 hour'
        AND c.Origin IN ('Email', 'Portal') 
),
WA_Final AS (
    SELECT 
        b.Id_MS_Inbound AS Interaction_ID,
        b.CreatedDate_MS_Inbound AS Interaction_Date,
        'WhatsApp' AS Channel,
        b.CID_MS AS Customer_CID,
        b.Country__c_MS AS Country,
        b.Regulation__c_MS AS Regulation,
        b.Customer_Level__c_MS AS Club_Level,
        b.Desk__c_MS AS Service_Desk,
        CAST(NULL AS STRING) AS Lead_or_FTD, 
        CASE 
            WHEN b.AgentType_MS <> 'Bot' THEN FALSE
            WHEN cal.Calendly_Event_Id IS NOT NULL THEN FALSE 
            WHEN tk.Offline_Task_Id IS NOT NULL THEN FALSE 
            WHEN tm.Case_Id IS NOT NULL THEN FALSE 
            WHEN b.Route_to_another_AM__c_MS = TRUE THEN FALSE 
            ELSE TRUE 
        END AS Is_Deflected,
        TRUE AS Is_Eligible,
        1 AS Total_Interactions
    FROM WA_target_whatsapp_sessions b
    LEFT JOIN WA_calendly_matched cal ON b.Id_MS_Inbound = cal.Id_MS_Inbound AND cal.rnk_cal = 1
    LEFT JOIN WA_task_matched tk ON b.Id_MS_Inbound = tk.Id_MS_Inbound AND tk.rnk_task = 1
    LEFT JOIN WA_ticket_matched tm ON b.Id_MS_Inbound = tm.Id_MS_Inbound AND tm.rnk_ticket = 1
),

-- ==============================================================================
-- 3. AUTO-RESOLVED TICKETS LOGIC
-- ==============================================================================
Ticket_FilteredCases AS (
    SELECT
        c.id AS CaseId,
        c.CaseNumber,
        c.CID__c,
        to_timestamp(c.CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') AS CreatedDate,
        c.Origin,
        c.Category__c,
        c.Country__c,
        c.Regulation__c,
        c.Club_Level_on_Creation__c,
        c.Service_Desk__c,
        c.Lead_or_FTD__c,
        c.IsClosedOnCreate,
        dictc.name as Registration_country,
        CASE
            WHEN (c.initial_sub_type__c in ('2FA') and c.Initial_Sub_Type_2__c in ('2FA -Other', 'Cannot activate', 'Code not working', 'Did not receive voice call', 'Didn''t receive SMS'))  THEN '2FA'
            WHEN c.initial_sub_type__c in ('General question - Other', 'Account details - Other', 'My Profile')  THEN 'General Question Cases'
            WHEN c.initial_sub_type__c in ('Cannot withdraw', 'Withdrawal - Other', 'Status of withdrawal') THEN 'Withdrawal Cases'
            WHEN c.initial_sub_type__c = 'Login issues'  THEN 'Login Issue Cases'
            WHEN c.sub_type__c = 'Phone Verification' THEN 'Phone Verification Cases'
            WHEN (c.initial_sub_type__c ='Detail Change' and c.Initial_Sub_Type_2__c ='Phone')  THEN 'Phone Detail Change Cases'
            WHEN (c.initial_sub_type__c = 'Detail Change' and c.Initial_Sub_Type_2__c in ('Details change - Other', 'Email', 'Address')) THEN 'Detail Change Cases'
            WHEN c.initial_sub_type__c ='General technical issues - Other' then 'General Tech Issue'
            ELSE null
        END as classification
    FROM main.crm.silver_crm_case c
    LEFT JOIN general.bronze_etoro_customer_customer_masked cm
        ON c.cid__c = cm.cid
    LEFT JOIN general.bronze_etoro_dictionary_country dictc
        ON cm.countryID = dictc.countryID
    WHERE CreatedDate > '2024-11-22' AND origin IN ('Portal','Email')
),
Ticket_FollowUpCases AS (
    SELECT 
        c1.cid__c,
        c1.category__c,
        to_timestamp(c1.CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') as CreatedDate,
        c1.origin
    FROM main.crm.silver_crm_case c1
    LEFT JOIN main.crm.silver_crm_livechattranscript t
        ON c1.id = t.caseid
    WHERE to_timestamp(c1.CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') > '2024-11-22' 
      AND (t.visitormessagecount > 0 OR t.visitormessagecount IS NULL)
),
Ticket_DeflectedCases AS (
    SELECT
        c.casenumber,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM Ticket_FollowUpCases p
                WHERE p.CID__c = c.CID__c
                    AND (p.Category__c = c.Category__c OR p.origin IN ('Chatbot','Chat'))
                    AND p.CreatedDate > c.CreatedDate
                    AND p.CreatedDate <= c.CreatedDate + INTERVAL '24 hour'
            ) THEN FALSE
            ELSE TRUE
        END AS IsDeflected
    FROM (
        SELECT DISTINCT CID__c, Category__c, CreatedDate, casenumber
        FROM Ticket_FilteredCases
    ) c
),
Ticket_Final AS (
    SELECT
        case1.CaseId AS Interaction_ID,
        case1.CreatedDate AS Interaction_Date,
        'Ticket' AS Channel,
        case1.CID__c AS Customer_CID,
        case1.Country__c AS Country,
        case1.Regulation__c AS Regulation,
        case1.Club_Level_on_Creation__c AS Club_Level,
        case1.Service_Desk__c AS Service_Desk,
        case1.Lead_or_FTD__c AS Lead_or_FTD,
        CASE 
            WHEN case1.classification IS NOT NULL 
                 AND case1.Registration_country IS NOT NULL
                 AND case1.Registration_country <> 'United States'
                 AND case1.IsClosedOnCreate = TRUE 
                 AND COALESCE(dc.IsDeflected, FALSE) = TRUE 
            THEN TRUE 
            ELSE FALSE 
        END AS Is_Deflected,
        CASE 
            WHEN case1.classification IS NOT NULL 
                 AND case1.Registration_country IS NOT NULL
                 AND case1.Registration_country <> 'United States'
            THEN TRUE
            ELSE FALSE
        END AS Is_Eligible,
        1 AS Total_Interactions
    FROM Ticket_FilteredCases case1
    LEFT JOIN Ticket_DeflectedCases dc
      ON case1.casenumber = dc.casenumber
)

-- ==============================================================================
-- THE UNIFIED OUTPUT
-- ==============================================================================
SELECT * FROM Web_Final
UNION ALL
SELECT * FROM WA_Final
UNION ALL
SELECT * FROM Ticket_Final