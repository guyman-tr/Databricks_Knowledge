select dt.CID
      ,dt.TxStatusModificationDate
      ,st.Mcc 
      ,st.MerchantName
      ,dt.MerchantID
      ,dt.HolderAmount
      ,st.TransactionId
from eMoney_dbo.eMoney_Dim_Transaction dt
join #SettlementsTransactions st 
on dt.ProviderTransactionID=st.TransactionId
AND dt.ProviderCurrencyBalanceID=st.AccountId
join eMoney_dbo.eMoney_Dim_Account da
on dt.CID=da.CID
WHERE da.IsValidETM=1
AND da.IsValidCustomer=1
and da.IsTestAccount=0
AND da.GCID_Unique_Count=1
AND dt.IsTxSettled=1
and dt.TxTypeID in (1,2,3,4)
and dt.TxStatusID in (1,2) 
and dt.TxStatusModificationDate>='2025-07-01'