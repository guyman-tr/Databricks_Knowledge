WITH
-- Step 1: Find all chats that contain the file upload link
ChatHasLink AS (
    SELECT
        c.id AS case_id,
        MAX(CASE
            WHEN aise.Bot_Message__c LIKE '%https://www.etoro.com/settings/profile%' THEN 1
            WHEN aise.Bot_Message__c LIKE '%https://www.etoro.com/login/?action=autokyc%' THEN 1
            ELSE 0
        END) AS has_link
    FROM
        main.crm.silver_crm_case c
    JOIN main.crm.silver_crm_messagingsession ms ON c.id = ms.CaseId
    JOIN main.crm.silver_crm_ai_session__c ais ON ais.messaging_session__c = ms.id
    JOIN main.crm.silver_crm_ai_session_entry__c aise ON aise.AI_Session__c = ais.id
    GROUP BY
        c.id
),

-- Step 2: Define Periods (Before vs With Feature)
AllChats AS (
    SELECT
        c.id AS CaseId,
        ms.id AS Id_MessagingSession, -- This is your JOIN KEY for Tableau
        c.CaseNumber,
        c.CID__c,
        c.CreatedDate AS Case_CreatedDate,
        c.origin AS Case_Origin,
        c.Lead_or_FTD__c,
        ms.ChannelName AS Messaging_ChannelName,
        CASE
            -- Before: May 1st to Sept 10th
            WHEN c.CreatedDate >= '2025-05-01' AND c.CreatedDate < '2025-09-10' THEN 'Before Feature'
            
            -- With Feature: Sept 10th onwards (Must have link to be considered "Exposed")
            WHEN c.CreatedDate >= '2025-09-10' AND COALESCE(chl.has_link, 0) = 1 THEN 'With Feature'
            
            ELSE NULL 
        END AS Period
    FROM
        main.crm.silver_crm_case c
    JOIN
        main.crm.silver_crm_messagingsession ms ON c.id = ms.caseid
    LEFT JOIN
        ChatHasLink chl ON c.id = chl.case_id
    WHERE
        (c.Club_Level_on_Creation__c <> 'Internal' OR c.Club_Level_on_Creation__c IS NULL)
        AND c.origin IN ('Chat', 'Chatbot')
        AND ms.ChannelName = 'Customer Service Web Chat'
        AND C.CreatedDate >= '2025-05-01'
    QUALIFY
        (ROW_NUMBER() OVER (PARTITION BY c.CaseNumber ORDER BY c.CreatedDate) = 1)
        AND Period IS NOT NULL
),

-- Step 3: Determine Verification Level BEFORE Chat
PreChatVerificationLevel AS (
    SELECT
        lc.CaseId,
        lc.Id_MessagingSession,
        lc.CID__c,
        lc.Case_CreatedDate,
        lc.Period,
        lc.Case_Origin,
        lc.Lead_or_FTD__c,
        COALESCE(cvc_pre.Verification_Level_New, 0) AS Verification_Level_At_Chat_Time
    FROM
        AllChats lc
    LEFT JOIN bizops_output_stg.bizops_output_customerhistory_gold_verificationlevel_history cvc_pre
        ON lc.CID__c = cvc_pre.CID__c
        AND cvc_pre.Verification_ChangeDate < lc.Case_CreatedDate
    QUALIFY
        ROW_NUMBER() OVER (PARTITION BY lc.CaseId ORDER BY cvc_pre.Verification_ChangeDate DESC) = 1
),

-- Step 4: Find V3 Progression (For Levels 0, 1, 2)
FirstV3Progress AS (
    SELECT
        pcl.CaseId,
        MIN(cvc_post.Verification_ChangeDate) AS First_V3_Progress_Date
    FROM
        PreChatVerificationLevel pcl
    JOIN bizops_output_stg.bizops_output_customerhistory_gold_verificationlevel_history cvc_post
        ON pcl.CID__c = cvc_post.CID__c
    WHERE
        pcl.Verification_Level_At_Chat_Time < 3 
        AND cvc_post.Verification_ChangeDate > pcl.Case_CreatedDate
        AND cvc_post.Verification_Level_New >= 3
    GROUP BY
        pcl.CaseId
),

-- Step 5: Find First Time Deposit & AMOUNT
FirstDeposit AS (
    SELECT
        CID,
        MIN(PaymentDate) AS First_Deposit_Date,
        SUM(Amount) AS FTD_Amount 
    FROM
        main.billing.bronze_etoro_billing_deposit
    WHERE
        PaymentStatusID = 2
        AND Amount > 0
    GROUP BY
        CID
),

-- NEW Step 6: Get EV Status (Isolated)
EV_Data AS (
    SELECT 
        CID,
        -- If status is NOT a failure, we count as success.
        -- If missing/null/NA, it counts as 0.
        CASE 
            WHEN COALESCE(EV_MatchStatus, 'NA') IN ('NotVerified', 'PartiallyVerified', 'None', 'NA') THEN 0
            ELSE 1 
        END AS Is_EV_Success
    FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis
)

-- Final Selection for Main Table
SELECT
    cm.CaseId,
    cm.Id_MessagingSession,
    cm.CID__c,
    cm.Case_CreatedDate,
    cm.Period,
    cm.Verification_Level_At_Chat_Time,
    cm.Lead_or_FTD__c,
    
    -- Verification Performance
    v3.First_V3_Progress_Date,
    DATEDIFF(DAY, cm.Case_CreatedDate, v3.First_V3_Progress_Date) AS Days_To_V3_Progress,
    
    -- FTD Performance
    fd.First_Deposit_Date,
    fd.FTD_Amount,
    DATEDIFF(DAY, cm.Case_CreatedDate, fd.First_Deposit_Date) AS Days_To_FTD,

    -- NEW EV COLUMN (Safe Join)
    -- If customer not found in EV table, defaults to 0 (Not EV Verified)
    COALESCE(ev.Is_EV_Success, 0) AS Is_EV_Success

FROM
    PreChatVerificationLevel cm
LEFT JOIN
    FirstV3Progress v3 ON cm.CaseId = v3.CaseId
LEFT JOIN
    FirstDeposit fd ON cm.CID__c = fd.CID
-- Safe LEFT JOIN ensures we don't lose any chats if EV data is missing
LEFT JOIN 
    EV_Data ev ON cm.CID__c = ev.CID