WITH base_triggers AS (
    -- 1. Gather all 'New deposit' Triggers (Rolling 12 Months)
    SELECT
        t.Id AS TriggerId,
        t.Account__c,
        t.Trigger_Created_Date__c,
        t.name AS TriggerName,
        'Low' AS TriggerTier,
        amp.GCID__c,
        amp.Customer_Unique_ID_CID__c AS CID,
        t.Last_Account_Manager__c,
        CASE WHEN t.Status__c = '5' THEN 'Solved' ELSE 'Unsolved' END AS TriggerStatus,
        t.whatsapp_status__c, -- [NEW] The WhatsApp Gatekeeper Field
        t.Status__c -- [NEW] Passed down for the Initiated logic
    FROM main.crm.silver_crm_low_tier_trigger__c t
    JOIN main.crm.silver_crm_accountidmappingtable amp ON t.Account__c = amp.id
    WHERE t.name = 'New deposit'
      AND t.Trigger_Created_Date__c >= CURRENT_DATE - INTERVAL 12 MONTH

    UNION ALL

    SELECT
        t.Id AS TriggerId,
        t.Account__c,
        t.Trigger_Created_Date__c,
        t.name AS TriggerName,
        'High' AS TriggerTier,
        amp.GCID__c,
        amp.Customer_Unique_ID_CID__c AS CID,
        t.Last_Account_Manager__c,
        CASE WHEN t.Status__c = '5' THEN 'Solved' ELSE 'Unsolved' END AS TriggerStatus,
        
        -- [UPDATED] Dynamically flag High Tier triggers as WhatsApp based on Status and Substatus
        CASE 
            WHEN t.Status__c = '5' AND t.Substatus__c = 'Exceeded Daily Priority Limit' THEN 'Sent'
            ELSE NULL 
        END AS whatsapp_status__c,
        
        t.Status__c -- [NEW] Passed down for the Initiated logic
    FROM main.crm.silver_crm_call_to_action__c t
    JOIN main.crm.silver_crm_accountidmappingtable amp ON t.Account__c = amp.id
    WHERE t.name = 'New deposit'
      AND t.Trigger_Created_Date__c >= CURRENT_DATE - INTERVAL 12 MONTH
),

/* ------------------------------------------------------------------
   START WHATSAPP ATTRIBUTION LOGIC
   ------------------------------------------------------------------ */
matched_pairs AS (
    SELECT 
        c.TriggerId AS Trigger_Id,
        c.Account__c,
        c.Trigger_Created_Date__c,
        ms.Id AS WhatsApp_Session_Id,
        ms.CreatedDate AS WhatsApp_Session_Date,
        ROW_NUMBER() OVER(PARTITION BY ms.Id ORDER BY c.Trigger_Created_Date__c DESC) as session_rank
    FROM base_triggers c
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

unique_sessions AS (
    SELECT * FROM matched_pairs WHERE session_rank = 1
),

whatsapp_outbound AS (
    SELECT 
        Trigger_Id,
        Account__c,
        WhatsApp_Session_Id,
        WhatsApp_Session_Date,
        ROW_NUMBER() OVER(PARTITION BY Trigger_Id ORDER BY WhatsApp_Session_Date ASC) as trigger_rank
    FROM unique_sessions
),

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

whatsapp_inbound AS (
    SELECT * FROM inbound_matched WHERE rn_in = 1
),
/* ------------------------------------------------------------------
   END WHATSAPP ATTRIBUTION LOGIC
   ------------------------------------------------------------------ */

-- 2. Fetch Raw Positions for Success Checking
new_positions AS (
    SELECT
        CID,
        OpenOccurred AS PositionOpenDate,
        Amount 
    FROM main.dwh.dim_position
)

-- 3. Final Select: Bring together Triggers, Dimensions, WhatsApp, and Success Rules
SELECT
    t.TriggerId,
    t.Account__c,
    t.Trigger_Created_Date__c,
    t.TriggerName,
    t.TriggerTier,
    t.GCID__c AS GCID,
    t.CID,
    CONCAT(u.FirstName, ' ', u.lastname) AS AccountManagerName, 
    t.TriggerStatus,

    -- *** ADDED: Explicitly expose raw Status and whatsapp_status strings for Tableau ***
    t.Status__c,
    t.whatsapp_status__c,

    -- [Dimensions] Club Level & Pro Customer Flag
    pl.Name AS PlayerLevelName,
    CASE 
        WHEN dc.MifidCategorizationID IN (2, 3) THEN 1 
        ELSE 0 
    END AS IsProfessionalCustomer,
    
    -- [NEW] Initiated Flag Logic
    CASE 
        WHEN t.TriggerTier = 'High' THEN TRUE
        WHEN t.TriggerTier = 'Low' AND (LOWER(t.whatsapp_status__c) = 'sent' OR t.Status__c IN ('2', '3', '5')) THEN TRUE
        ELSE FALSE
    END AS Initiated,

    -- [WhatsApp] Engagement Session IDs
    wa.WhatsApp_Session_Id AS WhatsApp_Outbound_Session_Id,
    wa.WhatsApp_Session_Date,
    wa_in.WhatsApp_Inbound_Session_Id,

    -- [Success Metric] Did they open a position within 14 days?
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM new_positions np
            WHERE np.CID = t.CID
              AND np.PositionOpenDate > t.Trigger_Created_Date__c
              AND np.PositionOpenDate <= DATEADD(day, 14, t.Trigger_Created_Date__c)
              AND np.Amount > 0
        ) THEN 1 
        ELSE 0 
    END AS IsSuccessful,

    -- [Contextual Data] How many positions were opened?
    COALESCE((
        SELECT COUNT(1)
        FROM new_positions np
        WHERE np.CID = t.CID
          AND np.PositionOpenDate > t.Trigger_Created_Date__c
          AND np.PositionOpenDate <= DATEADD(day, 14, t.Trigger_Created_Date__c)
    ), 0) AS Count_New_Positions_14Days,

    -- [Contextual Data] What was the total amount invested in those new positions?
    COALESCE((
        SELECT SUM(np.Amount)
        FROM new_positions np
        WHERE np.CID = t.CID
          AND np.PositionOpenDate > t.Trigger_Created_Date__c
          AND np.PositionOpenDate <= DATEADD(day, 14, t.Trigger_Created_Date__c)
    ), 0) AS TotalAmountInvested_14Days

FROM base_triggers t

-- Join to AM User details
LEFT JOIN main.crm.silver_crm_user u 
    ON t.Last_Account_Manager__c = u.id

-- Join to Dimensional Customer details
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
    ON t.GCID__c = dc.GCID
LEFT JOIN main.general.bronze_etoro_dictionary_playerlevel pl 
    ON dc.PlayerLevelID = pl.PlayerLevelID

-- Join to the strictly attributed WhatsApp checks
LEFT JOIN whatsapp_outbound wa 
    ON t.TriggerId = wa.Trigger_Id AND wa.trigger_rank = 1
LEFT JOIN whatsapp_inbound wa_in 
    ON t.TriggerId = wa_in.Trigger_Id