/* UNIFIED SUCCESS METRICS QUERY - WIDE TABLE ARCHITECTURE */

WITH 
-- [BASE] Get all relevant triggers from both tiers
base_triggers AS (
    SELECT 
        Id AS TriggerId, 
        Name, 
        Trigger_Created_Date__c, 
        Account__c, 
        Trigger_Definition__c,
        Status__c 
    FROM main.crm.silver_crm_call_to_action__c
    UNION ALL
    SELECT 
        Id AS TriggerId, 
        Name, 
        Trigger_Created_Date__c, 
        Account__c, 
        Trigger_Definition__c,
        Status__c 
    FROM main.crm.silver_crm_low_tier_trigger__c
),

-- [MAP] Add CID, GCID, Clean Amount Parsing, DateInt, and Trigger_ID__c
triggers_with_ids AS (
    SELECT 
        t.TriggerId,
        t.Name,
        LOWER(t.Name) AS LowerName, 
        def.Trigger_ID__c, -- [NEW] Expose the persistent numeric ID
        t.Trigger_Created_Date__c,
        t.Trigger_Definition__c,
        t.Status__c,
        amp.Customer_Unique_ID_CID__c AS CID,
        amp.GCID__c AS GCID, 
        CAST(TO_CHAR(t.Trigger_Created_Date__c, 'yyyyMMdd') AS INT) AS TriggerDateAsInt, 
        
        -- Helper for Cashout Parsing (We still need the name string to extract the dollar amount)
        COALESCE(
            TRY_CAST(REPLACE(LOWER(t.Name), 'cash out of', '') AS DECIMAL(18, 2)),
            TRY_CAST(REPLACE(REPLACE(LOWER(t.Name), 'cashout requested for $', ''), ' ', '') AS DECIMAL(18, 2))
        ) AS ParsedAmount
    FROM base_triggers t
    JOIN main.crm.silver_crm_accountidmappingtable amp 
        ON t.Account__c = amp.id
    -- [NEW] Join to the definitions table to grab the numeric ID
    LEFT JOIN main.crm.silver_crm_engagement_trigger_definition__c def 
        ON t.Trigger_Definition__c = def.Id
),

/* =========================================================================
   START DEDICATED CASHOUT CTEs 
   ========================================================================= */
cashout_triggers AS (
    SELECT * FROM triggers_with_ids WHERE Trigger_ID__c = 18
),

all_large_withdrawals AS (
    SELECT WithdrawID, CID, RequestDate, ModificationDate, Amount, CurrencyID, CashoutStatusID
    FROM main.billing.bronze_etoro_billing_withdraw WHERE Amount >= 25000
),

all_withdrawals AS (
    SELECT WithdrawID, CID, RequestDate, ModificationDate, Amount, CurrencyID, CashoutStatusID
    FROM main.billing.bronze_etoro_billing_withdraw 
    WHERE CID IN (SELECT DISTINCT CID FROM cashout_triggers)
),

daily_withdrawal_sums AS (
    SELECT CID, CAST(RequestDate AS DATE) AS RequestDay, SUM(Amount) AS SummedAmount
    FROM all_withdrawals GROUP BY 1, 2
),

linked_withdrawals_for_triggers AS (
    SELECT t.TriggerId, w.Amount,
        ROW_NUMBER() OVER(PARTITION BY t.TriggerId ORDER BY w.RequestDate DESC) AS rn
    FROM cashout_triggers t
    JOIN all_large_withdrawals w ON t.CID = w.CID AND w.RequestDate < t.Trigger_Created_Date__c
),

triggers_with_amount AS (
    SELECT t.*, 
        COALESCE(t.ParsedAmount, lw.Amount) AS RequestedAmount
    FROM cashout_triggers t
    LEFT JOIN (SELECT TriggerId, Amount FROM linked_withdrawals_for_triggers WHERE rn = 1) lw
        ON t.TriggerId = lw.TriggerId
),

