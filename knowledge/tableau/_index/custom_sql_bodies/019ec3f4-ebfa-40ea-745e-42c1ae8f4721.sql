SELECT DISTINCT 
        CASE 
            WHEN c.CaseSkills LIKE '%US%' THEN 'US'
            WHEN c.CaseSkills LIKE '%General Support%' THEN 'General Support'
            WHEN c.CaseSkills LIKE '%Financial Services%' THEN 'Financial Services'
            WHEN c.CaseSkills LIKE '%eToro Money%' THEN 'eToro Money'
            WHEN c.CaseSkills LIKE '%Hacked%' THEN 'Hacked Accounts'
            WHEN c.CaseSkills LIKE '%GDPR%' THEN 'Islamic/GDPR'
            WHEN c.CaseSkills LIKE '%Islamic%' THEN 'Islamic/GDPR'
            WHEN c.CaseSkills LIKE '%Trading Experience%' THEN 'Trading Experience'
            WHEN c.CaseSkills LIKE '%Technical%' THEN 'Technical'
            WHEN c.CaseSkills LIKE '%CS Marketing%' THEN 'CS Marketing'
        END AS Skill,
        CAST(ch.CreatedDate AS DATE) AS CreatedDate,
        c.ServiceLanguage,
        c.Country,
        ch.CaseId,
c.Sub_Type
    FROM crm.silver_crm_casehistory ch
    LEFT JOIN bi_output.bi_output_customer_customer_support_case c 
        ON c.CaseID = ch.CaseId
    WHERE Field = 'Counter_Routing__c' 
    and YEAR(ch.CreatedDate)>=2024
    --    AND CAST(ch.CreatedDate AS DATE) >='2024-01-01'
        AND c.CaseOwnerTitle <> 'Admin'
        AND c.CaseSkills NOT LIKE '%US%'
        AND ch.CreatedDate > c.CreatedDate