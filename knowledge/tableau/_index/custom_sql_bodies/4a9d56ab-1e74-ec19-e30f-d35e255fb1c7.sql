SELECT
     mfts.TransactionID 
, mfts.GCID
	,mfts.TxLocalDate
	,abs(mfts.HolderAmount)HolderAmount
	,abs(mfts.AccumulatedAmount)AccumulatedAmount
	,mfts.LocalCurrencyISO
	,m.Currency
	,m.CurrencyISO
	,mfts.HolderCurrencyISO
	,mfts.HolderCurrencyDesc
	,mfts.ProviderTransactionID
, CASE WHEN mfts.HolderCurrencyISO <>mfts.LocalCurrencyISO THEN 'Non-GBP' ELSE 'GBP' END IsGBP 
,mfts.TxTypeID
,mfts.TxType 
FROM eMoney.dbo.eMoney_Fact_Transaction_Status mfts 
	 LEFT JOIN eMoney.dbo.eMoney_DictionaryCurrencyISO_Static m ON m.CurrencyISO =mfts.LocalCurrencyISO  
WHERE mfts.TxTypeID IN (1,2,3) --CardPayment,Contactless,OnlinePayment, ( CashWithdrawal not relevant also not Refund )
AND mfts.TxStatusID =2
AND mfts.IsValidCustomer =1 
AND mfts.IsValidETM =1
--AND mfts.HolderCurrencyISO<>mfts.LocalCurrencyISO  
AND mfts.CountryIDTxDate =218
AND mfts.HolderCurrencyISO =826
AND  mfts.TxLocalDateID >= '20220101'  --I took since the begining of the year
AND   mfts.TxLocalDateID <  '20230101' -- I took to end the report at the eoy 
AND mfts.HolderAmount<0  -- wetake only spent