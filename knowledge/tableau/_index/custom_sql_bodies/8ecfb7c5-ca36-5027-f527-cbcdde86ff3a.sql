WITH combined_triggers AS (
    -- 1. Gather Low Tier Triggers (Filtered from Feb 10, 2026)
    SELECT
        t.Id AS Id_mt,
        t.Account__c AS Account__c_mt,
        t.Trigger_BI_Id__c AS Trigger_BI_Id__c_mt,
        t.Trigger_Created_Date__c AS Trigger_Created_Date__c_mt,
        t.name AS name_mt,
        'Low' AS TriggerTier_mt,
        amp.GCID__c AS GCID__c_mt,
        t.Last_Account_Manager__c AS Last_Account_Manager__c_mt,
        t.status__c AS status__c_mt,
        -- === ADDED: The WhatsApp Gatekeeper Field for Low Tier ===
        t.whatsapp_status__c AS whatsapp_status__c_mt
    FROM main.crm.silver_crm_low_tier_trigger__c t
    JOIN main.crm.silver_crm_accountidmappingtable amp 
        ON t.Account__c = amp.Id
    WHERE t.Trigger_Created_Date__c >= '2026-02-10'

    UNION ALL

    -- 2. Gather High Tier Triggers (Filtered from Feb 10, 2026)
    SELECT
        t.Id AS Id_mt,
        t.Account__c AS Account__c_mt,
        t.Trigger_BI_Id__c AS Trigger_BI_Id__c_mt,
        t.Trigger_Created_Date__c AS Trigger_Created_Date__c_mt,
        t.name AS name_mt,
        'High' AS TriggerTier_mt,
        amp.GCID__c AS GCID__c_mt,
        t.Last_Account_Manager__c AS Last_Account_Manager__c_mt,
        t.status__c AS status__c_mt,
        -- === ADDED: Synthetically generating the Gatekeeper Field for High Tier ===
        CASE 
            WHEN t.Status__c = '5' AND t.Substatus__c = 'Exceeded Daily Priority Limit' THEN 'Sent'
            ELSE NULL 
        END AS whatsapp_status__c_mt
    FROM main.crm.silver_crm_call_to_action__c t
    JOIN main.crm.silver_crm_accountidmappingtable amp 
        ON t.Account__c = amp.Id
    WHERE t.Trigger_Created_Date__c >= '2026-02-10'
),
outbound_matched AS (
    -- 3. Find the FIRST TriggeredOutbound session within 14 days of the trigger
    SELECT 
        mt.*,
        ms.Id AS Id_MS_Outbound,
        ms.CreatedDate AS CreatedDate_MS_Outbound,
        ms.Email__c AS Email__c_MS_Outbound,
        ROW_NUMBER() OVER(
            PARTITION BY mt.Id_mt 
            ORDER BY ms.CreatedDate ASC
        ) as session_rank_out
    FROM combined_triggers mt
    LEFT JOIN main.crm.silver_crm_messagingsession ms
        -- CRUCIAL FIX: Using EndUserAccountId for the outbound trigger match
        ON mt.Account__c_mt = ms.EndUserAccountId 
        AND ms.ChannelType = 'WhatsApp'
        AND ms.Origin = 'TriggeredOutbound'
        AND ms.CreatedDate >= '2026-02-10' 
        AND ms.CreatedDate >= mt.Trigger_Created_Date__c_mt
        AND ms.CreatedDate <= mt.Trigger_Created_Date__c_mt + INTERVAL 14 DAY
),

base_outbound AS (
    -- Filter to only keep the true matches (the first outbound session)
    SELECT * FROM outbound_matched WHERE session_rank_out = 1
),