ranked_pnl_for_triggers AS (
    SELECT b.*, p.Acc_pnl_total,
        ROW_NUMBER() OVER(PARTITION BY b.TriggerId ORDER BY p.DateID DESC) AS rn_pnl
    FROM triggers_with_amount b
    LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata p
        ON b.CID = p.CID
        AND p.DateID <= b.TriggerDateAsInt
),

triggers_of_interest AS (
    SELECT *
    FROM ranked_pnl_for_triggers
    WHERE rn_pnl = 1
),

trigger_to_withdrawal_links AS (
    SELECT t.TriggerId, w.WithdrawID
    FROM triggers_of_interest t
    JOIN all_withdrawals w 
        ON t.CID = w.CID AND t.RequestedAmount = w.Amount
        AND w.RequestDate < t.Trigger_Created_Date__c AND w.CashoutStatusID = 4
        AND w.ModificationDate > t.Trigger_Created_Date__c AND w.ModificationDate <= DATEADD(day, 14, t.Trigger_Created_Date__c)
    UNION
    SELECT t.TriggerId, w.WithdrawID
    FROM triggers_of_interest t
    JOIN daily_withdrawal_sums ds 
        ON t.CID = ds.CID AND t.RequestedAmount = ds.SummedAmount
        AND ds.RequestDay <= CAST(t.Trigger_Created_Date__c AS DATE)
    JOIN all_withdrawals w
        ON ds.CID = w.CID AND CAST(w.RequestDate AS DATE) = ds.RequestDay
        AND w.CashoutStatusID = 4 AND w.ModificationDate > t.Trigger_Created_Date__c
        AND w.ModificationDate <= DATEADD(day, 14, t.Trigger_Created_Date__c)
),

deduplicated_links AS (
    SELECT l.TriggerId, l.WithdrawID
    FROM (
        SELECT link.TriggerId, link.WithdrawID,
            ROW_NUMBER() OVER(
                PARTITION BY link.WithdrawID 
                ORDER BY CASE WHEN t.Status__c = '5' THEN 0 ELSE 1 END, t.Trigger_Created_Date__c DESC
            ) as attribution_rank
        FROM trigger_to_withdrawal_links link
        JOIN triggers_of_interest t ON link.TriggerId = t.TriggerId
    ) l
    WHERE l.attribution_rank = 1 
),

/* =========================================================================
   LOGIC A: Cashout 25k+ 
   ========================================================================= */
logic_cashout AS (
    SELECT 
        t.TriggerId AS TriggerId_SuccessQuery,
        1 AS IsSuccessful_SuccessQuery,
        'Cashout Canceled' AS SuccessType_SuccessQuery,
        
        -- 8 WIDE KPI COLUMNS
        SUM(w.Amount) AS Value_Cancelled_Withdrawals,
        0 AS Value_New_Deposits,
        0 AS Value_New_Position_Volume,
        0 AS Value_Retained_Portfolio,
        0 AS Count_IoB_OptIns,
        0 AS Count_New_Positions,
        0 AS Count_Positions_Retained,
        0 AS Count_Club_Upgrades_Retained
    FROM triggers_of_interest t
    JOIN deduplicated_links link ON t.TriggerId = link.TriggerId
    JOIN all_withdrawals w ON link.WithdrawID = w.WithdrawID
    GROUP BY t.TriggerId
),

/* =========================================================================
   LOGIC B: High Balance / Big Position Close / Big Deposit
   ========================================================================= */
