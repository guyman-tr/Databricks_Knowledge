WITH Cases AS (
    SELECT DISTINCT 
        c.CreatedDate,
        c.CaseId,
        CASE 
            WHEN c.NewValue LIKE '%Cashout%' THEN 'Cashout'
            WHEN c.NewValue LIKE '%Deposit%' THEN 'Deposit'
            WHEN c.NewValue LIKE '%Screening%' THEN 'KYC-Screening'
            WHEN c.NewValue LIKE '%Verification%' THEN 'KYC-Verification'
            WHEN c.NewValue LIKE '%Corporate%' THEN 'Corporate'
            WHEN c.NewValue LIKE '%Risk%' THEN 'Risk'     
        END AS Skill
    FROM crm.silver_crm_casehistory c
    WHERE YEAR(c.CreatedDate) >= 2024
),
GroupedCases AS (
    SELECT 
        Skill, 
        COUNT(DISTINCT CaseId) AS CasesIncoming,
        CAST(CreatedDate AS DATE) AS IncomingDate 
    FROM Cases
    WHERE Skill IS NOT NULL
    GROUP BY Skill, CAST(CreatedDate AS DATE)
)
SELECT * FROM GroupedCases