WITH base_triggers_with_am AS (
    -- Step 1: Get ALL triggers and join AM data.
    SELECT
        cta.Id AS TriggerId,
        cta.Account__c, 
        cta.Trigger_Created_Date__c,
        amp.Customer_Unique_ID_CID__c AS CID,
        cta.Name AS TriggerName,
        CONCAT(u.FirstName, ' ', u.lastname) AS AccountManagerName,
        CASE 
            WHEN cta.Status__c = '5' THEN 'Solved' 
            ELSE 'Unsolved' 
        END AS TriggerStatus,
        CAST(TO_CHAR(cta.Trigger_Created_Date__c, 'yyyyMMdd') AS INT) AS TriggerDateAsInt,
        
        -- [NEW] Added fields for WhatsApp Gatekeeper and Initiated logic
        'High' AS TriggerTier,
        cta.Status__c,
        CASE 
            WHEN cta.Status__c = '5' AND cta.Substatus__c = 'Exceeded Daily Priority Limit' THEN 'Sent'
            ELSE NULL 
        END AS whatsapp_status__c

    FROM
        main.crm.silver_crm_call_to_action__c cta
    JOIN
        main.crm.silver_crm_accountidmappingtable amp
        ON cta.Account__c = amp.id
    LEFT JOIN
        main.crm.silver_crm_user u 
        ON cta.Last_Account_Manager__c = u.id
    WHERE
        cta.Trigger_Definition__c = 'a480800000GWrRQAA1'
        AND cta.Trigger_Created_Date__c >= CURRENT_DATE - INTERVAL 12 MONTH
),

/* ------------------------------------------------------------------
   START WHATSAPP ATTRIBUTION LOGIC
   ------------------------------------------------------------------ */

-- WA Step 1: Find all possible outbound matches within 14 days
matched_pairs AS (
    SELECT 
        c.TriggerId AS Trigger_Id,
        c.Account__c,
        c.Trigger_Created_Date__c,
        ms.Id AS WhatsApp_Session_Id,
        ms.CreatedDate AS WhatsApp_Session_Date,
        ROW_NUMBER() OVER(
            PARTITION BY ms.Id 
            ORDER BY c.Trigger_Created_Date__c DESC
        ) as session_rank
    FROM base_triggers_with_am c
    JOIN main.crm.silver_crm_messagingsession ms
        ON c.Account__c = ms.EndUserAccountId 
        AND ms.ChannelType = 'WhatsApp'
        AND ms.Origin = 'TriggeredOutbound'
        AND ms.CreatedDate >= c.Trigger_Created_Date__c
        AND ms.CreatedDate <= c.Trigger_Created_Date__c + INTERVAL 14 DAY
        
    -- [NEW GATEKEEPER] Only let through triggers marked as 'Sent'
    WHERE lower(c.whatsapp_status__c) = 'sent'
),

-- WA Step 2: Unique sessions (Message only claimed by one trigger)
unique_sessions AS (
    SELECT * FROM matched_pairs WHERE session_rank = 1
),

-- WA Step 3: Keep only the first outbound session per trigger
whatsapp_outbound AS (
    SELECT 
        Trigger_Id,
        Account__c,
        WhatsApp_Session_Id,
        WhatsApp_Session_Date,
        ROW_NUMBER() OVER(PARTITION BY Trigger_Id ORDER BY WhatsApp_Session_Date ASC) as trigger_rank
    FROM unique_sessions
),

-- WA Step 4: Find the first inbound reply within 3 days
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

-- WA Step 5: Clean Inbound (keep only rank 1)
whatsapp_inbound AS (
    SELECT * FROM inbound_matched WHERE rn_in = 1
),

/* ------------------------------------------------------------------
   END WHATSAPP ATTRIBUTION LOGIC
   ------------------------------------------------------------------ */

