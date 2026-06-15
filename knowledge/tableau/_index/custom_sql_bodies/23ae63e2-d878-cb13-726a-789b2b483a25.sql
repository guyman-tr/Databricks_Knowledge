WITH PremiumChats AS (
    SELECT DISTINCT 
        l.CaseId AS ID,
        CAST(c.Time AS DATE) AS IncomingDate,
        'Chat' AS SourceType,
        CASE
            WHEN c.Detail LIKE '%General Support%' THEN '1.General Support'
            WHEN c.Detail LIKE '%Financial Services%' THEN '2.Financial Services'
            WHEN c.Detail LIKE '%eToro Money%' THEN '3.eToro Money'
            WHEN c.Detail LIKE '%Hacked%' THEN '4.Hacked Accounts'
            WHEN c.Detail LIKE '%GDPR%' THEN '5.Islamic/GDPR'
            WHEN c.Detail LIKE '%Islamic%' THEN '5.Islamic/GDPR'
            WHEN c.Detail LIKE '%Trading Experience%' THEN '6.Trading Experience'
            WHEN c.Detail LIKE '%Technical%' THEN '7.Technical'
            WHEN c.Detail LIKE '%Club%' THEN '9.Club Issues'
            WHEN c.Detail LIKE '%CS Marketing%' THEN '8.CS Marketing'
            WHEN c.Detail LIKE '%BU%' THEN '1.General Support'
            WHEN c.Detail LIKE '%Global%' THEN '1.General Support'
            ELSE NULL
        END AS Skill
    FROM crm.silver_crm_livechattranscriptevent c
    LEFT JOIN crm.silver_crm_livechattranscript l ON l.ID = LiveChatTranscriptId
    WHERE CAST(c.Time AS DATE) BETWEEN DATE_SUB(CURRENT_DATE(), 180) AND CURRENT_DATE()
      AND c.Detail LIKE '%Premium%'
      AND c.Detail NOT LIKE '%US%'
      AND c.Detail NOT LIKE '%Cashout%'
      AND c.Detail NOT LIKE '%Deposit%'
      AND c.Detail NOT LIKE '%FATCA%'
      AND c.Detail NOT LIKE '%Tax%'
      AND c.Detail NOT LIKE '%Risk%'
      AND c.Detail NOT LIKE '%FCMU%'
      AND c.Detail NOT LIKE '%Verification%'
      AND c.Detail NOT LIKE '%Screening%'
),

PremiumCases AS (
    SELECT DISTINCT 
        c.CaseId AS ID,
        CAST(c.CreatedDate AS DATE) AS IncomingDate,
        'NewCase' AS SourceType,
        CASE
            WHEN c.NewValue LIKE '%General Support%' THEN '1.General Support'
            WHEN c.NewValue LIKE '%Financial Services%' THEN '2.Financial Services'
            WHEN c.NewValue LIKE '%eToro Money%' THEN '3.eToro Money'
            WHEN c.NewValue LIKE '%Hacked%' THEN '4.Hacked Accounts'
            WHEN c.NewValue LIKE '%GDPR%' THEN '5.Islamic/GDPR'
            WHEN c.NewValue LIKE '%Islamic%' THEN '5.Islamic/GDPR'
            WHEN c.NewValue LIKE '%Trading Experience%' THEN '6.Trading Experience'
            WHEN c.NewValue LIKE '%Technical%' THEN '7.Technical'
            WHEN c.NewValue LIKE '%CS Marketing%' THEN '8.CS Marketing'
            WHEN c.NewValue LIKE '%BU%' THEN '1.General Support'

            WHEN  c.NewValue LIKE '%Club%' THEN '9.Club Issues'
            ELSE NULL
        END AS Skill
    FROM crm.silver_crm_casehistory c
    WHERE CAST(c.CreatedDate AS DATE) BETWEEN DATE_SUB(CURRENT_DATE(), 180) AND CURRENT_DATE()
      AND c.NewValue LIKE '%Premium%'
      AND c.NewValue NOT LIKE '%US%'
      AND c.NewValue NOT LIKE '%Cashout%'
      AND c.NewValue NOT LIKE '%Deposit%'
      AND c.NewValue NOT LIKE '%FATCA%'
      AND c.NewValue NOT LIKE '%Tax%'
      AND c.NewValue NOT LIKE '%Risk%'
      AND c.NewValue NOT LIKE '%FCMU%'
      AND c.NewValue NOT LIKE '%Verification%'
      AND c.NewValue NOT LIKE '%Screening%'
),

PremiumReopened AS (
    SELECT DISTINCT 
        ch.CaseId AS ID,
        CAST(ch.CreatedDate AS DATE) AS IncomingDate,
        'Reopened' AS SourceType,
        CASE
            WHEN c.CaseSkills LIKE '%General Support%' THEN '1.General Support'
            WHEN c.CaseSkills LIKE '%Financial Services%' THEN '2.Financial Services'
            WHEN c.CaseSkills LIKE '%eToro Money%' THEN '3.eToro Money'
            WHEN c.CaseSkills LIKE '%Hacked%' THEN '4.Hacked Accounts'
            WHEN c.CaseSkills LIKE '%GDPR%' THEN '5.Islamic/GDPR'
            WHEN c.CaseSkills LIKE '%Islamic%' THEN '5.Islamic/GDPR'
            WHEN c.CaseSkills LIKE '%Trading Experience%' THEN '6.Trading Experience'
            WHEN c.CaseSkills LIKE '%Technical%' THEN '7.Technical'
            WHEN c.CaseSkills LIKE '%CS Marketing%' THEN '8.CS Marketing'
            WHEN c.CaseSkills LIKE '%BU%' THEN '1.General Support'
 WHEN c.CaseSkills LIKE '%Club%' THEN '9.Club Issues'
            ELSE NULL
        END AS Skill
    FROM crm.silver_crm_casehistory ch
    LEFT JOIN bi_output.bi_output_customer_customer_support_case c ON ch.CaseId = c.CaseID
    WHERE ch.Field = 'Counter_Routing__c'
      AND CAST(ch.CreatedDate AS DATE) BETWEEN DATE_SUB(CURRENT_DATE(), 180) AND CURRENT_DATE()
      AND ch.CreatedDate > c.CreatedDate
      AND c.CaseOwnerTitle <> 'Admin'
      AND c.CaseSkills LIKE '%Premium%'
      AND c.CaseSkills NOT LIKE '%US%'
      AND c.CaseSkills NOT LIKE '%Cashout%'
      AND c.CaseSkills NOT LIKE '%Deposit%'
      AND c.CaseSkills NOT LIKE '%FATCA%'
      AND c.CaseSkills NOT LIKE '%Tax%'
      AND c.CaseSkills NOT LIKE '%Risk%'
      AND c.CaseSkills NOT LIKE '%FCMU%'
      AND c.CaseSkills NOT LIKE '%Verification%'
      AND c.CaseSkills NOT LIKE '%Screening%'
)

SELECT ID AS CaseID,IncomingDate, SourceType, Skill
FROM (
    SELECT * FROM PremiumChats
    UNION ALL
    SELECT * FROM PremiumCases
    UNION ALL
    SELECT * FROM PremiumReopened
) AS AllPremiumCS
WHERE Skill IS NOT NULL