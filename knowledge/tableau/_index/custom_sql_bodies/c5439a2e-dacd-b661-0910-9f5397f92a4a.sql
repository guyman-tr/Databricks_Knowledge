SELECT mdt.TxLocalDate
      ,mdt.CountryTxDate
	  ,mdt.ClubTxDate
	  ,mdt.TxType
	  ,mdt.MoneyMoveDirection
	  ,mdt.TxStatus
	  ,mdt.TransactionID
	  ,mdt.AccountID
	  ,mdt.USDAmountApprox
FROM eMoney.dbo.eMoney_Dim_Transaction mdt WITH(NOLOCK)
WHERE mdt.IsValidETM = 1
      AND mdt.TxLocalDateID >= 20210401