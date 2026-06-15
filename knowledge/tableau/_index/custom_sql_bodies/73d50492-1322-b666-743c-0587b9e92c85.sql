WITH target_definitions AS (
    -- 1. Grab only the relevant trigger definitions using their persistent numeric ID
    SELECT 
        Id AS DefinitionId,
        Trigger_ID__c
    FROM 
        main.crm.silver_crm_engagement_trigger_definition__c
    WHERE 
        -- Mapping all variations of High Available Balance, Big Positions Close, and Big Deposit
        Trigger_ID__c IN (
            3,  -- High available balance
            36, -- High Available Balance (opted in to IoB)
            37, -- High Available Balance (not eligible for IoB)
            4,  -- Big positions close
            21, -- Big deposit (no IoB)
            34, -- Big Deposit (opted into IoB)
            35  -- Big Deposit (not eligible for IoB)
        ) 
),

triggers AS (
    -- Low Tier Triggers 
    SELECT
        t.Id,
        t.Account__c, 
        t.Trigger_Created_Date__c,
        t.name AS TriggerName,
        'Low' AS TriggerTier,
        amp.GCID__c,
        amp.Customer_Unique_ID_CID__c AS CID,
        CASE 
            WHEN t.Status__c = '5' THEN 'Solved' 
            ELSE 'Unsolved' 
        END AS TriggerStatus,
        CONCAT(u.FirstName, ' ', u.lastname) AS AccountManagerName,
        t.whatsapp_status__c,
        t.Status__c,
        
        -- Expose the persistent numeric ID to Tableau for super easy filtering!
        def.Trigger_ID__c 
        
    FROM
        main.crm.silver_crm_low_tier_trigger__c t
    -- [NEW] Inner Join to the definitions table ensures only triggers matching our target IDs survive
    JOIN 
        target_definitions def ON t.Trigger_Definition__c = def.DefinitionId
    JOIN
        main.crm.silver_crm_accountidmappingtable amp ON t.Account__c = amp.id
    LEFT JOIN 
        main.crm.silver_crm_user u ON t.Last_Account_Manager__c = u.id
    WHERE
        t.Trigger_Created_Date__c >= CURRENT_DATE - INTERVAL 12 MONTH 

    UNION ALL

    -- High Tier Triggers
    SELECT
        t.Id,
        t.Account__c, 
        t.Trigger_Created_Date__c,
        t.name AS TriggerName,
        'High' AS TriggerTier,
        amp.GCID__c,
        amp.Customer_Unique_ID_CID__c AS CID,
        CASE 
            WHEN t.Status__c = '5' THEN 'Solved' 
            ELSE 'Unsolved' 
        END AS TriggerStatus,
        CONCAT(u.FirstName, ' ', u.lastname) AS AccountManagerName,
        
        CASE 
            WHEN t.Status__c = '5' AND t.Substatus__c = 'Exceeded Daily Priority Limit' THEN 'Sent'
            ELSE NULL 
        END AS whatsapp_status__c,
        
        t.Status__c,
        
        -- Expose the persistent numeric ID to Tableau for super easy filtering!
        def.Trigger_ID__c 
        
    FROM
        main.crm.silver_crm_call_to_action__c t
    -- [NEW] Inner Join to the definitions table
    JOIN 
        target_definitions def ON t.Trigger_Definition__c = def.DefinitionId
    JOIN
        main.crm.silver_crm_accountidmappingtable amp ON t.Account__c = amp.id
    LEFT JOIN 
        main.crm.silver_crm_user u ON t.Last_Account_Manager__c = u.id
    WHERE
        t.Trigger_Created_Date__c >= CURRENT_DATE - INTERVAL 12 MONTH 
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
        ROW_NUMBER() OVER(
            PARTITION BY ms.Id 
            ORDER BY c.Trigger_Created_Date__c DESC
        ) as session_rank
    FROM triggers c
    JOIN main.crm.silver_crm_messagingsession ms
        ON c.Account__c = ms.EndUserAccountId 
        AND ms.ChannelType = 'WhatsApp'
        AND ms.Origin = 'TriggeredOutbound'
        AND ms.CreatedDate >= c.Trigger_Created_Date__c
        AND ms.CreatedDate <= c.Trigger_Created_Date__c + INTERVAL 14 DAY
    WHERE lower(c.whatsapp_status__c) ='sent'
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

interest_optins AS (
    SELECT CID, ValidFrom AS OptInDate FROM bi_db.bronze_interest_trade_interestconsent WHERE ConsentStatusID = 1
    UNION 
    SELECT CID, ValidFrom AS OptInDate FROM bi_db.bronze_interest_history_interestconsent WHERE ConsentStatusID = 1
),

new_positions AS (
    SELECT CID, OpenOccurred AS PositionOpenDate, Amount FROM main.dwh.dim_position
)

-- Final Select
SELECT
    t.Id AS TriggerId,
    t.Account__c,
    t.Trigger_Created_Date__c,
    t.TriggerName,
    t.TriggerTier,
    t.Trigger_ID__c, -- Successfully mapped ID
    t.GCID__c,
    t.CID,
    t.AccountManagerName, 
    t.TriggerStatus,
    t.Status__c,
    t.whatsapp_status__c,

    CASE 
        WHEN t.TriggerTier = 'High' THEN TRUE
        WHEN t.TriggerTier = 'Low' AND (LOWER(t.whatsapp_status__c) = 'sent' OR t.Status__c IN ('2', '3', '5')) THEN TRUE
        ELSE FALSE
    END AS Initiated,

    wa.WhatsApp_Session_Id AS WhatsApp_Outbound_Session_Id,
    wa.WhatsApp_Session_Date,
    wa_in.WhatsApp_Inbound_Session_Id,

    CASE WHEN dc.MifidCategorizationID IN (2, 3) THEN 1 ELSE 0 END AS IsProfessionalCustomer,
    pl.Name AS PlayerLevelName,
    
    CASE
        WHEN EXISTS (
            SELECT 1 FROM interest_optins io WHERE io.CID = t.CID AND io.OptInDate > t.Trigger_Created_Date__c AND io.OptInDate <= DATEADD(day, 14, t.Trigger_Created_Date__c)
        ) OR EXISTS (
            SELECT 1 FROM new_positions np WHERE np.CID = t.CID AND np.PositionOpenDate > t.Trigger_Created_Date__c AND np.PositionOpenDate <= DATEADD(day, 14, t.Trigger_Created_Date__c)
        ) THEN 1 ELSE 0
    END AS IsSuccessful,
    
    CASE
        WHEN EXISTS (
            SELECT 1 FROM interest_optins io WHERE io.CID = t.CID AND io.OptInDate > t.Trigger_Created_Date__c AND io.OptInDate <= DATEADD(day, 14, t.Trigger_Created_Date__c)
        ) THEN 1 ELSE 0 
    END AS OptInInterest,
    
    CASE
        WHEN EXISTS (
            SELECT 1 FROM new_positions np WHERE np.CID = t.CID AND np.PositionOpenDate > t.Trigger_Created_Date__c AND np.PositionOpenDate <= DATEADD(day, 14, t.Trigger_Created_Date__c)
        ) THEN 1 ELSE 0
    END AS OpenedPosition,

    COALESCE((
        SELECT SUM(np.Amount)
        FROM new_positions np
        WHERE np.CID = t.CID AND np.PositionOpenDate > t.Trigger_Created_Date__c AND np.PositionOpenDate <= DATEADD(day, 14, t.Trigger_Created_Date__c)
    ), 0) AS TotalAmountInvested14Days,

    (
        SELECT COUNT(1)
        FROM main.dwh.dim_position p
        WHERE p.CID = t.CID AND p.OpenOccurred >= DATEADD(month, -1, t.Trigger_Created_Date__c) AND p.OpenOccurred < t.Trigger_Created_Date__c
    ) AS PositionsOpenedPriorMonth,
    
    CASE
        WHEN PositionsOpenedPriorMonth = 0 THEN '0'
        WHEN PositionsOpenedPriorMonth BETWEEN 1 AND 2 THEN '1-2'
        WHEN PositionsOpenedPriorMonth >= 3 THEN '3+'
        ELSE 'Dormant' 
    END AS PriorActivitySegment
    
FROM triggers t
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON t.GCID__c = dc.GCID
LEFT JOIN main.general.bronze_etoro_dictionary_playerlevel pl ON dc.PlayerLevelID = pl.PlayerLevelID
LEFT JOIN whatsapp_outbound wa ON t.Id = wa.Trigger_Id AND wa.trigger_rank = 1
LEFT JOIN whatsapp_inbound wa_in ON t.Id = wa_in.Trigger_Id