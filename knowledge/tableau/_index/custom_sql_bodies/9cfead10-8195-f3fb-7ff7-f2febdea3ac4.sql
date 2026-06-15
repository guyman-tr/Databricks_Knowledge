WITH Chats AS (
    -- 🔹 Live Chat Transcripts
    SELECT DISTINCT 
        DATE_TRUNC('day', CAST(c.Time AS DATE)) AS Day,
        l.CaseId,
        'Chats' AS Type,
        CASE 
            WHEN c.Detail LIKE '%US%' THEN 'US'
            WHEN c.Detail LIKE '%General Support%' THEN '1.General Support'
            WHEN c.Detail LIKE '%Financial Services%' THEN '2.Financial Services'
            WHEN c.Detail LIKE '%eToro Money%' THEN '3.eToro Money'
            WHEN c.Detail LIKE '%Hacked%' THEN '4.Hacked Accounts'
            WHEN c.Detail LIKE '%GDPR%' THEN '5.Islamic/GDPR'
            WHEN c.Detail LIKE '%Islamic%' THEN '5.Islamic/GDPR'
            WHEN c.Detail LIKE '%Club%' THEN '6.Club Issues'
            WHEN c.Detail LIKE '%Trading Experience%' THEN '7.Trading Experience'
            WHEN c.Detail LIKE '%Technical%' THEN '8.Technical'
            WHEN c.Detail LIKE '%CS Marketing%' THEN '9.CS Marketing'
            WHEN c.Detail LIKE '%BU%' THEN '1.General Support'
            WHEN c.Detail LIKE '%Global%' THEN '1.General Support'
            ELSE 'Other'
        END AS Skill
    FROM crm.silver_crm_livechattranscriptevent c
    LEFT JOIN crm.silver_crm_livechattranscript l 
        ON c.LiveChatTranscriptId = l.ID
    WHERE CAST(c.Time AS DATE) >= current_date - INTERVAL 30 DAY
      AND l.CaseId IS NOT NULL
      AND c.Detail NOT LIKE '%Cashout%'
      AND c.Detail NOT LIKE '%Deposit%'
),

Messaging AS (
    -- 🔹 Messaging Sessions (Asynchronous Chat)
    SELECT DISTINCT 
        DATE_TRUNC('day', CAST(c.CreatedDate AS DATE)) AS Day,
        s.CaseId,
        'Chats' AS Type,
        CASE 
            WHEN c.NewValue LIKE '%US%' THEN 'US'
            WHEN c.NewValue LIKE '%General%' THEN '1.General Support'
            WHEN c.NewValue LIKE '%Financial%' THEN '2.Financial Services'
            WHEN c.NewValue LIKE '%eToro%' THEN '3.eToro Money'
            WHEN c.NewValue LIKE '%Hacked%' THEN '4.Hacked Accounts'
            WHEN c.NewValue LIKE '%GDPR%' THEN '5.Islamic/GDPR'
            WHEN c.NewValue LIKE '%Islamic%' THEN '5.Islamic/GDPR'
            WHEN c.NewValue LIKE '%Club%' THEN '6.Club Issues'
            WHEN c.NewValue LIKE '%Trading%' THEN '7.Trading Experience'
            WHEN c.NewValue LIKE '%Technical%' THEN '8.Technical'
            WHEN c.NewValue LIKE '%Marketing%' THEN '9.CS Marketing'
            WHEN c.NewValue LIKE '%BU%' THEN '1.General Support'
            WHEN c.NewValue LIKE '%Global%' THEN '1.General Support'
            ELSE 'Other'
        END AS Skill
    FROM crm.silver_crm_messagingsessionhistory c
    LEFT JOIN crm.silver_crm_messagingsession s 
        ON s.ID = c.MessagingSessionId
    WHERE CAST(c.CreatedDate AS DATE) >= current_date - INTERVAL 30  DAY
      AND s.CaseId IS NOT NULL
      AND c.NewValue NOT LIKE '%Cashout%'
      AND c.NewValue NOT LIKE '%Deposit%'
),

