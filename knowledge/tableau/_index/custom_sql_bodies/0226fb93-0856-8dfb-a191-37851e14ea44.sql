WITH combined_triggers AS (
    -- 1. Gather Low Tier Triggers
    SELECT 
        Id, Name, CreatedDate, CreatedById, SystemModstamp, Account__c, Status__c, Substatus__c, 
        Close_Date__c, Last_Account_Manager__c, Source__c, Trigger_BI_Id__c, Trigger_Created_Date__c, 
        Trigger_Definition__c, etr_ymd, 
        'Low' AS TriggerTier,
        whatsapp_status__c -- The WhatsApp Gatekeeper Field
    FROM 
        main.crm.silver_crm_low_tier_trigger__c
    WHERE Trigger_Created_Date__c >= CURRENT_DATE - INTERVAL 12 MONTH

    UNION ALL

    -- 2. Gather High Tier Triggers (Call to Action)
    SELECT 
        Id, Name, CreatedDate, CreatedById, SystemModstamp, Account__c, Status__c, Substatus__c, 
        Close_Date__c, Last_Account_Manager__c, Source__c, Trigger_BI_Id__c, Trigger_Created_Date__c, 
        Trigger_Definition__c, etr_ymd, 
        'High' AS TriggerTier,
        
        -- Dynamically flag High Tier triggers as WhatsApp based on Status and Substatus
        CASE 
            WHEN Status__c = '5' AND Substatus__c = 'Exceeded Daily Priority Limit' THEN 'Sent'
            ELSE NULL 
        END AS whatsapp_status__c 
        
    FROM 
        main.crm.silver_crm_call_to_action__c
    WHERE Trigger_Created_Date__c >= CURRENT_DATE - INTERVAL 12 MONTH
),

-- 3. Find all possible matches between Triggers and Outbound Sessions within 14 days
matched_pairs AS (
    SELECT 
        c.Id AS Trigger_Id,
        c.Account__c, 
        c.Trigger_Created_Date__c,
        ms.Id AS WhatsApp_Session_Id,
        ms.CreatedDate AS WhatsApp_Session_Date,
        
        -- Rank 1: Lock the SESSION to the MOST RECENT TRIGGER before it was sent
        ROW_NUMBER() OVER(
            PARTITION BY ms.Id 
            ORDER BY c.Trigger_Created_Date__c DESC
        ) as session_rank
    FROM combined_triggers c
    JOIN main.crm.silver_crm_messagingsession ms
        ON c.Account__c = ms.EndUserAccountId 
        AND ms.ChannelType = 'WhatsApp'
        AND ms.Origin = 'TriggeredOutbound'
        AND ms.CreatedDate >= c.Trigger_Created_Date__c
        AND ms.CreatedDate <= c.Trigger_Created_Date__c + INTERVAL 14 DAY
        
    -- [FIXED GATEKEEPER LOGIC] 
    -- Now allows High Tier triggers IF their synthetic status was set to 'Sent' above
    WHERE lower(c.whatsapp_status__c) = 'sent'
),

-- 4. Filter so each session is only claimed by ONE trigger
unique_sessions AS (
    SELECT * FROM matched_pairs WHERE session_rank = 1
),

-- 5. If a trigger has multiple unique sessions, keep only the FIRST session
whatsapp_outbound AS (
    SELECT 
        Trigger_Id,
        Account__c, 
        WhatsApp_Session_Id,
        WhatsApp_Session_Date,
        
        -- Rank 2: Lock the TRIGGER to the FIRST SESSION sent after it
        ROW_NUMBER() OVER(
            PARTITION BY Trigger_Id 
            ORDER BY WhatsApp_Session_Date ASC
        ) as trigger_rank
    FROM unique_sessions
),

