SELECT mdt.*, d.TransactionType from eMoney_dbo.eMoney_Dim_Transaction mdt 
JOIN eMoney_dbo.eMoney_Dictionary_TransactionType d ON mdt.TxTypeID=d.TransactionTypeID
where mdt.TxTypeID IN (1,2,3,4) 
and mdt.IsValidETM=1 and mdt.IsTxSettled=1  
AND mdt.TxStatusModificationDateID>= 20240601