Cases AS (
    -- 🔹 Standard CRM Cases
    SELECT DISTINCT 
        DATE_TRUNC('day', CAST(ch.CreatedDate AS DATE)) AS Day,
        ch.CaseId,
        'Cases' AS Type,
        CASE 
            WHEN ch.NewValue LIKE '%US%' THEN 'US'
            WHEN ch.NewValue LIKE '%General Support%' THEN '1.General Support'
            WHEN ch.NewValue LIKE '%Financial Services%' THEN '2.Financial Services'
            WHEN ch.NewValue LIKE '%eToro Money%' THEN '3.eToro Money'
            WHEN ch.NewValue LIKE '%Hacked%' THEN '4.Hacked Accounts'
            WHEN ch.NewValue LIKE '%GDPR%' THEN '5.Islamic/GDPR'
            WHEN ch.NewValue LIKE '%Islamic%' THEN '5.Islamic/GDPR'
            WHEN ch.NewValue LIKE '%Club%' THEN '6.Club Issues'
            WHEN ch.NewValue LIKE '%Trading Experience%' THEN '7.Trading Experience'
            WHEN ch.NewValue LIKE '%Technical%' THEN '8.Technical'
            WHEN ch.NewValue LIKE '%CS Marketing%' THEN '9.CS Marketing'
            ELSE 'Other'
        END AS Skill
    FROM crm.silver_crm_casehistory ch
    WHERE CAST(ch.CreatedDate AS DATE) >= current_date - INTERVAL 30 DAY
),

Reopened AS (
    -- 🔹 Reopened Cases (Your BI Logic)
    SELECT DISTINCT 
        DATE_TRUNC('day', CAST(ch.CreatedDate AS DATE)) AS Day,
        ch.CaseId,
        'Reopened' AS Type,
        CASE 
            WHEN c.CaseSkills LIKE '%US%' THEN 'US'
            WHEN c.CaseSkills LIKE '%General Support%' THEN '1.General Support'
            WHEN c.CaseSkills LIKE '%Financial Services%' THEN '2.Financial Services'
            WHEN c.CaseSkills LIKE '%eToro Money%' THEN '3.eToro Money'
            WHEN c.CaseSkills LIKE '%Hacked%' THEN '4.Hacked Accounts'
            WHEN c.CaseSkills LIKE '%GDPR%' THEN '5.Islamic/GDPR'
            WHEN c.CaseSkills LIKE '%Islamic%' THEN '5.Islamic/GDPR'
            WHEN c.CaseSkills LIKE '%Club Issues%' THEN '6.Club Issues'
            WHEN c.CaseSkills LIKE '%Trading Experience%' THEN '7.Trading Experience'
            WHEN c.CaseSkills LIKE '%Technical%' THEN '8.Technical'
            WHEN c.CaseSkills LIKE '%CS Marketing%' THEN '9.CS Marketing'
            ELSE 'Other'
        END AS Skill
    FROM crm.silver_crm_casehistory ch
    LEFT JOIN bi_output.bi_output_customer_customer_support_case c 
        ON c.CaseID = ch.CaseId
    WHERE ch.Field = 'Counter_Routing__c'
      AND CAST(ch.CreatedDate AS DATE) >= current_date - INTERVAL 30 DAY
      AND c.CaseOwnerTitle <> 'Admin'
      AND ch.CreatedDate > c.CreatedDate
      AND c.CaseSkills NOT LIKE '%US%'
), final as (

-- ✅ Unified Daily Dataset (All types, standardized skills)
SELECT DISTINCT 
    Day,
    CaseId,
    Type,
    Skill
FROM (
    SELECT Day, CaseId, Type, Skill FROM Chats
    UNION ALL
    SELECT Day, CaseId, Type, Skill FROM Messaging
    UNION ALL
    SELECT Day, CaseId, Type, Skill FROM Cases
    UNION ALL
    SELECT Day, CaseId, Type, Skill FROM Reopened
)
where Skill <>'Other'
and Skill <> 'US')

select f.*,c.Origin,c.Sub_Type,c.Sub_Type_2, CaseSkills,Status,cast(ClosedDate as date) as ClosedDate,NumberofTouches,Country from final f
left join bi_output.bi_output_customer_customer_support_case c on f.CaseId = c.CaseId