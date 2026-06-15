WITH LeadChats AS (
    SELECT
        c.id AS CaseId,
        c.CaseNumber,
        c.CID__c,
        c.CreatedDate AS Case_CreatedDate,
        c.origin AS Case_Origin, -- 'Chatbot' or 'Chat (escalated)
        ms.ChannelName AS Messaging_ChannelName
    FROM
        main.crm.silver_crm_case c
    JOIN
        main.crm.silver_crm_messagingsession ms
        ON c.id = ms.caseid
    WHERE
        c.Lead_or_FTD__c = 'Lead'
        AND (c.Club_Level_on_Creation__c <> 'Internal' OR c.Club_Level_on_Creation__c IS NULL)
        AND c.origin IN ('Chat', 'Chatbot')
        AND ms.ChannelName = 'Customer Service Web Chat'
    QUALIFY
        ROW_NUMBER() OVER (PARTITION BY c.CaseNumber ORDER BY c.CreatedDate) = 1 -- Ensure one row per case
),
-- Determine the verification level immediately BEFORE the chat using the pre-calculated changes table
PreChatVerificationLevel AS (
    SELECT
        lc.CaseId,
        lc.CID__c,
        lc.Case_CreatedDate,
        COALESCE(cvc_pre.Verification_Level_New, 0) AS Verification_Level_At_Chat_Time -- Default to 0 if no history found before chat
    FROM
        LeadChats lc
    LEFT JOIN bizops_output_stg.bizops_output_customerhistory_gold_verificationlevel_history cvc_pre
        ON lc.CID__c = cvc_pre.CID__c
       AND cvc_pre.Verification_ChangeDate < lc.Case_CreatedDate
    QUALIFY
        ROW_NUMBER() OVER (PARTITION BY lc.CaseId ORDER BY cvc_pre.Verification_ChangeDate DESC) = 1
),
ChatVerificationProgress AS (
    SELECT
        lc.CaseId,
        lc.CaseNumber,
        lc.CID__c,
        lc.Case_CreatedDate,
        lc.Case_Origin,
        lc.Messaging_ChannelName,
        pcl.Verification_Level_At_Chat_Time, -- Derived from PreChatVerificationLevel CTE

        cvc_post.Verification_ChangeDate,
        cvc_post.Verification_Level_Old AS Verif_History_Level_Old,
        cvc_post.Verification_Level_New AS Verif_History_Level_New,

        -- This flag now indicates *any* valid level increase in the history table
        CASE
            WHEN cvc_post.Verification_ChangeDate IS NOT NULL
                 AND cvc_post.Verification_Level_New > COALESCE(cvc_post.Verification_Level_Old, -1)
            THEN TRUE
            ELSE FALSE
        END AS Is_Upgrade_In_History,

        -- Check if this upgrade happened within 30 days after chat
        CASE
            WHEN cvc_post.Verification_ChangeDate IS NOT NULL
                 AND cvc_post.Verification_ChangeDate > lc.Case_CreatedDate
                 AND cvc_post.Verification_ChangeDate <= lc.Case_CreatedDate + INTERVAL '30 days'
                 AND cvc_post.Verification_Level_New > COALESCE(cvc_post.Verification_Level_Old, -1)
            THEN TRUE
            ELSE FALSE
        END AS Is_Progress_Within_30_Days,

        -- Calculate days to progress (if applicable)
        DATEDIFF(DAY, lc.Case_CreatedDate, cvc_post.Verification_ChangeDate) AS Days_To_Verification_Progress
    FROM
        LeadChats lc
    INNER JOIN PreChatVerificationLevel pcl
        ON lc.CaseId = pcl.CaseId
    LEFT JOIN bizops_output_stg.bizops_output_customerhistory_gold_verificationlevel_history cvc_post
        ON lc.CID__c = cvc_post.CID__c
       AND cvc_post.Verification_ChangeDate > lc.Case_CreatedDate -- Only look for verification changes *after* the chat
)
SELECT
    c.CaseId,
    c.CaseNumber,
    c.CID__c,
    c.Case_CreatedDate,
    c.Case_Origin,
    c.Messaging_ChannelName,
    c.Verification_Level_At_Chat_Time,

    -- These will be the details for the HIGHEST progress within 30 days (or NULL if no progress)
    c.Verification_ChangeDate,
    c.Verif_History_Level_Old,
    c.Verif_History_Level_New,

    c.Is_Upgrade_In_History,
    c.Is_Progress_Within_30_Days,

    c.Days_To_Verification_Progress
FROM
    ChatVerificationProgress c
QUALIFY -- Use QUALIFY to pick the *single most relevant* row for each chat
    ROW_NUMBER() OVER (
        PARTITION BY c.CaseId
        ORDER BY
            -- 1. Prioritize rows that actually represent progress within 30 days
            CASE WHEN c.Is_Progress_Within_30_Days THEN 0 ELSE 1 END ASC,
            -- 2. Among progressing rows, pick the one with the highest new verification level
            c.Verif_History_Level_New DESC,
            -- 3. If multiple records achieve the same highest level, pick the earliest one
            c.Verification_ChangeDate ASC
    ) = 1