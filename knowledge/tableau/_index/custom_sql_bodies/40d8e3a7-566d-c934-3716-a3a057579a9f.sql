SELECT bddwf.DateID
	 , bddwf.CID
	 , bddwf.DepositWithdrawID
	 , bddwf.Occurred
	 , bddwf.CreditTypeID
	 , bddwf.TransactionID
	 , bddwf.Date
	 , bddwf.Customer
	 , bddwf.TransactionType
	 , bddwf.PaymentMethod
	 , bddwf.Amount
	 , bddwf.Currency
	 , bddwf.ExchangeRate
	 , bddwf.AmountUSD
	 , bddwf.RegulationID
	 , bddwf.LabelID
	 , bddwf.PlayerLevelID
	 , bddwf.Regulation
	 , bddwf.[Label]
	 , bddwf.IsValidCustomer
	 , bddwf.UpdateDate
	 , bddwf.BaseExchangeRate
	 , bddwf.ExchangeFee
	 , CASE WHEN bddwf.TransactionType = 'Deposit' THEN bddwf.ExternalTransactionID END AS ExternalTransactionID
	 , CASE WHEN bddwf.TransactionType = 'Withdraw' THEN bddwf.ExternalTransactionID END AS VerificationCode
	 , bddwf.Depot
	 , bddwf.MIDValue
	 , bddwf.Club
	 , bddwf.PlayerStatus
	 , bddwf.PIPsCalculation
	 , bddwf.RegCountry
	 , bddwf.RegCountryByIP
	 , bddwf.CardType
	 , bddwf.CardCategory
	 , bddwf.BinCountry
	 , bddwf.MOPCountry
	 , bddwf.IsGermanBaFin
	 , bddwf.IsIBANTrade
	 , 'NA' AS TransactionStatus
	 , NULL AS CreditID
        , 'NA' as PayeeName
        , NULL as RollbackCanceled
	, dgs.GuruStatusName
        , NULL as Memo
        , null as TotalRollbackAmountInUSD
        , 'NA' as MID
FROM BI_DB_dbo.BI_DB_DepositWithdrawFee bddwf
	JOIN DWH_dbo.Fact_SnapshotCustomer fsc
		ON bddwf.CID = fsc.RealCID
JOIN DWH_dbo.Dim_GuruStatus dgs
	ON fsc.GuruStatusID = dgs.GuruStatusID
WHERE bddwf.DateID BETWEEN 
	CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT) 
	AND CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)