logic_trading_raw AS (
    SELECT 
        t.TriggerId, 'Position' AS EventType, np.Amount AS Val, 1 AS Cnt
    FROM triggers_with_ids t
    JOIN main.dwh.dim_position np 
        ON t.CID = np.CID 
        AND np.OpenOccurred > t.Trigger_Created_Date__c 
        AND np.OpenOccurred <= DATEADD(day, 14, t.Trigger_Created_Date__c)
    -- High Available Balance (3, 36, 37), Big Positions Close (4), and Big Deposit (21, 34, 35)
    WHERE t.Trigger_ID__c IN (3, 36, 37, 4, 21, 34, 35)

    UNION ALL

    SELECT TriggerId, 'Interest' AS EventType, 0 AS Val, 1 AS Cnt
    FROM (
        SELECT t.TriggerId FROM triggers_with_ids t
        JOIN bi_db.bronze_interest_trade_interestconsent io 
            ON t.CID = io.CID AND io.ValidFrom > t.Trigger_Created_Date__c AND io.ValidFrom <= DATEADD(day, 14, t.Trigger_Created_Date__c) AND io.ConsentStatusID = 1
        WHERE t.Trigger_ID__c IN (3, 36, 37, 4, 21, 34, 35)
        UNION 
        SELECT t.TriggerId FROM triggers_with_ids t
        JOIN bi_db.bronze_interest_history_interestconsent ioh 
            ON t.CID = ioh.CID AND ioh.ValidFrom > t.Trigger_Created_Date__c AND ioh.ValidFrom <= DATEADD(day, 14, t.Trigger_Created_Date__c) AND ioh.ConsentStatusID = 1
        WHERE t.Trigger_ID__c IN (3, 36, 37, 4, 21, 34, 35)
    ) deduplicated_interest_joiners
),

logic_trading_aggregated AS (
    SELECT 
        TriggerId AS TriggerId_SuccessQuery,
        1 AS IsSuccessful_SuccessQuery,
        'Trading Activity' AS SuccessType_SuccessQuery,
        
        -- 8 WIDE KPI COLUMNS
        0 AS Value_Cancelled_Withdrawals,
        0 AS Value_New_Deposits,
        SUM(Val) AS Value_New_Position_Volume,
        0 AS Value_Retained_Portfolio,
        SUM(CASE WHEN EventType = 'Interest' THEN Cnt ELSE 0 END) AS Count_IoB_OptIns,
        SUM(CASE WHEN EventType = 'Position' THEN Cnt ELSE 0 END) AS Count_New_Positions,
        0 AS Count_Positions_Retained,
        0 AS Count_Club_Upgrades_Retained
    FROM logic_trading_raw
    GROUP BY TriggerId
),

/* =========================================================================
   LOGIC C: Monthly Active Log-in 
   ========================================================================= */
logic_login AS (
    SELECT 
        t.TriggerId AS TriggerId_SuccessQuery,
        1 AS IsSuccessful_SuccessQuery,
        'Login' AS SuccessType_SuccessQuery,
        
        -- 8 WIDE KPI COLUMNS
        0 AS Value_Cancelled_Withdrawals,
        0 AS Value_New_Deposits,
        0 AS Value_New_Position_Volume,
        0 AS Value_Retained_Portfolio,
        0 AS Count_IoB_OptIns,
        0 AS Count_New_Positions,
        0 AS Count_Positions_Retained,
        0 AS Count_Club_Upgrades_Retained
    FROM triggers_with_ids t
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ca
        ON t.GCID = ca.gcid AND ca.Occurred > t.Trigger_Created_Date__c AND ca.Occurred <= DATEADD(day, 30, t.Trigger_Created_Date__c)
    WHERE t.Trigger_ID__c = 2 AND ca.ActionTypeID = 14
    GROUP BY t.TriggerId
),

/* =========================================================================
   LOGIC D: Big Revenue Drop
   ========================================================================= */
