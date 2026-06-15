SELECT 
mb.FlowID,
mfts.CID,
mfts.GCID,
mfts.TxStatus,
mda.ProviderHolderID,
mfts.ProviderCurrencyBalanceID,
mfts.HolderCurrencyDesc,
mfts.TxLocalDate  as TxExecution_date,
mfts.TxStatusModificationDate AS TxStatusDate,
mfts.AuthorizationType,
mfts.TransactionID,
mfts.TxLabel,
mfts.TxType ,
mfts.LocalAmount,
mfts.HolderCurrencyISO,
NULL AS LocalCurrency,
mfts.HolderAmount,  
 ProviderTransactionID, 
 cb.ClosingBalanceBO

FROM bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status mfts 
INNER JOIN bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account  mda  ON mfts.CurrencyBalanceID = mda.CurrencyBalanceID
  left join  main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance 
  cb on cb.CID=mfts.CID and cb.BalanceDate=mfts.TxLocalDate
left join main.billing.bronze_moneybusdb_moneybus_transactions mb on mfts.ReferenceNumber =mb.ID
WHERE 1=1
and 
          (mfts.CID = <[Parameters].[RealCID Parameter]> 
           OR mfts.GCID = <[Parameters].[GCID Parameter]>
OR mda.ProviderHolderID=<[Parameters].[HolderID Parameter]>
OR mfts.ProviderCurrencyBalanceID=<[Parameters].[CurrencyBalanceProviderID Parameter]>)