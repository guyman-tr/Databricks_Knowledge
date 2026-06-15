WITH Chats AS (
    SELECT DISTINCT 
        c.Time,
        c.LiveChatTranscriptId,
        CASE 
            WHEN c.Detail LIKE '%US%' THEN 'US'
            WHEN c.Detail LIKE '%General Support%' THEN '1.General Support/FS'
            WHEN c.Detail LIKE '%Financial Services%' THEN '1.General Support/FS'
            WHEN c.Detail LIKE '%eToro Money%' THEN '2.eToro Money'
            WHEN c.Detail LIKE '%Hacked%' THEN '3.Hacked Accounts/Islamic/GDPR'
            WHEN c.Detail LIKE '%GDPR%' THEN '3.Hacked Accounts/Islamic/GDPR'
            WHEN c.Detail LIKE '%Islamic%' THEN '3.Hacked Accounts/Islamic/GDPR'
            WHEN c.Detail LIKE '%Trading Experience%' THEN '4.Trading Experience'
            WHEN c.Detail LIKE '%Technical%' THEN '5.Technical'
            WHEN c.Detail LIKE '%CS Marketing%' THEN '6.CS Marketing'
            WHEN c.Detail LIKE '%BU%' THEN '1.General Support/FS'
            WHEN c.Detail LIKE '%Global%' THEN '1.General Support/FS'
        END AS ChatSkill
    FROM crm.silver_crm_livechattranscriptevent c
    WHERE YEAR(c.Time)>= 2024
    AND c.Detail NOT LIKE '%US%'
),
GroupedChats AS (
    SELECT 
        ChatSkill, 
        COUNT(LiveChatTranscriptId) AS ChatsIncoming,
        CAST(Time AS DATE) AS IncomingDate 
    FROM Chats
    WHERE ChatSkill IS NOT NULL
    GROUP BY ChatSkill, CAST(Time AS DATE)
    ORDER BY ChatSkill ASC
),
Cases AS (
    SELECT DISTINCT 
        c.CreatedDate,
        c.CaseId,
        CASE 
            WHEN c.NewValue LIKE '%US%' THEN 'US'
            WHEN c.NewValue LIKE '%General Support%' THEN '1.General Support/FS'
            WHEN c.NewValue LIKE '%Financial Services%' THEN '1.General Support/FS'
            WHEN c.NewValue LIKE '%eToro Money%' THEN '2.eToro Money'
            WHEN c.NewValue LIKE '%Hacked%' THEN '3.Hacked Accounts/Islamic/GDPR'
            WHEN c.NewValue LIKE '%GDPR%' THEN '3.Hacked Accounts/Islamic/GDPR'
            WHEN c.NewValue LIKE '%Islamic%' THEN '3.Hacked Accounts/Islamic/GDPR'
            WHEN c.NewValue LIKE '%Trading Experience%' THEN '4.Trading Experience'
            WHEN c.NewValue LIKE '%Technical%' THEN '5.Technical'
            WHEN c.NewValue LIKE '%CS Marketing%' THEN '6.CS Marketing'
        END AS Skill
    FROM crm.silver_casehistory c
    WHERE YEAR(c.CreatedDate) >=2024
    AND c.NewValue NOT LIKE '%US%'
),
GroupedCases AS (
    SELECT 
        Skill, 
        COUNT(CaseId) AS CasesIncoming,
        CAST(CreatedDate AS DATE) AS IncomingDate 
    FROM Cases
    WHERE Skill IS NOT NULL
    GROUP BY Skill, CAST(CreatedDate AS DATE)
    ORDER BY Skill ASC
),
reopened AS (
    SELECT DISTINCT 
        CASE 
            WHEN c.CaseSkills LIKE '%US%' THEN 'US'
            WHEN c.CaseSkills LIKE '%General Support%' THEN '1.General Support/FS'
            WHEN c.CaseSkills LIKE '%Financial Services%' THEN '1.General Support/FS'
            WHEN c.CaseSkills LIKE '%eToro Money%' THEN '2.eToro Money'
            WHEN c.CaseSkills LIKE '%Hacked%' THEN '3.Hacked Accounts/Islamic/GDPR'
            WHEN c.CaseSkills LIKE '%GDPR%' THEN '3.Hacked Accounts/Islamic/GDPR'
            WHEN c.CaseSkills LIKE '%Islamic%' THEN '3.Hacked Accounts/Islamic/GDPR'
            WHEN c.CaseSkills LIKE '%Trading Experience%' THEN '4.Trading Experience'
            WHEN c.CaseSkills LIKE '%Technical%' THEN '5.Technical'
            WHEN c.CaseSkills LIKE '%CS Marketing%' THEN '6.CS Marketing'
        END AS Skill,
        CAST(ch.CreatedDate AS DATE) AS CreatedDate,
        ch.CaseId
    FROM crm.silver_crm_casehistory ch
    LEFT JOIN bi_output.bi_output_customer_customer_support_case c 
        ON c.CaseID = ch.CaseId
    WHERE Field = 'Counter_Routing__c' 
        AND YEAR(ch.CreatedDate) >=2024
        AND c.CaseOwnerTitle <> 'Admin'
        AND c.CaseSkills NOT LIKE '%US%'
        AND ch.CreatedDate > c.CreatedDate
),
GroupedReopened AS (
    SELECT 
        Skill, 
        COUNT(CaseId) AS ReopenedIncoming,
        CAST(CreatedDate AS DATE) AS IncomingDate 
    FROM reopened
    WHERE Skill IS NOT NULL
    GROUP BY Skill, CAST(CreatedDate AS DATE)
    ORDER BY Skill ASC
),
final2 as (
SELECT 
    COALESCE(g.Skill, gc.ChatSkill, gr.Skill) AS Skill,
    COALESCE(g.CasesIncoming, 0) + COALESCE(gr.ReopenedIncoming, 0) AS CasesIncoming,
    gc.ChatsIncoming,
    COALESCE(g.IncomingDate, gc.IncomingDate, gr.IncomingDate) AS IncomingDate
FROM GroupedCases g
FULL OUTER JOIN GroupedChats gc 
    ON g.Skill = gc.ChatSkill 
    AND g.IncomingDate = gc.IncomingDate
FULL OUTER JOIN GroupedReopened gr
    ON COALESCE(g.Skill, gc.ChatSkill) = gr.Skill 
    AND COALESCE(g.IncomingDate, gc.IncomingDate) = gr.IncomingDate
ORDER BY Skill ASC)
select * from final2