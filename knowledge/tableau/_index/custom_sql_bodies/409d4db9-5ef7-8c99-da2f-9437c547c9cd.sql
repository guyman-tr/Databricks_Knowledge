SELECT 
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
  
mfts.HolderAmount,  
ProviderTransactionID , mfts.LocalCurrencyDesc  AS LocalCurrency 

FROM eMoney_dbo.eMoney_Fact_Transaction_Status mfts WITH(NOLOCK)
INNER JOIN eMoney_dbo.eMoney_Dim_Account mda WITH(NOLOCK) 
ON mfts.CurrencyBalanceID = mda.CurrencyBalanceID 
AND mda.GCID_Unique_Count =1 
 AND TxStatusModificationDate >=<[Parameters].[Parameter 3]>
AND TxStatusModificationDate<=<[Parameters].[Parameter 4]>