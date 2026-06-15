WITH Chats AS (
    SELECT DISTINCT 
        c.Time,
        c.LiveChatTranscriptId  AS SessionId,
        CASE 
            WHEN c.Detail LIKE '%Cashout%' THEN 'Cashout'
            WHEN c.Detail LIKE '%Verification%' THEN 'Verification'
            WHEN c.Detail LIKE '%Screening%' THEN 'Screening'
            WHEN c.Detail LIKE '%Deposit%' THEN 'Deposit'
            WHEN c.Detail LIKE '%FCMU%' THEN 'FCMU'
            WHEN c.Detail LIKE '%Risk%' THEN 'FCMU'
            WHEN c.Detail LIKE '%GDPR%' THEN '5.Islamic/GDPR'
            WHEN c.Detail LIKE '%Islamic%' THEN '5.Islamic/GDPR'
            WHEN c.Detail LIKE '%Trading Experience%' THEN '6.Trading Experience'
            WHEN c.Detail LIKE '%Technical%' THEN '7.Technical'
            WHEN c.Detail LIKE '%CS Marketing%' THEN '8.CS Marketing'
            WHEN c.Detail LIKE '%BU%' THEN '1.General Support'
            WHEN c.Detail LIKE '%Global%' THEN '1.General Support'
        END AS ChatSkill
    FROM crm.silver_crm_livechattranscriptevent c
    WHERE YEAR(c.Time) >= 2024
      AND c.Detail NOT LIKE '%US%'
),
Asynchronous AS (
    SELECT DISTINCT 
        c.CreatedDate AS Time,
        c.MessagingSessionId AS SessionId,
        CASE 
            WHEN c.NewValue LIKE '%Cashout%' THEN 'Cashout'
            WHEN c.NewValue LIKE '%Verification%' THEN 'Verification'
            WHEN c.NewValue LIKE '%Screening%' THEN 'Screening'
            WHEN c.NewValue LIKE '%Deposit%' THEN 'Deposit'
            WHEN c.NewValue LIKE '%FCMU%' THEN 'FCMU'
            WHEN c.NewValue LIKE '%Risk%' THEN 'FCMU'
            WHEN c.NewValue LIKE '%GDPR%' THEN '5.Islamic/GDPR'
            WHEN c.NewValue LIKE '%Islamic%' THEN '5.Islamic/GDPR'
            WHEN c.NewValue LIKE '%Trading Experience%' THEN '6.Trading Experience'
            WHEN c.NewValue LIKE '%Technical%' THEN '7.Technical'
            WHEN c.NewValue LIKE '%CS Marketing%' THEN '8.CS Marketing'
            WHEN c.NewValue LIKE '%BU%' THEN '1.General Support'
            WHEN c.NewValue LIKE '%Global%' THEN '1.General Support'
        END AS ChatSkill
    FROM crm.silver_crm_messagingsessionhistory c
    WHERE YEAR(c.CreatedDate) >= 2024
), 
Combined AS (
    SELECT Time, SessionId, ChatSkill FROM Chats
    UNION ALL
    SELECT Time, SessionId, ChatSkill FROM Asynchronous
),
GroupedChats AS (
    SELECT 
        ChatSkill,
        CAST(Time AS DATE) AS IncomingDate,
        COUNT(DISTINCT SessionId) AS ChatsIncoming
    FROM Combined
    WHERE ChatSkill IS NOT NULL
    GROUP BY ChatSkill, CAST(Time AS DATE)
),
Cases AS (
    SELECT DISTINCT 
        ch.CreatedDate,
        ch.CaseId,
        c.ClubLevel,
        CASE 
            WHEN ch.NewValue LIKE '%Cashout%' THEN 'Cashout'
            WHEN ch.NewValue LIKE '%Deposit%' THEN 'Deposit'
            WHEN ch.NewValue LIKE '%Verification%' THEN 'Verification'
            WHEN ch.NewValue LIKE '%Screening%' THEN 'Screening'
            WHEN ch.NewValue LIKE '%FCMU%' THEN 'FCMU'
            WHEN ch.NewValue LIKE '%Risk%' THEN 'FCMU'
            WHEN ch.NewValue LIKE '%GDPR%' THEN '5.Islamic/GDPR'
            WHEN ch.NewValue LIKE '%Islamic%' THEN '5.Islamic/GDPR'
            WHEN ch.NewValue LIKE '%Trading Experience%' THEN '6.Trading Experience'
            WHEN ch.NewValue LIKE '%Technical%' THEN '7.Technical'
            WHEN ch.NewValue LIKE '%CS Marketing%' THEN '8.CS Marketing'
        END AS Skill
    FROM crm.silver_crm_casehistory ch
    LEFT JOIN bi_output.bi_output_customer_customer_support_case c
        ON ch.CaseId = c.CaseID
    WHERE YEAR(ch.CreatedDate) >= 2024
),
GroupedCases AS (
    SELECT 
        Skill, 
        ClubLevel,
        COUNT(DISTINCT CaseId) AS CasesIncoming,
        CAST(CreatedDate AS DATE) AS IncomingDate 
    FROM Cases
    WHERE Skill IS NOT NULL
    GROUP BY Skill, ClubLevel, CAST(CreatedDate AS DATE)
),
Reopened AS (
    SELECT DISTINCT 
        CASE 
            WHEN c.CaseSkills LIKE '%Cashout%' THEN 'Cashout'
            WHEN c.CaseSkills LIKE '%Deposit%' THEN 'Deposit'
            WHEN c.CaseSkills LIKE '%Verification%' THEN 'Verification'
            WHEN c.CaseSkills LIKE '%Screening%' THEN 'Screening'
            WHEN c.CaseSkills LIKE '%FCMU%' THEN 'FCMU'
            WHEN c.CaseSkills LIKE '%Risk%' THEN 'FCMU'
            WHEN c.CaseSkills LIKE '%GDPR%' THEN '5.Islamic/GDPR'
            WHEN c.CaseSkills LIKE '%Islamic%' THEN '5.Islamic/GDPR'
            WHEN c.CaseSkills LIKE '%Trading Experience%' THEN '6.Trading Experience'
            WHEN c.CaseSkills LIKE '%Technical%' THEN '7.Technical'
            WHEN c.CaseSkills LIKE '%CS Marketing%' THEN '8.CS Marketing'
        END AS Skill,
        CAST(ch.CreatedDate AS DATE) AS CreatedDate,
        ch.CaseId,
        c.ClubLevel
    FROM crm.silver_crm_casehistory ch
    LEFT JOIN bi_output.bi_output_customer_customer_support_case c 
        ON c.CaseID = ch.CaseId
    WHERE Field = 'Counter_Routing__c' 
      AND YEAR(ch.CreatedDate) >= 2024
      AND c.CaseOwnerTitle <> 'Admin'
      AND ch.CreatedDate > c.CreatedDate
),
GroupedReopened AS (
    SELECT 
        Skill, 
        ClubLevel,
        COUNT(CaseId) AS ReopenedIncoming,
        CAST(CreatedDate AS DATE) AS IncomingDate 
    FROM Reopened
    WHERE Skill IS NOT NULL
    GROUP BY Skill, ClubLevel, CAST(CreatedDate AS DATE)
),
Final2 AS (
    SELECT 
        COALESCE(g.Skill, gc.ChatSkill, gr.Skill) AS Skill,
        COALESCE(g.ClubLevel, gr.ClubLevel) AS ClubLevel,
        COALESCE(g.CasesIncoming, 0) + COALESCE(gr.ReopenedIncoming, 0) AS CasesIncoming,
        COALESCE(gc.ChatsIncoming, 0) AS ChatsIncoming,
        COALESCE(g.IncomingDate, gc.IncomingDate, gr.IncomingDate) AS IncomingDate
    FROM GroupedCases g
    FULL OUTER JOIN GroupedChats gc 
        ON g.Skill = gc.ChatSkill 
        AND g.IncomingDate = gc.IncomingDate
    FULL OUTER JOIN GroupedReopened gr
        ON COALESCE(g.Skill, gc.ChatSkill) = gr.Skill 
        AND COALESCE(g.IncomingDate, gc.IncomingDate) = gr.IncomingDate
        AND COALESCE(g.ClubLevel, gr.ClubLevel) = gr.ClubLevel
)
SELECT * 
FROM Final2