all_large_withdrawals AS (
    -- Step 2: Get ALL withdrawals >= 25k
    SELECT WithdrawID, CID, RequestDate, ModificationDate, Amount, CurrencyID, CashoutStatusID
    FROM main.billing.bronze_etoro_billing_withdraw
    WHERE Amount >= 25000
),

all_withdrawals AS (
    -- Step 3: Get ALL withdrawals for linked CIDs
    SELECT w.WithdrawID, w.CID, w.RequestDate, w.ModificationDate, w.Amount, w.CurrencyID, w.CashoutStatusID
    FROM main.billing.bronze_etoro_billing_withdraw w
    WHERE w.CID IN (SELECT DISTINCT CID FROM base_triggers_with_am)
),

daily_withdrawal_sums AS (
    -- Step 4: Pre-aggregate sums
    SELECT CID, CAST(RequestDate AS DATE) AS RequestDay, SUM(Amount) AS SummedAmount
    FROM all_withdrawals
    GROUP BY 1, 2
),

linked_withdrawals_for_triggers AS (
    -- Step 5: Get fallback amount
    SELECT t.TriggerId, w.Amount,
        ROW_NUMBER() OVER(PARTITION BY t.TriggerId ORDER BY w.RequestDate DESC) AS rn
    FROM base_triggers_with_am t
    JOIN all_large_withdrawals w
        ON t.CID = w.CID
        AND w.RequestDate < t.Trigger_Created_Date__c
),

triggers_with_amount AS (
    -- Step 6: Create RequestedAmount
    SELECT t.*, 
        COALESCE(
            TRY_CAST(REPLACE(t.TriggerName, 'Cash out of', '') AS DECIMAL(18, 2)),
            TRY_CAST(
                REPLACE(
                    REPLACE(t.TriggerName, 'Cashout requested for $', ''),
                    ' ', ''
                ) 
            AS DECIMAL(18, 2)),
            lw.Amount
        ) AS RequestedAmount
    FROM base_triggers_with_am t
    LEFT JOIN (SELECT TriggerId, Amount FROM linked_withdrawals_for_triggers WHERE rn = 1) lw
        ON t.TriggerId = lw.TriggerId
),

ranked_pnl_for_triggers AS (
    -- Step 7: Get PNL
    SELECT b.*, p.Acc_pnl_total,
        ROW_NUMBER() OVER(PARTITION BY b.TriggerId ORDER BY p.DateID DESC) AS rn_pnl
    FROM triggers_with_amount b
    LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata p
        ON b.CID = p.CID
        AND p.DateID <= b.TriggerDateAsInt
),

triggers_of_interest AS (
    -- Step 8: Filter PNL
    SELECT 
        TriggerId, Trigger_Created_Date__c, CID, TriggerName, AccountManagerName,
        RequestedAmount, TriggerStatus,
        TriggerTier, Status__c, whatsapp_status__c, -- [NEW] Carried through for Initiated Logic
        COALESCE(
            CASE 
                WHEN Acc_pnl_total < 0 THEN 'Losing Customer'
                ELSE 'Winning/Even Customer'
            END, 
            'Unknown'
        ) AS LosingCustomerStatus
    FROM ranked_pnl_for_triggers
    WHERE rn_pnl = 1
),

trigger_to_withdrawal_links AS (
    -- Step 9: CORRECTED - Apply success logic BEFORE ranking
    SELECT t.TriggerId, w.WithdrawID
    FROM triggers_of_interest t
    JOIN all_withdrawals w 
        ON t.CID = w.CID
        AND t.RequestedAmount = w.Amount
        AND w.RequestDate < t.Trigger_Created_Date__c
        AND w.CashoutStatusID = 4
        AND w.ModificationDate > t.Trigger_Created_Date__c
        AND w.ModificationDate <= DATEADD(day, 14, t.Trigger_Created_Date__c)
        
    UNION
    
    SELECT t.TriggerId, w.WithdrawID
    FROM triggers_of_interest t
    JOIN daily_withdrawal_sums ds
        ON t.CID = ds.CID
        AND t.RequestedAmount = ds.SummedAmount
        AND ds.RequestDay <= CAST(t.Trigger_Created_Date__c AS DATE)
    JOIN all_withdrawals w
        ON ds.CID = w.CID
        AND CAST(w.RequestDate AS DATE) = ds.RequestDay
        AND w.CashoutStatusID = 4
        AND w.ModificationDate > t.Trigger_Created_Date__c
        AND w.ModificationDate <= DATEADD(day, 14, t.Trigger_Created_Date__c)
),

