with cases as (
SELECT DISTINCT 
Field,
        CASE 
            WHEN ch.NewValue LIKE '%General Support%' THEN 'General Support'
            WHEN ch.NewValue LIKE '%Financial Services%' THEN 'Financial Services'
            WHEN ch.NewValue LIKE '%eToro Money%' THEN 'eToro Money'
            WHEN ch.NewValue LIKE '%Hacked%' THEN 'Hacked Accounts'
            WHEN ch.NewValue LIKE '%GDPR%' THEN 'Islamic/GDPR'
            WHEN ch.NewValue LIKE '%Islamic%' THEN 'Islamic/GDPR'
            WHEN ch.NewValue LIKE '%Trading Experience%' THEN 'Trading Experience'
            WHEN ch.NewValue LIKE '%Technical%' THEN 'Technical'
            WHEN ch.NewValue LIKE '%CS Marketing%' THEN 'CS Marketing'
        END AS NewSkill,
          CASE 
            WHEN ch.OldValue LIKE '%General Support%' THEN 'General Support'
            WHEN ch.OldValue LIKE '%Financial Services%' THEN 'Financial Services'
            WHEN ch.OldValue LIKE '%eToro Money%' THEN 'eToro Money'
            WHEN ch.OldValue LIKE '%Hacked%' THEN 'Hacked Accounts'
            WHEN ch.OldValue LIKE '%GDPR%' THEN 'Islamic/GDPR'
            WHEN ch.OldValue LIKE '%Islamic%' THEN 'Islamic/GDPR'
            WHEN ch.OldValue LIKE '%Trading Experience%' THEN 'Trading Experience'
            WHEN ch.OldValue LIKE '%Technical%' THEN 'Technical'
              WHEN ch.OldValue LIKE '%CS Marketing%' THEN 'CS Marketing'
             end as PreviousSkill,
        CAST(ch.CreatedDate AS DATE) AS CreatedDate,
c.CreatedDate as OpenedDate,
c.ClosedDate,
        c.ServiceLanguage,
        c.Country,
        ch.CaseId,
c.Sub_Type
    FROM crm.silver_crm_casehistory ch
    LEFT JOIN bi_output.bi_output_customer_customer_support_case c 
        ON c.CaseID = ch.CaseId
    and YEAR(ch.CreatedDate)>=2024
    --    AND CAST(ch.CreatedDate AS DATE) >='2024-01-01'
) select * from cases where PreviousSkill is not null and NewSkill is not null and PreviousSkill <> NewSkill