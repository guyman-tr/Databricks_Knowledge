SELECT DISTINCT 
        CASE 
            WHEN c.CaseSkills LIKE '%Cashout%' THEN 'Cashout'
            WHEN c.CaseSkills LIKE '%Deposit%' THEN 'Deposit'
            WHEN c.CaseSkills LIKE '%Screening%' THEN 'KYC-Screening'
            WHEN c.CaseSkills LIKE '%Verification%' THEN 'KYC-Verification'
            WHEN c.CaseSkills LIKE '%Corporate%' THEN 'Corporate'
            WHEN c.CaseSkills LIKE '%Risk%' THEN 'Risk'     
        END AS Skill,
        CAST(ch.CreatedDate AS DATE) AS CreatedDate,
        ch.CaseId
    FROM crm.silver_crm_casehistory ch
    LEFT JOIN bi_output.bi_output_customer_customer_support_case c 
        ON c.CaseID = ch.CaseId
    WHERE Field = 'Counter_Routing__c' 
        AND year (ch.CreatedDate) >=2024
        AND c.CaseOwnerTitle <> 'Admin'
        AND c.CaseSkills NOT LIKE '%US%'
        AND ch.CreatedDate > c.CreatedDate