logic_revenue AS (
    SELECT 
        TriggerId AS TriggerId_SuccessQuery,
        1 AS IsSuccessful_SuccessQuery,
        'Revenue Recovered' AS SuccessType_SuccessQuery,
        
        -- 8 WIDE KPI COLUMNS
        0 AS Value_Cancelled_Withdrawals,
        0 AS Value_New_Deposits,
        0 AS Value_New_Position_Volume,
        0 AS Value_Retained_Portfolio,
        0 AS Count_IoB_OptIns,
        0 AS Count_New_Positions,
        0 AS Count_Positions_Retained,
        0 AS Count_Club_Upgrades_Retained
    FROM (
        SELECT t.TriggerId,
            SUM(CASE WHEN dp.DateID >= CAST(TO_CHAR(DATEADD(day, -90, t.Trigger_Created_Date__c), 'yyyyMMdd') AS INT) AND dp.DateID < CAST(TO_CHAR(t.Trigger_Created_Date__c, 'yyyyMMdd') AS INT) THEN dp.Revenue_Total ELSE 0 END) / 3.0 AS PriorAvg,
            SUM(CASE WHEN dp.DateID >= CAST(TO_CHAR(t.Trigger_Created_Date__c, 'yyyyMMdd') AS INT) AND dp.DateID <= CAST(TO_CHAR(DATEADD(day, 30, t.Trigger_Created_Date__c), 'yyyyMMdd') AS INT) THEN dp.Revenue_Total ELSE 0 END) AS PostRevenue
        FROM triggers_with_ids t
        JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata dp 
            ON t.CID = dp.CID AND dp.DateID >= CAST(TO_CHAR(DATEADD(day, -90, t.Trigger_Created_Date__c), 'yyyyMMdd') AS INT) AND dp.DateID <= CAST(TO_CHAR(DATEADD(day, 30, t.Trigger_Created_Date__c), 'yyyyMMdd') AS INT)
        WHERE t.Trigger_ID__c = 8
        GROUP BY t.TriggerId
    ) calc
    WHERE PostRevenue >= PriorAvg
),

/* =========================================================================
   LOGIC E: First Time Copying a Popular Investor & Smart Portfolio
   ========================================================================= */
logic_first_time_copying AS (
    SELECT 
        t.TriggerId AS TriggerId_SuccessQuery,
        1 AS IsSuccessful_SuccessQuery,
        'Copy Kept 14+ Days' AS SuccessType_SuccessQuery,
        
        -- 8 WIDE KPI COLUMNS
        0 AS Value_Cancelled_Withdrawals,
        0 AS Value_New_Deposits,
        0 AS Value_New_Position_Volume,
        0 AS Value_Retained_Portfolio,
        0 AS Count_IoB_OptIns,
        0 AS Count_New_Positions,
        1 AS Count_Positions_Retained, 
        0 AS Count_Club_Upgrades_Retained
    FROM triggers_with_ids t
    -- Popular Investor (16) and Smart Portfolio (33)
    WHERE t.Trigger_ID__c IN (16, 33)
      AND EXISTS (
          SELECT 1
          FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror cp
          WHERE cp.CID = t.CID
            AND TO_DATE(CAST(cp.OpenDateID AS STRING), 'yyyyMMdd') <= DATEADD(day, 2, CAST(t.Trigger_Created_Date__c AS DATE))
            AND TO_DATE(CAST(cp.OpenDateID AS STRING), 'yyyyMMdd') >= DATEADD(day, -2, CAST(t.Trigger_Created_Date__c AS DATE))
            AND (
                cp.CloseDateID IS NULL 
                OR TO_DATE(CAST(cp.CloseDateID AS STRING), 'yyyyMMdd') > DATEADD(day, 14, CAST(t.Trigger_Created_Date__c AS DATE))
            )
      )
),

/* =========================================================================
   LOGIC F: New Deposit
   ========================================================================= */
logic_new_deposit AS (
    SELECT 
        t.TriggerId AS TriggerId_SuccessQuery,
        1 AS IsSuccessful_SuccessQuery,
        'Opened Position' AS SuccessType_SuccessQuery,
        
        -- 8 WIDE KPI COLUMNS
        0 AS Value_Cancelled_Withdrawals,
        0 AS Value_New_Deposits,
        COALESCE(agg.SumAmount, 0) AS Value_New_Position_Volume,
        0 AS Value_Retained_Portfolio,
        0 AS Count_IoB_OptIns,
        COALESCE(agg.PosCount, 0) AS Count_New_Positions,
        0 AS Count_Positions_Retained,
        0 AS Count_Club_Upgrades_Retained
    FROM triggers_with_ids t
    JOIN (
        SELECT 
            t_inner.TriggerId,
            SUM(np.Amount) AS SumAmount,
            COUNT(np.CID) AS PosCount
        FROM triggers_with_ids t_inner
        JOIN main.dwh.dim_position np 
            ON np.CID = t_inner.CID
            AND np.OpenOccurred > t_inner.Trigger_Created_Date__c
            AND np.OpenOccurred <= DATEADD(day, 14, t_inner.Trigger_Created_Date__c)
            AND np.Amount > 0
        WHERE t_inner.Trigger_ID__c = 20
        GROUP BY t_inner.TriggerId
    ) agg ON t.TriggerId = agg.TriggerId
    WHERE t.Trigger_ID__c = 20
),

