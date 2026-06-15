SELECT  
	EOMONTH(w.Occurred) as Month
	,case when w.PaymentMethod = 'eToroCryptoWallet' then 'eToroCryptoWallet (C2USD)' else w.PaymentMethod end as PaymentMethod
	,w.TransactionType
	,sum(w.AmountUSD) as TotalAmountUSD
	,count(w.TransactionID) as NumOfTrx
from 
	BI_DB_dbo.BI_DB_DepositWithdrawFee w
WHERE 
	Year(w.Occurred) >= '2025'
GROUP BY 
	EOMONTH(w.Occurred)
	,case when w.PaymentMethod = 'eToroCryptoWallet' then 'eToroCryptoWallet (C2USD)' else w.PaymentMethod end
	,w.TransactionType

UNION ALL

Select 
	EOMONTH(LastModificationDate) as Month
	,'C2IBAN' as PaymentMethod
	,'Deposit' as TransactionType
	,sum(UsdAmount) as TotalAmountUSD
	,count(SentTransactionID) as NumOfTrx
FROM 
	EXW_dbo.EXW_C2F_E2E
WHERE 
	TargetPlatform = 'IbanAccount'
	and eMoneyLastTxStatus = 'Settled'
	and Year(LastModificationDate) >= '2025'
GROUP BY 
	EOMONTH(LastModificationDate)