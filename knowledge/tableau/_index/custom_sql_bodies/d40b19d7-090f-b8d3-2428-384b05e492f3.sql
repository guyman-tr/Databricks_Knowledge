SELECT 
case  when
CaseSkills like '%Verification%' then 'Verification' 
when CaseSkills like '%Screening%' then 'Screening'
when CaseSkills like '%FCMU%' then 'FCMU'
when CaseSkills like '%Risk%' then 'FCMU'
when CaseSkills like '%Cashout%' then 'Cashout'
when CaseSkills like '%Deposit%' then 'Deposit'
when CaseSkills like '%Affiliate%' then 'Affiliate'
end as Type

 , count(CaseNumber) as Backlog from bi_output.bi_output_customer_customer_support_case c
where Status in ('In Routing','Open','New')
and (CaseSkills like '%Verification%' or CaseSkills like '%Screening%'or CaseSkills like '%FCMU%' or CaseSkills like '%Risk%'or CaseSkills like '%Cashout%'  or CaseSkills like '%Deposit%'  or CaseSkills like '%Affiliate%' )
group by 
case  when
CaseSkills like '%Verification%' then 'Verification' 
when CaseSkills like '%Screening%' then 'Screening'
when CaseSkills like '%FCMU%' then 'FCMU'
when CaseSkills like '%Risk%' then 'FCMU'
when CaseSkills like '%Cashout%' then 'Cashout'
when CaseSkills like '%Deposit%' then 'Deposit'
when CaseSkills like '%Affiliate%' then 'Affiliate'
end