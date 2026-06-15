SELECT
        b.CID,c.GCID,
        b.PIPsCalculation, 
		a.IsInternalTransfer, a.IsTradeFromIBAN, a.MIMOAction, a.MIMOPlatform, a.Date, a.AmountUSD, a.AmountOrigCurrency, a.IsCryptoToFiat, a.Currency,
b.DepositID as ID  
    FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms a
    JOIN BI_DB_dbo.BI_DB_DepositWithdrawFee b
      ON a.TransactionID = b.DepositID
     AND a.MIMOAction = 'Deposit' 
	 -- must take only TP 
	 AND a.MIMOPlatform = 'TradingPlatform'
    JOIN eMoney_dbo.eMoney_Dim_Account c
      ON a.RealCID = c.CID
     AND c.IsValidETM = 1
     AND c.IsTestAccount = 0
     AND c.GCID_Unique_Count = 1
    WHERE a.MIMOAction = 'Deposit' 
and (a.IsInternalTransfer=1 OR a.IsTradeFromIBAN=1)
	AND b.PIPsCalculation > 0
	and a.DateID>=20240101 
	    UNION ALL
    SELECT
        b.CID,c.GCID,
        b.PIPsCalculation, a.IsInternalTransfer, a.IsTradeFromIBAN, a.MIMOAction, a.MIMOPlatform, a.Date, a.AmountUSD, a.AmountOrigCurrency, a.IsCryptoToFiat, 
		a.Currency , b.WithdrawPaymentID as ID 
    FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms a
    JOIN BI_DB_dbo.BI_DB_DepositWithdrawFee b
      ON a.TransactionID = b.WithdrawPaymentID
     AND a.MIMOAction = 'Withdraw'
	 -- must take only TP 
	 AND a.MIMOPlatform = 'TradingPlatform'
    JOIN eMoney_dbo.eMoney_Dim_Account c
      ON a.RealCID = c.CID
     AND c.IsValidETM = 1
     AND c.IsTestAccount = 0
     AND c.GCID_Unique_Count = 1
    WHERE a.MIMOAction = 'Withdraw'
and (a.IsInternalTransfer=1 OR a.IsTradeFromIBAN=1)
	AND b.PIPsCalculation > 0
		and a.DateID>=20240101