select  last_day(ProcessDate) EoM,
        tab.launch_groups,
        count(distinct tab.AccountNumber) ct_depositors,
        count(distinct tab.ACATSControlNumber) ct_deposits, 
        sum(abs(tab.Amount)) sum_deposits 
from  
(
select cast(ca.ProcessDate as date) as ProcessDate, am.OpenDDate,
        case when am.OpenDDate <='2025-03-06' then 'before 2025 launch' when am.OpenDDate >'2025-03-06' then 'since 2025-03-07' end as launch_groups,
        ca.AccountNumber, ca.ACATSControlNumber, ca.Amount, am.AccountName --concat_ws(" ", am.na)
  from main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ca 
  join main.general.bronze_sodreconciliation_apex_ext765_accountmaster am on ca.AccountNumber=am.AccountNumber
  where  ca.PayTypeCode = 'C' 
       AND EnteredBy IN ('ACH','WRD')
       and ca.RegisteredRepCode='UK1'
       --and ca.ProcessDate>='2025-03-07'
    group by cast(ca.ProcessDate as date) , am.OpenDDate, case when am.OpenDDate <='2025-03-06' then 'before 2025 launch' when am.OpenDDate >'2025-03-06' then 'since 2025-03-07' end,
        ca.AccountNumber, ca.ACATSControlNumber, ca.Amount,  am.AccountName
    --order by cast(ca.ProcessDate as date)
)tab 
group by last_day(ProcessDate),
        tab.launch_groups