inbound_matched AS (
    -- 4. Find the FIRST InboundInitiated session within 3 days of the outbound message
    SELECT 
        b.*,
        
        -- === ACTIVE RELEVANT FIELDS FROM MESSAGING SESSION ===
        ms_in.Id AS Id_MS_Inbound,
        ms_in.OwnerId AS OwnerId_MS,
        ms_in.CreatedDate AS CreatedDate_MS_Inbound,
        ms_in.Origin AS Origin_MS,
        ms_in.AgentType AS AgentType_MS,
        ms_in.Status AS Status_MS,
        ms_in.ChannelType AS ChannelType_MS,
        ms_in.EndUserMessageCount AS EndUserMessageCount_MS,
        ms_in.AgentMessageCount AS AgentMessageCount_MS,
        ms_in.Body__c AS Body__c_MS,
        ms_in.First_Message__c AS First_Message__c_MS,
        ms_in.Transfer_Counter__c AS Transfer_Counter__c_MS,
        ms_in.Email__c AS Email__c_MS,
        ms_in.Customer_Level__c AS Customer_Level__c_MS,
        ms_in.Customer_Status__c AS Customer_Status__c_MS,
        ms_in.Regulation__c AS Regulation__c_MS,
        ms_in.EndedByType AS EndedByType_MS,
        ms_in.Desk__c AS Desk__c_MS,
        ms_in.Owner_Desk__c AS Owner_Desk__c_MS,
        ms_in.Session_Owner_custom__c AS Session_Owner_custom__c_MS,
        ms_in.CID__c AS CID__c_MS,
        ms_in.Account_GCID__c AS Account_GCID__c_MS,
        ms_in.EndUserLanguage AS EndUserLanguage_MS,
        ms_in.Site_Language__c AS Site_Language__c_MS,
        ms_in.Name AS Name_MS,
        ms_in.CaseId AS CaseId_MS,
        ms_in.AcceptTime AS AcceptTime_MS,
        ms_in.StartTime AS StartTime_MS,
        ms_in.EndTime AS EndTime_MS,
        ms_in.Country__c AS Country__c_MS,
        ms_in.First_Name__c AS First_Name__c_MS,
        ms_in.Last_Customer_Input__c AS Last_Customer_Input__c_MS,
        ms_in.Player_Level_Id__c AS Player_Level_Id__c_MS,
        ms_in.Regulation_Id__c AS Regulation_Id__c_MS,
        ms_in.Origin__c AS Origin__c_MS,
        ms_in.Route_to_another_AM__c AS Route_to_another_AM__c_MS, 

        ROW_NUMBER() OVER(
            PARTITION BY b.Id_mt 
            ORDER BY ms_in.CreatedDate ASC
        ) as session_rank_in
    FROM base_outbound b
    LEFT JOIN main.crm.silver_crm_messagingsession ms_in
        -- CRUCIAL FIX: Using EndUserAccountId for the inbound reply match as well
        ON b.Account__c_mt = ms_in.EndUserAccountId 
        AND ms_in.ChannelType = 'WhatsApp'
        AND ms_in.Origin <> 'TriggeredOutbound'
        AND ms_in.CreatedDate >= '2026-02-10'
        AND ms_in.CreatedDate >= b.CreatedDate_MS_Outbound
        AND ms_in.CreatedDate <= b.CreatedDate_MS_Outbound + INTERVAL 3 DAY
),

base_inbound AS (
    -- Ensure we keep the triggers even if the customer never responded inbound
    SELECT * FROM inbound_matched WHERE session_rank_in = 1 OR Id_MS_Inbound IS NULL
),

optin_matched AS (
    -- 5. Check if the customer unsubscribed (SettingStatus = 0) within 3 days of the outbound message
    SELECT 
        b.Id_mt,
        opt.StatusChangeDate AS Unsubscribe_Date,
        ROW_NUMBER() OVER(PARTITION BY b.Id_mt ORDER BY opt.StatusChangeDate ASC) as rnk_opt
    FROM base_inbound b
    JOIN main.bizops_output.bizops_output_notifications_silver_whatsapp_optin opt
        ON CAST(b.GCID__c_mt AS STRING) = CAST(opt.GCID AS STRING)
        AND opt.SettingStatus = 0
        AND opt.StatusChangeDate >= '2026-02-10'
        AND opt.StatusChangeDate >= b.CreatedDate_MS_Outbound
        AND opt.StatusChangeDate <= b.CreatedDate_MS_Outbound + INTERVAL 3 DAY
),

calendly_matched AS (
    -- 6. Check if the customer scheduled a Calendly meeting after the outbound message
    SELECT 
        b.Id_mt,
        cal.Id AS Calendly_Event_Id,
        cal.EventCreatedAt__c AS Calendly_Booked_At,
        ROW_NUMBER() OVER(PARTITION BY b.Id_mt ORDER BY cal.EventCreatedAt__c ASC) as rnk_cal
    FROM base_inbound b
    -- NEW: Grab the real customer email using their GCID
    JOIN main.pii_data.bronze_etoro_customer_customer cust
        ON CAST(b.GCID__c_mt AS STRING) = CAST(cust.GCID AS STRING)
    JOIN main.crm.silver_crm_calendlyaction__c cal
        -- NEW: Match the Calendly invite to the true customer email
        ON cal.InviteeEmail__c = cust.Email
        AND cal.EventCreatedAt__c >= '2026-02-10'
        AND cal.EventCreatedAt__c >= b.CreatedDate_MS_Outbound
        AND cal.EventCreatedAt__c <= b.CreatedDate_MS_Outbound + INTERVAL 14 DAY
),

