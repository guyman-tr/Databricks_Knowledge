SELECT mda.CID,
	mdt.TransactionID,
	mdt.TxLocalCountryNameISO,
	mdt.TxType,
	mdt.TxTypeID,
	mda.CurrencyBalanceISODesc,
	ABS(mdt.LocalAmount) AS EUR_Amount
FROM eMoney_dbo.eMoney_Dim_Account mda 
INNER JOIN eMoney_dbo.eMoney_Dim_Transaction mdt
ON mda.CID = mdt.CID AND mda.GCID_Unique_Count =1
WHERE mdt.TxStatusModificationDate >= '2024-07-01'
		AND mdt.TxStatusModificationDate < '2024-10-01'
		AND mda.IsValidETM = 1
		AND mda.IsTestAccount = 0
		AND mdt.TxTypeID IN (5,6,7,8)
		AND mdt.IsTxSettled=1	
		AND mda.CurrencyBalanceISODesc = 'EUR'