-- 5A. Find the FIRST Inbound reply within 3 days of the Outbound message
inbound_matched AS (
    SELECT 
        o.Trigger_Id,
        ms_in.Id AS WhatsApp_Inbound_Session_Id,
        ROW_NUMBER() OVER(PARTITION BY o.Trigger_Id ORDER BY ms_in.CreatedDate ASC) as rn_in
    FROM whatsapp_outbound o
    JOIN main.crm.silver_crm_messagingsession ms_in
        ON o.Account__c = ms_in.EndUserAccountId 
        AND ms_in.ChannelType = 'WhatsApp'
        AND ms_in.Origin <> 'TriggeredOutbound'
        AND ms_in.CreatedDate >= o.WhatsApp_Session_Date
        AND ms_in.CreatedDate <= o.WhatsApp_Session_Date + INTERVAL 3 DAY
    WHERE o.trigger_rank = 1
),

-- 5B. Keep only the first inbound reply
whatsapp_inbound AS (
    SELECT * FROM inbound_matched WHERE rn_in = 1
)

-- 6. Main Select: Bring it all together
SELECT 
    c.*,

    -- [Standardized Name Logic]
    CASE  
        WHEN c.Trigger_Definition__c = 'a480800000GWrRQAA1' 
        THEN 'Cash out of 25k and above'
        ELSE c.Name 
    END AS Trigger_Standardized_Name,

    -- [NEW] Initiated Flag Logic (Now returning Boolean)
    CASE 
        WHEN c.TriggerTier = 'High' THEN TRUE
        WHEN c.TriggerTier = 'Low' AND (LOWER(c.whatsapp_status__c) = 'sent' OR c.Status__c IN ('2', '3', '5')) THEN TRUE
        ELSE FALSE
    END AS Initiated,

    -- Pass the raw WhatsApp session data to Tableau
    wa.WhatsApp_Session_Id AS WhatsApp_Outbound_Session_Id,
    wa.WhatsApp_Session_Date,
    
    -- Pass the inbound reply ID to Tableau for the "True Engagement" calculation
    wa_in.WhatsApp_Inbound_Session_Id,

    -- [Account Manager Hierarchy]
    amp.GCID__c AS GCID,
    amp.Customer_Unique_ID_CID__c AS CID,
    CONCAT(u.FirstName, ' ', u.lastname) AS am_name, 
    u.Department AS am_department, 
    u.Email AS am_email, 
    u.ManagerId AS am_managerid,
    u.Desk__c,
    m_m1.email AS m1_email, 
    CONCAT(m_m1.firstname, ' ', m_m1.lastname) AS m1_fullname,
    m_m2.email AS m2_email, 
    CONCAT(m_m2.firstname, ' ', m_m2.lastname) AS m2_fullname,
    m_m3.email AS m3_email, 
    CONCAT(m_m3.firstname, ' ', m_m3.lastname) AS m3_fullname,
    m_m4.email AS m4_email, 
    CONCAT(m_m4.firstname, ' ', m_m4.lastname) AS m4_fullname,
    m_m5.email AS m5_email, 
    CONCAT(m_m5.firstname, ' ', m_m5.lastname) AS m5_fullname

FROM combined_triggers c

-- Join to Account Map
JOIN main.crm.silver_crm_accountidmappingtable amp 
    ON c.Account__c = amp.id

-- Join to the strictly attributed WhatsApp check (Outbound)
LEFT JOIN whatsapp_outbound wa 
    ON c.Id = wa.Trigger_Id
    AND wa.trigger_rank = 1

-- Join to the strictly attributed WhatsApp check (Inbound)
LEFT JOIN whatsapp_inbound wa_in
    ON c.Id = wa_in.Trigger_Id

-- Join to AM Hierarchy
LEFT JOIN main.crm.silver_crm_user u 
    ON c.Last_Account_Manager__c = u.id
LEFT JOIN main.crm.silver_crm_user m_m1 ON m_m1.id = u.managerid
LEFT JOIN main.crm.silver_crm_user m_m2 ON m_m2.id = m_m1.managerid
LEFT JOIN main.crm.silver_crm_user m_m3 ON m_m3.id = m_m2.managerid
LEFT JOIN main.crm.silver_crm_user m_m4 ON m_m4.id = m_m3.managerid
LEFT JOIN main.crm.silver_crm_user m_m5 ON m_m5.id = m_m4.managerid