task_matched AS (
    -- 7. Check if a 'Missed Whatsapp' task was logged specifically for this inbound chat
    SELECT 
        b.Id_mt,
        tk.Id AS Offline_Task_Id,
        tk.Status AS Task_Status,                 
        tk.CreatedDate AS Task_CreatedDate,       
        tk.CompletedDateTime,                     
        ROW_NUMBER() OVER(PARTITION BY b.Id_mt ORDER BY tk.CreatedDate ASC) as rnk_task
    FROM base_inbound b
    JOIN main.crm.silver_crm_task tk
        ON b.Account__c_mt = tk.AccountId
        AND tk.Type = 'Missed Whatsapp'
        AND tk.CreatedDate >= '2026-02-10'
        -- CRUCIAL FIX: Ensure we only look for tasks if an inbound session exists
        AND b.Id_MS_Inbound IS NOT NULL
        -- EXACT MATCH: Task Description must contain the exact Session ID
        AND tk.Description LIKE CONCAT('%', b.Id_MS_Inbound, '%') 
)

-- 8. Final Select: Merge everything into clean, dashboard-ready columns
SELECT 
    b.*,
    opt.Unsubscribe_Date,
    cal.Calendly_Event_Id,
    cal.Calendly_Booked_At,
    tk.Offline_Task_Id,
    tk.Task_Status,
    tk.CompletedDateTime,
    
    -- === ADDED: Theoretical Initiated Flag (Mirrors Centralized Dashboard) ===
    CASE 
        WHEN b.TriggerTier_mt = 'High' THEN TRUE
        WHEN b.TriggerTier_mt = 'Low' AND (LOWER(b.whatsapp_status__c_mt) = 'sent' OR b.status__c_mt IN ('2', '3', '5')) THEN TRUE
        ELSE FALSE
    END AS IsInitiated,

    -- === NEW: ADDING THE ACCOUNT MANAGER NAMES ===
    CONCAT(u_assigned.FirstName, ' ', u_assigned.LastName) AS Assigned_AM_Name,
    CONCAT(u_handled.FirstName, ' ', u_handled.LastName) AS Handling_AM_Name,
    
    -- Dashboard KPI Boolean Flags
    CASE WHEN b.Id_MS_Inbound IS NOT NULL THEN TRUE ELSE FALSE END AS Customer_Responded_Within_3_Days,
    CASE WHEN opt.Unsubscribe_Date IS NOT NULL THEN TRUE ELSE FALSE END AS Customer_Unsubscribed_Within_3_Days,
    CASE WHEN cal.Calendly_Event_Id IS NOT NULL THEN TRUE ELSE FALSE END AS Customer_Scheduled_Meeting,
    
    -- FIXED: Must have both an inbound session AND a matched task
    CASE 
        WHEN b.Id_MS_Inbound IS NOT NULL AND tk.Offline_Task_Id IS NOT NULL 
        THEN TRUE 
        ELSE FALSE 
    END AS Customer_Left_Offline_Message,
    
    -- NEW: Did the customer ask to be routed to an alternative Account Manager? (INTENT)
    CASE 
        WHEN b.Id_MS_Inbound IS NOT NULL 
         AND b.Route_to_another_AM__c_MS = TRUE 
        THEN TRUE 
        ELSE FALSE 
    END AS Routed_To_Another_AM,

    -- NEW: Was the session actually handled by a DIFFERENT human Account Manager? (FULFILLMENT)
    CASE 
        WHEN b.Id_MS_Inbound IS NOT NULL 
         AND b.AgentType_MS <> 'Bot' 
         AND b.OwnerId_MS <> b.Last_Account_Manager__c_mt 
        THEN TRUE 
        ELSE FALSE 
    END AS Actually_Handled_By_Alternative_AM,

    -- Did the AM complete the offline task?
    CASE WHEN tk.Offline_Task_Id IS NOT NULL AND tk.Task_Status = 'Completed' THEN TRUE ELSE FALSE END AS AM_Responded_To_Message,
    
    -- Time to get back to the customer (in minutes)
    CASE 
        WHEN tk.Offline_Task_Id IS NOT NULL AND tk.Task_Status = 'Completed' 
        THEN TIMESTAMPDIFF(MINUTE, tk.Task_CreatedDate, tk.CompletedDateTime) 
        ELSE NULL 
    END AS Time_To_Respond_Minutes

FROM base_inbound b
LEFT JOIN optin_matched opt ON b.Id_mt = opt.Id_mt AND opt.rnk_opt = 1
LEFT JOIN calendly_matched cal ON b.Id_mt = cal.Id_mt AND cal.rnk_cal = 1
LEFT JOIN task_matched tk ON b.Id_mt = tk.Id_mt AND tk.rnk_task = 1

-- === NEW: JOINS TO THE USER TABLE ===
-- Join 1: Get the name of the originally assigned Account Manager
LEFT JOIN main.crm.silver_crm_user u_assigned 
    ON b.Last_Account_Manager__c_mt = u_assigned.Id

-- Join 2: Get the name of the Account Manager who actually owned the session
LEFT JOIN main.crm.silver_crm_user u_handled 
    ON b.OwnerId_MS = u_handled.Id
-- Filter for just whatsapp triggers
WHERE LOWER(whatsapp_status__c_mt) = 'sent'