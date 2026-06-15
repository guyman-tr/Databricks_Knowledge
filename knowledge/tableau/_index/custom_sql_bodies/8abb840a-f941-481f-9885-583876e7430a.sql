WITH combined_triggers AS (
    -- 1. Gather triggers
    SELECT
        t.Id,
        t.Trigger_Created_Date__c,
        t.Account__c,
        t.Last_Account_Manager__c,
        t.Name AS TriggerName,
        CASE 
            WHEN t.Status__c = '5' THEN 'Solved' 
            ELSE 'Unsolved' 
        END AS TriggerStatus,
        'Low' AS TriggerTier,
        t.whatsapp_status__c, -- [NEW] The WhatsApp Gatekeeper Field
        t.Status__c -- [NEW] Passed down for the Initiated logic
    FROM
        main.crm.silver_crm_low_tier_trigger__c t
    WHERE
        t.Name = 'Big revenue drop'
        AND t.Trigger_Created_Date__c >= CURRENT_DATE - INTERVAL 12 MONTH -- *** ADDED: 12-Month Rolling Filter ***

    UNION ALL

    SELECT
        t.Id,
        t.Trigger_Created_Date__c,
        t.Account__c,
        t.Last_Account_Manager__c,
        t.Name AS TriggerName,
        CASE 
            WHEN t.Status__c = '5' THEN 'Solved' 
            ELSE 'Unsolved' 
        END AS TriggerStatus,
        'High' AS TriggerTier,
        
        -- [UPDATED] Dynamically flag High Tier triggers as WhatsApp based on Status and Substatus
        CASE 
            WHEN t.Status__c = '5' AND t.Substatus__c = 'Exceeded Daily Priority Limit' THEN 'Sent'
            ELSE NULL 
        END AS whatsapp_status__c,
        
        t.Status__c -- [NEW] Passed down for the Initiated logic
    FROM
        main.crm.silver_crm_call_to_action__c t
    WHERE
        t.Name = 'Big revenue drop'
        AND t.Trigger_Created_Date__c >= CURRENT_DATE - INTERVAL 12 MONTH -- *** ADDED: 12-Month Rolling Filter ***
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

triggers_enriched AS (
    -- 2. Prepare Trigger Data (Unchanged - Keeps the 30-day maturity filter)
    SELECT
        ct.Id AS TriggerId,
        ct.Trigger_Created_Date__c,
        ct.TriggerName,
        ct.TriggerStatus,
        ct.TriggerTier,
        ct.whatsapp_status__c, -- [NEW] Pass through for Initiated logic
        ct.Status__c, -- [NEW] Pass through for Initiated logic
        amp.Customer_Unique_ID_CID__c AS CID,
        amp.GCID__c, 
        CONCAT(u.FirstName, ' ', u.lastname) AS AccountManagerName,
        CAST(TO_CHAR(ct.Trigger_Created_Date__c, 'yyyyMMdd') AS INT) AS TriggerDateInt,
        CAST(TO_CHAR(DATEADD(day, -90, ct.Trigger_Created_Date__c), 'yyyyMMdd') AS INT) AS StartDatePriorInt,
        CAST(TO_CHAR(DATEADD(day, 30, ct.Trigger_Created_Date__c), 'yyyyMMdd') AS INT) AS EndDatePostInt
    FROM
        combined_triggers ct
    JOIN
        main.crm.silver_crm_accountidmappingtable amp ON ct.Account__c = amp.id
    LEFT JOIN
        main.crm.silver_crm_user u ON ct.Last_Account_Manager__c = u.id
    WHERE
        ct.Trigger_Created_Date__c <= DATEADD(day, -30, CURRENT_DATE)
),

-- 3. Pre-filter and Column Prune the Daily Panel (Unchanged)
daily_panel_slim AS (
    SELECT 
        CID, 
        DateID, 
        Revenue_Total
    FROM 
        main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata
    WHERE 
        DateID >= 20240401 
),

revenue_stats AS (
    -- 4. Calculate Stats using the Slim Panel (Unchanged)
    SELECT
        t.TriggerId,
        -- Prior Average (90 days)
        SUM(CASE 
            WHEN dp.DateID >= t.StartDatePriorInt AND dp.DateID < t.TriggerDateInt 
            Then dp.Revenue_Total 
            ELSE 0 
        END) / 3.0 AS Avg_Monthly_Revenue_3Months_Prior,
        
        -- Post Revenue (30 days)
        SUM(CASE 
            WHEN dp.DateID >= t.TriggerDateInt AND dp.DateID <= t.EndDatePostInt 
            THEN dp.Revenue_Total 
            ELSE 0 
        END) AS Revenue_30Days_Post
        
    FROM
        triggers_enriched t
    JOIN
        daily_panel_slim dp 
        ON t.CID = dp.CID
        AND dp.DateID >= t.StartDatePriorInt 
        AND dp.DateID <= t.EndDatePostInt
    GROUP BY
        t.TriggerId
)

-- 5. Final Output
SELECT
    t.TriggerId,
    t.TriggerTier,
    t.Trigger_Created_Date__c,
    t.CID,
    t.AccountManagerName,
    t.TriggerStatus,
    t.Status__c,             -- *** ADDED: Explicitly expose raw Status string for Tableau ***
    t.whatsapp_status__c,    -- *** ADDED: Explicitly expose WhatsApp gatekeeper string for Tableau ***
    pl.Name AS PlayerLevelName,
    CASE
        WHEN dc.MifidCategorizationID IN (2, 3) THEN 1
        ELSE 0
    END AS IsProfessionalCustomer,

    COALESCE(rs.Avg_Monthly_Revenue_3Months_Prior, 0) AS Avg_Monthly_Revenue_Prior,
    COALESCE(rs.Revenue_30Days_Post, 0) AS Revenue_Post_Trigger,
    CASE 
        WHEN COALESCE(rs.Revenue_30Days_Post, 0) >= COALESCE(rs.Avg_Monthly_Revenue_3Months_Prior, 0) 
        THEN 1 
        ELSE 0 
    END AS IsRevenueRecovered,
    
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
    triggers_enriched t
LEFT JOIN
    revenue_stats rs ON t.TriggerId = rs.TriggerId
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