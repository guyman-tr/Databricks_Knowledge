Select 
t.TxLabel
,cast(t.TxCreatedDate   as date) as TxCreatedDate
,t.TxStatus
,t.TxType
,count(t.TransactionID)as totaltrx
,sum(case when t.txStatus = 'Settled' then 1 else 0 end) as totalsettledtrx
,sum(t.USDAmountApprox)as totalUSD
from 
  main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction t
where 
	t.TxCreatedDate BETWEEN date_add(current_date(), -90) AND current_date()
  and t.MoneyMoveDirection = 'MoneyOut'
  and t.TxLabel <> 'eToro Trading Platform DPT'
  and t.IsValidCustomer = 1
  and t.IsValidETM = 1
GROUP BY 
  t.TxLabel
  ,cast(t.TxCreatedDate   as date)
  ,t.TxStatus
  ,t.TxType