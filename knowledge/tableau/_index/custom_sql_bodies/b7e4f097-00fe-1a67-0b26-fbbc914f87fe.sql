SELECT 
    c.CaseNumber
    ,c.CID
    ,c.WithdrawalID
    ,cast(BW.ModificationDate as date) as StatusModificationTime
    ,cast(c.CreatedDate  as date) as CreatedDate
from
    bi_output.bi_output_customer_customer_support_case c
LEFT JOIN     
    billing.bronze_etoro_billing_withdraw BW ON BW.WithdrawID=c.WithdrawalID
where
    Status in ('In Routing') 
    and (CaseSkills like '%Cashout%')
    and cast(c.CreatedDate as date) >= '2024-01-01'