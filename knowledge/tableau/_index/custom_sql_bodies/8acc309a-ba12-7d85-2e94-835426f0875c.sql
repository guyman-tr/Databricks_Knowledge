SELECT last_day(tab.ProcessDate) EoM, 
        launch_groups,
        count(distinct tab.AccountNumber) ct_traders,
        count(distinct tab.OrderID) ct_trades,
        sum(abs(quantity)) sum_contracts, sum(abs(tab.NetAmount)) sum_invested_principal
FROM 
(
select cast(tr.ProcessDate as date) ProcessDate, 
        case when am.OpenDDate <='2025-03-06' then 'before 2025 launch' else 'since 2025-03-07' end as launch_groups,
        --BuySellCode,
        tr.AccountNumber, tr.OrderID, tr.ExecutionTime, tr.quantity, tr.NetAmount
  from main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity tr 
  join main.general.bronze_sodreconciliation_apex_ext765_accountmaster am on tr.AccountNumber=am.AccountNumber
  where tr.RegisteredRepCode='UK1'
    and BuySellCode='B'
    group by cast(tr.ProcessDate as date) , case when am.OpenDDate <='2025-03-06' then 'before 2025 launch' else 'since 2025-03-07' end,
    tr.AccountNumber, tr.OrderID, tr.ExecutionTime, tr.quantity, tr.NetAmount
)tab 
GROUP BY last_day(tab.ProcessDate), launch_groups
ORDER BY last_day(tab.ProcessDate)