deduplicated_links AS (
    -- Step 10: De-duplicate Withdrawals (Rank & Filter)
    SELECT l.TriggerId, l.WithdrawID
    FROM (
        SELECT link.TriggerId, link.WithdrawID,
            ROW_NUMBER() OVER(
                PARTITION BY link.WithdrawID 
                ORDER BY 
                    CASE WHEN t.TriggerStatus = 'Solved' THEN 0 ELSE 1 END,
                    t.Trigger_Created_Date__c DESC
            ) as attribution_rank
        FROM trigger_to_withdrawal_links link
        JOIN triggers_of_interest t ON link.TriggerId = t.TriggerId
    ) l
    WHERE l.attribution_rank = 1 
)

-- Final Step: CORRECTED & SIMPLIFIED Aggregation with WhatsApp
SELECT
    t.TriggerId,
    t.Trigger_Created_Date__c,
    t.CID,
    t.TriggerName,
    t.AccountManagerName AS `Account Manager`,
    t.TriggerStatus,
    t.LosingCustomerStatus,
    t.RequestedAmount AS total_amount_requested,
    
    -- *** ADDED: Explicitly expose raw Status and whatsapp_status strings for Tableau ***
    t.Status__c,
    t.whatsapp_status__c,
    
    -- [NEW] Initiated Flag Logic
    CASE 
        WHEN t.TriggerTier = 'High' THEN TRUE
        WHEN t.TriggerTier = 'Low' AND (LOWER(t.whatsapp_status__c) = 'sent' OR t.Status__c IN ('2', '3', '5')) THEN TRUE
        ELSE FALSE
    END AS Initiated,
    
    -- Pass the raw WhatsApp session data to Tableau
    wa.WhatsApp_Session_Id AS WhatsApp_Outbound_Session_Id,
    wa.WhatsApp_Session_Date,
    wa_in.WhatsApp_Inbound_Session_Id,
    
    COALESCE(MAX(CASE WHEN link.WithdrawID IS NOT NULL THEN 1 ELSE 0 END), 0) AS was_successful_flag,
    COALESCE(SUM(w.Amount), 0) AS total_amount_saved_by_trigger,
    COUNT(DISTINCT link.WithdrawID) AS count_of_withdrawals_saved
    
FROM triggers_of_interest t
LEFT JOIN deduplicated_links link
    ON t.TriggerId = link.TriggerId
LEFT JOIN all_withdrawals w
    ON link.WithdrawID = w.WithdrawID

-- Join to the strictly attributed WhatsApp checks
LEFT JOIN whatsapp_outbound wa 
    ON t.TriggerId = wa.Trigger_Id
    AND wa.trigger_rank = 1
LEFT JOIN whatsapp_inbound wa_in
    ON t.TriggerId = wa_in.Trigger_Id
    
GROUP BY
    t.TriggerId,
    t.Trigger_Created_Date__c,
    t.CID,
    t.TriggerName,
    t.AccountManagerName,
    t.TriggerStatus,
    t.LosingCustomerStatus,
    t.RequestedAmount,
    
    -- [NEW] Added fields to GROUP BY for Initiated flag and WhatsApp
    t.TriggerTier,
    t.whatsapp_status__c,
    t.Status__c,
    wa.WhatsApp_Session_Id,
    wa.WhatsApp_Session_Date,
    wa_in.WhatsApp_Inbound_Session_Id