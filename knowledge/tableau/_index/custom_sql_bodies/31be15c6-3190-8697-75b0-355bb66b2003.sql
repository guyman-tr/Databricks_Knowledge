with Cases AS (
    SELECT DISTINCT 
        c.CreatedDate,
        c.CaseId,
     
        CASE 
            WHEN c.NewValue LIKE '%US%' THEN 'US'
            WHEN c.NewValue LIKE '%General Support%' THEN 'General Support'
            WHEN c.NewValue LIKE '%Financial Services%' THEN 'Financial Services'
            WHEN c.NewValue LIKE '%eToro Money%' THEN 'eToro Money'
            WHEN c.NewValue LIKE '%Hacked%' THEN 'Hacked Accounts'
            WHEN c.NewValue LIKE '%GDPR%' THEN 'Islamic/GDPR'
            WHEN c.NewValue LIKE '%Islamic%' THEN 'Islamic/GDPR'
            WHEN c.NewValue LIKE '%Trading Experience%' THEN 'Trading Experience'
            WHEN c.NewValue LIKE '%Technical%' THEN 'Technical'
            WHEN c.NewValue LIKE '%CS Marketing%' THEN 'CS Marketing'
        END AS Skill,
        ServiceLanguage,
        Sub_Type,
        Initial_Sub_Type,
    Sub_Type_2,
        Country
    FROM crm.silver_crm_casehistory c
    left join bi_output.bi_output_customer_customer_support_case cc on cc.CaseId = c.CaseId
    WHERE 
    YEAR(c.CreatedDate) >=2024
   --  cast(c.CreatedDate as date)='2024-11-05' 
    AND c.NewValue NOT LIKE '%US%'
)
    SELECT 
        Skill, 
        COUNT(distinct CaseId) AS CasesIncoming,
            ServiceLanguage,
        Country,
        CAST(CreatedDate AS DATE) AS IncomingDate,
       Sub_Type,
        Initial_Sub_Type,
    Sub_Type_2
    FROM Cases
    WHERE Skill IS NOT NULL
    GROUP BY Skill, 
    ServiceLanguage,
       Country, 
   Sub_Type,
        Initial_Sub_Type,
    Sub_Type_2,
        CAST(CreatedDate AS DATE)