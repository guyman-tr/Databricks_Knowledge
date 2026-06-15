WITH Chats AS (
    SELECT DISTINCT 
        CAST(c.Time AS DATE) AS Day,
        l.CaseId,
        CASE 
            WHEN c.Detail LIKE '%General Support%' OR c.Detail LIKE '%Financial Services%' 
                THEN 'General & Financial Support'
            WHEN c.Detail LIKE '%eToro Money%' OR c.Detail LIKE '%Hacked%' OR c.Detail LIKE '%Islamic%'  OR c.Detail LIKE '%Club%'
OR c.Detail LIKE '%GDPR%' 
                THEN 'Security & Compliance'
            WHEN c.Detail LIKE '%Trading Experience%' THEN 'Trading Experience'
            WHEN c.Detail LIKE '%Technical%' THEN 'Technical'
            WHEN c.Detail LIKE '%CS Marketing%' THEN 'CS Marketing'
when c.Detail LIKE '%BU%' OR c.Detail LIKE '%Global%' then  'General & Financial Support'
        END AS Skill
    FROM crm.silver_crm_livechattranscriptevent c
    LEFT JOIN crm.silver_crm_livechattranscript l ON c.LiveChatTranscriptId = l.ID
    WHERE YEAR(c.Time) >= 2024
      AND c.Detail NOT LIKE '%US%'
      AND c.Detail NOT LIKE '%Cashout%'
      AND c.Detail NOT LIKE '%Deposit%'
      AND l.CaseId IS NOT NULL
),
Cases AS (
    SELECT DISTINCT 
        CAST(c.CreatedDate AS DATE) AS Day,
        c.CaseId,
        CASE 
            WHEN c.NewValue LIKE '%General Support%' OR c.NewValue LIKE '%Financial Services%' 
                THEN 'General & Financial Support'
            WHEN c.NewValue LIKE '%eToro Money%' OR c.NewValue LIKE '%Hacked%' OR c.NewValue LIKE '%Islamic%' OR c.NewValue LIKE '%GDPR%' or c.NewValue like '%Club%'
                THEN 'Security & Compliance'
            WHEN c.NewValue LIKE '%Trading Experience%' THEN 'Trading Experience'
            WHEN c.NewValue LIKE '%Technical%' THEN 'Technical'
            WHEN c.NewValue LIKE '%CS Marketing%' THEN 'CS Marketing'
        END AS Skill
    FROM crm.silver_crm_casehistory c
    WHERE YEAR(c.CreatedDate) >= 2024
      AND c.NewValue NOT LIKE '%US%'
),
Reopened AS (
    SELECT DISTINCT 
        CAST(ch.CreatedDate AS DATE) AS Day,
        ch.CaseId,
        CASE 
            WHEN c.CaseSkills LIKE '%General Support%' OR c.CaseSkills LIKE '%Financial Services%' 
                THEN 'General & Financial Support'
            WHEN c.CaseSkills LIKE '%eToro Money%' OR c.CaseSkills LIKE '%Hacked%' OR c.CaseSkills LIKE '%Islamic%' OR c.CaseSkills LIKE '%GDPR%' 
or c.CaseSkills like '%Club%'
                THEN 'Security & Compliance'
            WHEN c.CaseSkills LIKE '%Trading Experience%' THEN 'Trading Experience'
            WHEN c.CaseSkills LIKE '%Technical%' THEN 'Technical'
            WHEN c.CaseSkills LIKE '%CS Marketing%' THEN 'CS Marketing'
        END AS Skill
    FROM crm.silver_crm_casehistory ch
    LEFT JOIN bi_output.bi_output_customer_customer_support_case c 
        ON c.CaseID = ch.CaseId
    WHERE ch.Field = 'Counter_Routing__c' 
      AND YEAR(ch.CreatedDate) >= 2024
      AND ch.CreatedDate > c.CreatedDate
      AND c.CaseOwnerTitle <> 'Admin'
      AND c.CaseSkills NOT LIKE '%US%'
)

-- Combine all sources
, Combined AS (
    SELECT Day, CaseId, Skill FROM Chats
    UNION
    SELECT Day, CaseId, Skill FROM Cases
    UNION
    SELECT Day, CaseId, Skill FROM Reopened
)

-- Final aggregation
SELECT 
    DATE_FORMAT(DATE_TRUNC('month', Day), 'yyyy-MM') AS IncomingDate,
    Skill,
    COUNT(DISTINCT CaseId) AS DistinctCases
FROM Combined
WHERE Skill IS NOT NULL
GROUP BY DATE_FORMAT(DATE_TRUNC('month', Day), 'yyyy-MM'), Skill