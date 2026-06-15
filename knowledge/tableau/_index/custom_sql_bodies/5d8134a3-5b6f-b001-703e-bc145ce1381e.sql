with cases as (
SELECT DISTINCT 
Field,
          CASE 
            WHEN ch.NewValue LIKE '%Cashout%' THEN 'Cashout'
            WHEN ch.NewValue LIKE '%Deposit%' THEN 'Deposit'
            WHEN ch.NewValue LIKE '%Risk%' THEN 'FCMU'
            WHEN ch.NewValue LIKE '%FCMU%' THEN 'FCMU'
            WHEN ch.NewValue LIKE '%Corporate%' THEN 'Corporate'
            WHEN ch.NewValue LIKE '%Verification%' THEN 'KYC'
            WHEN ch.NewValue LIKE '%Screening%' THEN 'KYC' end as NewSkill,
           CASE 
            WHEN ch.OldValue LIKE '%Cashout%' THEN 'Cashout'
            WHEN ch.OldValue LIKE '%Deposit%' THEN 'Deposit'
            WHEN ch.OldValue LIKE '%Risk%' THEN 'FCMU'
            WHEN ch.OldValue LIKE '%FCMU%' THEN 'FCMU'
            WHEN ch.OldValue LIKE '%Corporate%' THEN 'Corporate'
            WHEN ch.OldValue LIKE '%Verification%' THEN 'KYC'
            WHEN ch.OldValue LIKE '%Screening%' THEN 'KYC' end as PreviousSkill,
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