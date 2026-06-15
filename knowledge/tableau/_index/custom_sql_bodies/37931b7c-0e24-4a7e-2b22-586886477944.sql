with cases as (
SELECT DISTINCT 
Field,
        CASE 
            WHEN ch.OldValue LIKE '%US%' THEN 'US'
            WHEN ch.OldValue LIKE '%General Support%' THEN 'General Support'
            WHEN ch.OldValue LIKE '%Financial Services%' THEN 'Financial Services'
            WHEN ch.OldValue LIKE '%eToro Money%' THEN 'eToro Money'
            WHEN ch.OldValue LIKE '%Hacked%' THEN 'Hacked Accounts'
            WHEN ch.OldValue LIKE '%GDPR%' THEN 'Islamic/GDPR'
            WHEN ch.OldValue LIKE '%Islamic%' THEN 'Islamic/GDPR'
            WHEN ch.OldValue LIKE '%Trading Experience%' THEN 'Trading Experience'
            WHEN ch.OldValue LIKE '%Technical%' THEN 'Technical'
            WHEN ch.OldValue LIKE '%CS Marketing%' THEN 'CS Marketing'
        END AS PreviousSkill,
          CASE 
            WHEN ch.NewValue LIKE '%Cashout%' THEN 'Cashout'
            WHEN ch.NewValue LIKE '%Deposit%' THEN 'Deposit'
            WHEN ch.NewValue LIKE '%Risk%' THEN 'FCMU'
            WHEN ch.NewValue LIKE '%FCMU%' THEN 'FCMU'
            WHEN ch.NewValue LIKE '%Corporate%' THEN 'Corporate'
            WHEN ch.NewValue LIKE '%Verification%' THEN 'KYC'
            WHEN ch.NewValue LIKE '%Screening%' THEN 'KYC' end as NewSkill,
        CAST(ch.CreatedDate AS DATE) AS CreatedDate,
        c.ServiceLanguage,
        c.Country,
        ch.CaseId,
c.CreatedDate as OpenedDate,
c.ClosedDate as ClosedDate,
c.Sub_Type
    FROM crm.silver_crm_casehistory ch
    LEFT JOIN bi_output.bi_output_customer_customer_support_case c 
        ON c.CaseID = ch.CaseId
    and YEAR(ch.CreatedDate)>=2024
    --    AND CAST(ch.CreatedDate AS DATE) >='2024-01-01'
) select * from cases where PreviousSkill is not null and NewSkill is not null