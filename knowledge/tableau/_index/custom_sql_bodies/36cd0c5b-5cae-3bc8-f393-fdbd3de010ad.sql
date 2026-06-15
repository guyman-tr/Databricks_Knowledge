/*SELECT 
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
mdcis.Currency AS LocalCurrency,
mfts.HolderAmount,  
 ProviderTransactionID

FROM  eMoney.dbo.eMoney_Fact_Transaction_Status mfts WITH(NOLOCK)
JOIN eMoney.dbo.eMoney_Dim_Account mda ON mfts.CurrencyBalanceID = mda.CurrencyBalanceID
JOIN eMoney.dbo.eMoney_DictionaryCurrencyISO_Static mdcis ON mfts.LocalCurrencyISO =mdcis.CurrencyISO

*/
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
/*mdcis.Currency AS LocalCurrency,*/ NULL AS LocalCurrency,
mfts.HolderAmount,  
 ProviderTransactionID

FROM eMoney_dbo.eMoney_Fact_Transaction_Status mfts WITH(NOLOCK)
INNER JOIN eMoney_dbo.eMoney_Dim_Account mda WITH(NOLOCK) ON mfts.CurrencyBalanceID = mda.CurrencyBalanceID
/*INNER JOIN eMoney_dbo.eMoney_DictionaryCurrencyISO_Static mdcis WITH(NOLOCK) ON mfts.LocalCurrencyISO =mdcis.CurrencyISO*/
WHERE 1=1
and 
          (mfts.CID = <[Parameters].[RealCID Parameter]> 
           OR mfts.GCID = <[Parameters].[GCID Parameter]>
OR mda.ProviderHolderID=<[Parameters].[HolderID Parameter]>
OR mfts.ProviderCurrencyBalanceID=<[Parameters].[CurrencyBalanceProviderID Parameter]>)