SELECT 
    rol.Region,
    di.SellCurrency, 
    di.InstrumentType, 
    cus.AccountTypeID, 
    fca.IsSettled, 
	fca.RealCID,
	mda.CurrencyBalanceCreateDate AS eMoney_Created_Date,
    CAST(fca.Occurred AS date) AS Date_,
        SUM( case WHEN dat.ActionTypeID=44 AND fca.FundingTypeID=33 AND de.PIPsCalculation is NOT NULL THEN isnull(de.PIPsCalculation,0) end) AS Amount_Fee_Open_LC, 
		 SUM( case WHEN dat.ActionTypeID=45 AND fca.FundingTypeID=33 AND wi.PIPsCalculation is NOT NULL THEN isnull(wi.PIPsCalculation,0) end) AS Amount_Fee_close_LC   
FROM DWH_dbo.Fact_CustomerAction fca
INNER JOIN DWH_dbo.Dim_Customer cus ON fca.RealCID = cus.RealCID AND cus.IsValidCustomer=1  
INNER JOIN DWH_dbo.Dim_Instrument di ON fca.InstrumentID = di.InstrumentID 
INNER JOIN DWH_dbo.Dim_AccountType actype ON cus.AccountTypeID = actype.AccountTypeID
INNER JOIN DWH_dbo.Dim_ActionType dat ON fca.ActionTypeID = dat.ActionTypeID 
INNER JOIN eMoney_dbo.eMoney_Dim_Country_Rollout rol ON cus.CountryID = rol.CountryID
LEFT JOIN (
    SELECT * 
    FROM eMoney_dbo.eMoney_Dim_Account 
    WHERE GCID_Unique_Count = 1 AND IsValidETM = 1
) mda ON fca.RealCID = mda.CID 
LEFT JOIN BI_DB_dbo.BI_DB_DepositWithdrawFee wi ON fca.WithdrawID = CAST(left(wi.TransactionID, len(wi.TransactionID)-1) as INT) 
and wi.TransactionType = 'Withdraw'
left JOIN BI_DB_dbo.BI_DB_DepositWithdrawFee de ON fca.DepositID = CAST(left(de.TransactionID, len(de.TransactionID)-1) as INT) 
and de.TransactionType = 'Deposit'
WHERE fca.Occurred >= '2024-04-01'
AND    (fca.ActionTypeID IN (44,45) AND fca.FundingTypeID=33)      
   GROUP BY 
    fca.RealCID,
     CAST(fca.Occurred AS date), 
    rol.Region,
   fca.IsSettled,  
    di.SellCurrency, 
    di.InstrumentType, 
    cus.AccountTypeID,   
    mda.CurrencyBalanceCreateDate