/* =========================================================================
   LOGIC G: High Leverage Activity
   ========================================================================= */
high_leverage_events AS (
    SELECT t.TriggerId, 'Position' AS EventType, hlp.Amount AS Val, 1 AS Cnt
    FROM triggers_with_ids t
    JOIN main.dwh.dim_position hlp 
        ON hlp.CID = t.CID
        AND hlp.OpenOccurred > t.Trigger_Created_Date__c
        AND hlp.OpenOccurred <= DATEADD(day, 14, t.Trigger_Created_Date__c)
        AND hlp.Leverage >= 10 
        AND hlp.MirrorID = 0
    WHERE t.Trigger_ID__c = 10

    UNION ALL

    SELECT t.TriggerId, 'Deposit' AS EventType, cd.Amount AS Val, 0 AS Cnt
    FROM triggers_with_ids t
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction cd 
        ON cd.RealCID = t.CID
        AND cd.Occurred > t.Trigger_Created_Date__c
        AND cd.Occurred <= DATEADD(day, 14, t.Trigger_Created_Date__c)
        AND cd.ActionTypeID = 7
    WHERE t.Trigger_ID__c = 10
),

logic_high_leverage AS (
    SELECT 
        TriggerId AS TriggerId_SuccessQuery,
        1 AS IsSuccessful_SuccessQuery,
        'High Leverage Pos or Deposit' AS SuccessType_SuccessQuery,
        
        -- 8 WIDE KPI COLUMNS
        0 AS Value_Cancelled_Withdrawals,
        SUM(CASE WHEN EventType = 'Deposit' THEN Val ELSE 0 END) AS Value_New_Deposits,
        SUM(CASE WHEN EventType = 'Position' THEN Val ELSE 0 END) AS Value_New_Position_Volume,
        0 AS Value_Retained_Portfolio,
        0 AS Count_IoB_OptIns,
        SUM(CASE WHEN EventType = 'Position' THEN Cnt ELSE 0 END) AS Count_New_Positions,
        0 AS Count_Positions_Retained,
        0 AS Count_Club_Upgrades_Retained
    FROM high_leverage_events
    GROUP BY TriggerId
),

/* =========================================================================
   LOGIC H: Monthly Active Open 
   ========================================================================= */
logic_monthly_active_open AS (
    SELECT 
        t.TriggerId AS TriggerId_SuccessQuery,
        1 AS IsSuccessful_SuccessQuery,
        'Opened Position (30 Days)' AS SuccessType_SuccessQuery,
        
        -- 8 WIDE KPI COLUMNS
        0 AS Value_Cancelled_Withdrawals,
        0 AS Value_New_Deposits,
        COALESCE(agg.SumAmount, 0) AS Value_New_Position_Volume,
        0 AS Value_Retained_Portfolio,
        0 AS Count_IoB_OptIns,
        COALESCE(agg.PosCount, 0) AS Count_New_Positions,
        0 AS Count_Positions_Retained,
        0 AS Count_Club_Upgrades_Retained
    FROM triggers_with_ids t
    JOIN (
        SELECT 
            t_inner.TriggerId,
            SUM(np.Amount) AS SumAmount,
            COUNT(np.CID) AS PosCount
        FROM triggers_with_ids t_inner
        JOIN main.dwh.dim_position np 
            ON np.CID = t_inner.CID
            AND np.OpenOccurred > t_inner.Trigger_Created_Date__c
            AND np.OpenOccurred <= DATEADD(day, 30, t_inner.Trigger_Created_Date__c)
            AND np.Amount > 0
        WHERE t_inner.Trigger_ID__c = 1
        GROUP BY t_inner.TriggerId
    ) agg ON t.TriggerId = agg.TriggerId
    WHERE t.Trigger_ID__c = 1
),

