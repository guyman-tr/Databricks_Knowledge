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
        END AS PreviousSkill,
          CASE 
            WHEN ch.OldValue LIKE '%Cashout%' THEN 'Cashout'
            WHEN ch.OldValue LIKE '%Deposit%' THEN 'Deposit'
            WHEN ch.OldValue LIKE '%Risk%' THEN 'FCMU'
            WHEN ch.OldValue LIKE '%FCMU%' THEN 'FCMU'
            WHEN ch.OldValue LIKE '%Corporate%' THEN 'Corporate'
            WHEN ch.OldValue LIKE '%Verification%' THEN 'KYC'
            WHEN ch.OldValue LIKE '%Screening%' THEN 'KYC' end as NewSkill,
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
) select * from cases where PreviousSkill is not null and NewSkill is not null