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
    JOIN
        main.crm.silver_crm_messagingsession ms ON c.id = ms.CaseId
    JOIN
        main.crm.silver_crm_ai_session__c ais ON ais.messaging_session__c = ms.id
    JOIN
        main.crm.silver_crm_ai_session_entry__c aise ON aise.AI_Session__c = ais.id
    GROUP BY
        c.id
),

-- Step 2: Get all chats and define 'Before', 'After', and 'With File' periods
AllChats AS (
    SELECT
        c.id AS CaseId,
        ms.id AS Id_MessagingSession, -- *** ADDED HERE ***
        c.CaseNumber,
        c.CID__c,
        c.CreatedDate AS Case_CreatedDate,
        c.origin AS Case_Origin,
        c.Lead_or_FTD__c,
        ms.ChannelName AS Messaging_ChannelName,
        CASE
            -- Before: May 1st to Sept 10th
            WHEN c.CreatedDate >= '2025-05-01' AND c.CreatedDate < '2025-09-10' THEN 'Before'
            
            -- After: Sept 10th to Nov 11th (Must have link)
            WHEN c.CreatedDate >= '2025-09-10' AND c.CreatedDate < '2025-11-11' AND COALESCE(chl.has_link, 0) = 1 THEN 'After'
            
            -- With File: Nov 11th onwards (Must have link)
            WHEN c.CreatedDate >= '2025-11-11' AND COALESCE(chl.has_link, 0) = 1 THEN 'With File'
            
            ELSE NULL 
        END AS Period
    FROM
        main.crm.silver_crm_case c
    JOIN
        main.crm.silver_crm_messagingsession ms
        ON c.id = ms.caseid
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

-- Step 3: Determine the verification level immediately BEFORE each chat
PreChatVerificationLevel AS (
    SELECT
        lc.CaseId,
        lc.Id_MessagingSession, -- *** PASSED THROUGH ***
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

-- Step 4: Find first V3+ progression after the chat (for V2 users)
FirstV3Progress AS (
    SELECT
        pcl.CaseId,
        MIN(cvc_post.Verification_ChangeDate) AS First_V3_Progress_Date
    FROM
        PreChatVerificationLevel pcl
    JOIN bizops_output_stg.bizops_output_customerhistory_gold_verificationlevel_history cvc_post
        ON pcl.CID__c = cvc_post.CID__c
    WHERE
        pcl.Verification_Level_At_Chat_Time = 2
        AND cvc_post.Verification_ChangeDate > pcl.Case_CreatedDate
        AND cvc_post.Verification_Level_New >= 3
    GROUP BY
        pcl.CaseId
),

-- Step 5: Find First Time Deposit date
FirstDeposit AS (
    SELECT
        CID,
        MIN(PaymentDate) AS First_Deposit_Date
    FROM
        main.billing.bronze_etoro_billing_deposit
    WHERE
        PaymentStatusID = 2
        AND Amount > 0
    GROUP BY
        CID
),

-- Step 6: Combine metrics
CombinedMetrics AS (
    SELECT
        pcl.CaseId,
        pcl.Id_MessagingSession, -- *** PASSED THROUGH ***
        pcl.CID__c,
        pcl.Case_CreatedDate,
        pcl.Period,
        pcl.Case_Origin,
        pcl.Lead_or_FTD__c,
        pcl.Verification_Level_At_Chat_Time,
        v3.First_V3_Progress_Date,
        fd.First_Deposit_Date,
        
        DATEDIFF(DAY, pcl.Case_CreatedDate, v3.First_V3_Progress_Date) AS Days_To_V3_Progress,
        DATEDIFF(DAY, pcl.Case_CreatedDate, fd.First_Deposit_Date) AS Days_To_FTD
    FROM
        PreChatVerificationLevel pcl
    LEFT JOIN
        FirstV3Progress v3 ON pcl.CaseId = v3.CaseId
    LEFT JOIN
        FirstDeposit fd ON pcl.CID__c = fd.CID
)

-- Final Step: Select data with new 1-day buckets and Messaging Session ID
SELECT
    cm.CaseId,
    cm.Id_MessagingSession, -- *** INCLUDED IN FINAL OUTPUT ***
    cm.CID__c,
    cm.Case_CreatedDate,
    cm.Period,
    cm.Case_Origin,
    cm.Verification_Level_At_Chat_Time,
    cm.Lead_or_FTD__c,
    
    -- V2 -> V3 Conversion Flags
    CASE 
        WHEN cm.Verification_Level_At_Chat_Time = 2 THEN 1
        ELSE 0
    END AS Is_V2_Chat_Cohort,
    
    CASE 
        WHEN cm.Verification_Level_At_Chat_Time = 2 AND cm.Days_To_V3_Progress IS NOT NULL AND cm.Days_To_V3_Progress <= 1 THEN 1
        ELSE 0
    END AS V3_Progress_1_Day,
    CASE 
        WHEN cm.Verification_Level_At_Chat_Time = 2 AND cm.Days_To_V3_Progress IS NOT NULL AND cm.Days_To_V3_Progress <= 3 THEN 1
        ELSE 0
    END AS V3_Progress_3_Days,
    CASE 
        WHEN cm.Verification_Level_At_Chat_Time = 2 AND cm.Days_To_V3_Progress IS NOT NULL AND cm.Days_To_V3_Progress <= 7 THEN 1
        ELSE 0
    END AS V3_Progress_7_Days,
    CASE 
        WHEN cm.Verification_Level_At_Chat_Time = 2 AND cm.Days_To_V3_Progress IS NOT NULL AND cm.Days_To_V3_Progress <= 14 THEN 1
        ELSE 0
    END AS V3_Progress_14_Days,
    CASE 
        WHEN cm.Verification_Level_At_Chat_Time = 2 AND cm.Days_To_V3_Progress IS NOT NULL AND cm.Days_To_V3_Progress <= 30 THEN 1
        ELSE 0
    END AS V3_Progress_30_Days,

    -- Lead -> FTD Conversion Flags
    CASE
        WHEN cm.Lead_or_FTD__c = 'Lead' THEN 1
        ELSE 0
    END AS Is_Lead_Chat_Cohort,
    
    CASE
        WHEN cm.Lead_or_FTD__c = 'Lead' AND cm.Days_To_FTD >= 0 AND cm.Days_To_FTD <= 1 THEN 1
        ELSE 0
    END AS FTD_1_Day,
    CASE
        WHEN cm.Lead_or_FTD__c = 'Lead' AND cm.Days_To_FTD >= 0 AND cm.Days_To_FTD <= 3 THEN 1
        ELSE 0
    END AS FTD_3_Days,
    CASE
        WHEN cm.Lead_or_FTD__c = 'Lead' AND cm.Days_To_FTD >= 0 AND cm.Days_To_FTD <= 7 THEN 1
        ELSE 0
    END AS FTD_7_Days,
    CASE
        WHEN cm.Lead_or_FTD__c = 'Lead' AND cm.Days_To_FTD >= 0 AND cm.Days_To_FTD <= 14 THEN 1
        ELSE 0
    END AS FTD_14_Days,
    CASE
        WHEN cm.Lead_or_FTD__c = 'Lead' AND cm.Days_To_FTD >= 0 AND cm.Days_To_FTD <= 30 THEN 1
        ELSE 0
    END AS FTD_30_Days,
    
    cm.First_V3_Progress_Date,
    cm.First_Deposit_Date,
    cm.Days_To_V3_Progress,
    cm.Days_To_FTD

FROM
    CombinedMetrics cm