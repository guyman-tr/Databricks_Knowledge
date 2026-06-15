WITH Chats AS (
    SELECT DISTINCT 
        c.Time,
        c.LiveChatTranscriptId,
        CASE 
            WHEN c.Detail LIKE '%General Support%' OR c.Detail LIKE '%Financial Services%' 
                 OR c.Detail LIKE '%BU%' OR c.Detail LIKE '%Global%' 
                THEN 'General & Financial Support'
            WHEN c.Detail LIKE '%eToro Money%' OR c.Detail LIKE '%Hacked%' 
                 OR c.Detail LIKE '%Islamic%' OR c.Detail LIKE '%GDPR%' 
                THEN 'Security & Compliance'
            WHEN c.Detail LIKE '%Trading Experience%' THEN 'Trading Experience'
            WHEN c.Detail LIKE '%Technical%' THEN 'Technical'
            WHEN c.Detail LIKE '%CS Marketing%' THEN 'CS Marketing'
        END AS ChatSkill
    FROM crm.silver_crm_livechattranscriptevent c
    WHERE YEAR(c.Time) >= 2024
      AND c.Detail NOT LIKE '%US%'
      AND c.Detail NOT LIKE '%Cashout%'
      AND c.Detail NOT LIKE '%Deposit%'
),
GroupedChats AS (
    SELECT 
        ChatSkill, 
        COUNT(DISTINCT LiveChatTranscriptId) AS ChatsIncoming,
        CAST(Time AS DATE) AS IncomingDate 
    FROM Chats
    WHERE ChatSkill IS NOT NULL
    GROUP BY ChatSkill, CAST(Time AS DATE)
),
Cases AS (
    SELECT DISTINCT 
        c.CreatedDate,
        c.CaseId,
        CASE 
            WHEN c.NewValue LIKE '%General Support%' OR c.NewValue LIKE '%Financial Services%' 
                THEN 'General & Financial Support'
            WHEN c.NewValue LIKE '%eToro Money%' OR c.NewValue LIKE '%Hacked%' 
                 OR c.NewValue LIKE '%Islamic%' OR c.NewValue LIKE '%GDPR%' 
                THEN 'Security & Compliance'
            WHEN c.NewValue LIKE '%Trading Experience%' THEN 'Trading Experience'
            WHEN c.NewValue LIKE '%Technical%' THEN 'Technical'
            WHEN c.NewValue LIKE '%CS Marketing%' THEN 'CS Marketing'
        END AS Skill
    FROM crm.silver_crm_casehistory c
    WHERE YEAR(c.CreatedDate) >= 2024
      AND c.NewValue NOT LIKE '%US%'
),
GroupedCases AS (
    SELECT 
        Skill, 
        COUNT(DISTINCT CaseId) AS CasesIncoming,
        CAST(CreatedDate AS DATE) AS IncomingDate 
    FROM Cases
    WHERE Skill IS NOT NULL
    GROUP BY Skill, CAST(CreatedDate AS DATE)
),
reopened AS (
    SELECT DISTINCT 
        CASE 
            WHEN c.CaseSkills LIKE '%General Support%' OR c.CaseSkills LIKE '%Financial Services%' 
                THEN 'General & Financial Support'
            WHEN c.CaseSkills LIKE '%eToro Money%' OR c.CaseSkills LIKE '%Hacked%' 
                 OR c.CaseSkills LIKE '%Islamic%' OR c.CaseSkills LIKE '%GDPR%' 
                THEN 'Security & Compliance'
            WHEN c.CaseSkills LIKE '%Trading Experience%' THEN 'Trading Experience'
            WHEN c.CaseSkills LIKE '%Technical%' THEN 'Technical'
            WHEN c.CaseSkills LIKE '%CS Marketing%' THEN 'CS Marketing'
        END AS Skill,
        CAST(ch.CreatedDate AS DATE) AS CreatedDate,
        ch.CaseId
    FROM crm.silver_crm_casehistory ch
    LEFT JOIN bi_output.bi_output_customer_customer_support_case c 
        ON c.CaseID = ch.CaseId
    WHERE Field = 'Counter_Routing__c' 
      AND YEAR(ch.CreatedDate) >= 2024
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
),
final2 AS (
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
)
SELECT * FROM final2