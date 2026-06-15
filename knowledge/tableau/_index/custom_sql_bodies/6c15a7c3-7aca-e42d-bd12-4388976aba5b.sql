SELECT 

mft.StatusModificationTime,

mft.TransactionType,
(CASE WHEN mft.TransactionType = 'Payment' THEN 'IBAN to External'
WHEN mft.TransactionType = 'PaymentReceived' THEN 'External to IBAN'
WHEN mft.TransactionType = 'Transfer' THEN 'IBAN to Trading Platform'
WHEN mft.TransactionType = 'TransferReceived' THEN 'Trading Platform to IBAN'
WHEN mft.TransactionType IN ('CardPayment', 'Contactless',
'OnlinePayment',
'CashWithdrawal') THEN 'Card Use' 
ELSE TransactionType END) AS TransactionTypeLabelled,
SUM(CASE WHEN mft.HolderAmount>0 THEN mft.HolderAmount ELSE NULL end) AS Amount_Positive,
SUM(CASE WHEN mft.HolderAmount<0 THEN mft.HolderAmount ELSE NULL end) AS Amount_Negative,
COUNT(mft.TransactionID) AS tx,
mft.GCID,
sum(ABS(mft.HolderAmount)) as Amount
FROM eMoney_Fact_Transactions mft
LEFT JOIN eMoney_TestUsers mtu ON mft.GCID = mtu.GCID
inner join DWH.. Dim_Customer dc on dc.GCID=mft.GCID 
WHERE mft.TransactionStatusId=2 AND cast(mft.TransactionLocalTime AS DATE)>='2022-01-01'
and dc.PlayerLevelID<>4 and TXStatusCBRelevant=1
GROUP BY 
mft.StatusModificationTime,
mft.GCID,
mft.TransactionType,
(CASE WHEN mft.TransactionType = 'Payment' THEN 'IBAN to External'
WHEN mft.TransactionType = 'PaymentReceived' THEN 'External to IBAN'
WHEN mft.TransactionType = 'Transfer' THEN 'IBAN to Trading Platform'
WHEN mft.TransactionType = 'TransferReceived' THEN 'Trading Platform to IBAN'
WHEN mft.TransactionType IN ('CardPayment', 'Contactless',
'OnlinePayment',
'CashWithdrawal') THEN 'Card Use' 
ELSE TransactionType END)