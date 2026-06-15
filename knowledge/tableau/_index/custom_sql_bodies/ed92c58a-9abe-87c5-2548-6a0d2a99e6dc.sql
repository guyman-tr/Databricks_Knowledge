SELECT Cast(mft.TransactionLocalTime as Date) AS Date,
CASE WHEN mft.TransactionType = 'Payment' THEN 'IBAN to External'
WHEN mft.TransactionType = 'PaymentReceived' THEN 'External to IBAN'
WHEN mft.TransactionType = 'Transfer' THEN 'IBAN to Trading Platform'
WHEN mft.TransactionType = 'TransferReceived' THEN 'Trading Platform to IBAN'
WHEN mft.TransactionType IN ('CardPayment', 'Contactless','OnlinePayment','CashWithdrawal') THEN 'Card Use' 
ELSE mft.TransactionType END AS TransactionTypeLabelled,
mft.TransactionType,
mft.GCID as users,
SUM(ABS(mft.HolderAmount)) AS Amount,
COUNT(DISTINCT mft.TransactionID) AS trn

       
FROM eMoney_Fact_Transactions mft
--INNER JOIN eMoney_BetaUsers mbu ON mft.GCID = mbu.GCID
WHERE mft.TransactionStatusId=2 AND Cast(mft.TransactionLocalTime as Date)>='20220117' AND mft.TransactionType IN ('CardPayment', 'Contactless','OnlinePayment')
GROUP BY Cast(mft.TransactionLocalTime as Date) ,
CASE WHEN mft.TransactionType = 'Payment' THEN 'IBAN to External'
WHEN mft.TransactionType = 'PaymentReceived' THEN 'External to IBAN'
WHEN mft.TransactionType = 'Transfer' THEN 'IBAN to Trading Platform'
WHEN mft.TransactionType = 'TransferReceived' THEN 'Trading Platform to IBAN'
WHEN mft.TransactionType IN ('CardPayment', 'Contactless','OnlinePayment','CashWithdrawal') THEN 'Card Use' 
ELSE mft.TransactionType END,
mft.TransactionType,
mft.GCID