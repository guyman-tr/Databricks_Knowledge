WITH combined_triggers_filtered AS (
    -- 1. Gather Triggers: Added Account__c and 12-Month Rolling Filter
    SELECT
        t.Id,
        t.Account__c, -- *** ADDED for WhatsApp Join ***
        t.Trigger_Created_Date__c,
        'Low' AS TriggerTier,
        amp.GCID__c,
        t.Last_Account_Manager__c,
        CASE 
            WHEN t.Status__c = '5' THEN 'Solved' 
            ELSE 'Unsolved' 
        END AS TriggerStatus,
        t.whatsapp_status__c, -- The WhatsApp Gatekeeper Field
        t.Status__c -- [NEW] Passed down for the Initiated logic
    FROM
        main.crm.silver_crm_low_tier_trigger__c t
    JOIN
        main.crm.silver_crm_accountidmappingtable amp ON t.Account__c = amp.id
    WHERE
        t.name = 'Monthly active log-in'
        AND t.Trigger_Created_Date__c >= CURRENT_DATE - INTERVAL 12 MONTH -- *** ADDED Rolling 12 Months ***

    UNION ALL

    SELECT
        t.Id,
        t.Account__c, -- *** ADDED for WhatsApp Join ***
        t.Trigger_Created_Date__c,
        'High' AS TriggerTier,
        amp.GCID__c,
        t.Last_Account_Manager__c,
        CASE 
            WHEN t.Status__c = '5' THEN 'Solved' 
            ELSE 'Unsolved' 
        END AS TriggerStatus,
        
        -- [UPDATED] Dynamically flag High Tier triggers as WhatsApp based on Status and Substatus
        CASE 
            WHEN t.Status__c = '5' AND t.Substatus__c = 'Exceeded Daily Priority Limit' THEN 'Sent'
            ELSE NULL 
        END AS whatsapp_status__c,
        
        t.Status__c -- [NEW] Passed down for the Initiated logic
    FROM
        main.crm.silver_crm_call_to_action__c t
    JOIN
        main.crm.silver_crm_accountidmappingtable amp ON t.Account__c = amp.id
    WHERE
        t.name = 'Monthly active log-in'
        AND t.Trigger_Created_Date__c >= CURRENT_DATE - INTERVAL 12 MONTH -- *** ADDED Rolling 12 Months ***
),

/* ------------------------------------------------------------------
   START WHATSAPP ATTRIBUTION LOGIC
   ------------------------------------------------------------------ */
matched_pairs AS (
    SELECT 
        c.Id AS Trigger_Id,
        c.Account__c,
        c.Trigger_Created_Date__c,
        ms.Id AS WhatsApp_Session_Id,
        ms.CreatedDate AS WhatsApp_Session_Date,
        ROW_NUMBER() OVER(PARTITION BY ms.Id ORDER BY c.Trigger_Created_Date__c DESC) as session_rank
    FROM combined_triggers_filtered c
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

min_trigger_date AS (
    -- 2. Optimization: Find earliest date
    SELECT MIN(Trigger_Created_Date__c) AS min_date
    FROM combined_triggers_filtered
),

customer_logins_filtered AS (
    -- 3. Optimization: Filter Logins
    SELECT DISTINCT ca.gcid, ca.Occurred
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ca
    JOIN min_trigger_date mtd ON ca.Occurred >= mtd.min_date
    WHERE ca.ActionTypeID = 14
),

triggers_enriched_logic AS (
    -- 4. Calculate Login Success (WITH DEDUPLICATION FIX)
    SELECT
        c.Id AS TriggerId,
        c.TriggerTier,
        c.TriggerStatus,
        c.Trigger_Created_Date__c,
        c.GCID__c,
        CONCAT(u.FirstName, ' ', u.lastname) AS AccountManagerName,
        c.whatsapp_status__c, -- [NEW] Pass through for Initiated Logic
        c.Status__c,          -- [NEW] Pass through for Initiated Logic
        
        -- *** SAFE AGGREGATION: Prevents row explosion from multiple logins ***
        MAX(CASE WHEN l.gcid IS NOT NULL THEN 1 ELSE 0 END) AS HasLoginWithin30Days

    FROM
        combined_triggers_filtered c
    LEFT JOIN
        main.crm.silver_crm_user u ON c.Last_Account_Manager__c = u.id
    LEFT JOIN
        customer_logins_filtered l ON c.GCID__c = l.gcid
        AND l.Occurred > c.Trigger_Created_Date__c
        AND l.Occurred <= DATEADD(day, 30, c.Trigger_Created_Date__c)
    GROUP BY 
        c.Id, c.TriggerTier, c.TriggerStatus, c.Trigger_Created_Date__c, c.GCID__c, u.FirstName, u.lastname,
        c.whatsapp_status__c, c.Status__c -- [NEW] Added fields to the Group By
)

-- 5. Final Output: Join to Dimensional Tables & WhatsApp
SELECT
    t.TriggerId,
    t.TriggerTier,
    t.TriggerStatus,
    t.Trigger_Created_Date__c,
    t.GCID__c AS GCID,
    
    -- *** ADDED: Explicitly expose raw Status and whatsapp_status strings for Tableau ***
    t.Status__c,
    t.whatsapp_status__c,
    
    -- Enriched Columns
    t.AccountManagerName,
    pl.Name AS PlayerLevelName,
    CASE
        WHEN dc.MifidCategorizationID IN (2, 3) THEN 1
        ELSE 0
    END AS IsProfessionalCustomer,

    -- Success Metric
    t.HasLoginWithin30Days,
    
    -- [NEW] Initiated Flag Logic
    CASE 
        WHEN t.TriggerTier = 'High' THEN TRUE
        WHEN t.TriggerTier = 'Low' AND (LOWER(t.whatsapp_status__c) = 'sent' OR t.Status__c IN ('2', '3', '5')) THEN TRUE
        ELSE FALSE
    END AS Initiated,
    
    -- *** ADDED: Pass WhatsApp IDs for Tableau filtering ***
    wa.WhatsApp_Session_Id AS WhatsApp_Outbound_Session_Id,
    wa.WhatsApp_Session_Date,
    wa_in.WhatsApp_Inbound_Session_Id

FROM
    triggers_enriched_logic t
LEFT JOIN
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    ON t.GCID__c = dc.GCID
LEFT JOIN
    main.general.bronze_etoro_dictionary_playerlevel pl
    ON dc.PlayerLevelID = pl.PlayerLevelID

-- *** ADDED: WhatsApp Joins ***
LEFT JOIN whatsapp_outbound wa 
    ON t.TriggerId = wa.Trigger_Id
    AND wa.trigger_rank = 1
LEFT JOIN whatsapp_inbound wa_in
    ON t.TriggerId = wa_in.Trigger_Id