/* =========================================================================
   LOGIC I: High Risk with High Losses
   ========================================================================= */
logic_high_risk_losses AS (
    SELECT 
        t.TriggerId AS TriggerId_SuccessQuery,
        1 AS IsSuccessful_SuccessQuery,
        'No Cashout (14 Days)' AS SuccessType_SuccessQuery,
        
        -- 8 WIDE KPI COLUMNS
        0 AS Value_Cancelled_Withdrawals,
        0 AS Value_New_Deposits,
        0 AS Value_New_Position_Volume,
        COALESCE(vl.RealizedEquity, 0) AS Value_Retained_Portfolio,
        0 AS Count_IoB_OptIns,
        0 AS Count_New_Positions,
        0 AS Count_Positions_Retained,
        0 AS Count_Club_Upgrades_Retained
    FROM triggers_with_ids t
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities vl
        ON t.CID = vl.CID
        AND vl.etr_ymd = CAST(t.Trigger_Created_Date__c AS DATE)
    WHERE t.Trigger_ID__c = 9
      AND NOT EXISTS (
          SELECT 1
          FROM main.billing.bronze_etoro_billing_withdraw w
          WHERE w.CID = t.CID
            AND w.RequestDate > t.Trigger_Created_Date__c
            AND w.RequestDate <= DATEADD(day, 14, t.Trigger_Created_Date__c)
            AND w.CashoutStatusID != 44 
      )
),

/* =========================================================================
   LOGIC J: Low Balance with High Equity
   ========================================================================= */
logic_low_balance_high_equity AS (
    SELECT 
        t.TriggerId AS TriggerId_SuccessQuery,
        1 AS IsSuccessful_SuccessQuery,
        'Deposited (7 Days)' AS SuccessType_SuccessQuery,
        
        -- 8 WIDE KPI COLUMNS
        0 AS Value_Cancelled_Withdrawals,
        COALESCE(agg.SumDeposit, 0) AS Value_New_Deposits,
        0 AS Value_New_Position_Volume,
        0 AS Value_Retained_Portfolio,
        0 AS Count_IoB_OptIns,
        0 AS Count_New_Positions,
        0 AS Count_Positions_Retained,
        0 AS Count_Club_Upgrades_Retained
    FROM triggers_with_ids t
    JOIN (
        SELECT 
            t_inner.TriggerId,
            SUM(cd.Amount) AS SumDeposit
        FROM triggers_with_ids t_inner
        JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction cd 
            ON cd.RealCID = t_inner.CID
            AND cd.Occurred > t_inner.Trigger_Created_Date__c
            AND cd.Occurred <= DATEADD(day, 7, t_inner.Trigger_Created_Date__c)
            AND cd.ActionTypeID = 7
        WHERE t_inner.Trigger_ID__c = 7
        GROUP BY t_inner.TriggerId
    ) agg ON t.TriggerId = agg.TriggerId
    WHERE t.Trigger_ID__c = 7
)

/* =========================================================================
   FINAL OUTPUT
   ========================================================================= */
SELECT * FROM logic_cashout
UNION ALL
SELECT * FROM logic_trading_aggregated
UNION ALL
SELECT * FROM logic_login
UNION ALL
SELECT * FROM logic_revenue
UNION ALL
SELECT * FROM logic_first_time_copying
UNION ALL
SELECT * FROM logic_new_deposit
UNION ALL
SELECT * FROM logic_high_leverage
UNION ALL
SELECT * FROM logic_monthly_active_open
UNION ALL
SELECT * FROM logic_high_risk_losses
UNION ALL
SELECT * FROM logic_low_balance_high_equity