SELECT CAST(GETDATE() AS DATE) AS LoadDate,FullDate 'Date',Year_Month,InstrumentType,[Real/CFD],AUA 'Amount'
FROM #AUAPositionPnL1
UNION ALL 
SELECT CAST(GETDATE() AS DATE) AS LoadDate,FullDate, Year_Month, 'InProcessCashouts' AS InstrumentType,' ' 'Real/CFD', InProcessCashouts AS Amount
FROM #InProcessCashouts
UNION ALL 
SELECT CAST(GETDATE() AS DATE) AS LoadDate,FullDate, Year_Month, 'CashBalances' AS InstrumentType,' ' 'Real/CFD', CashBalances AS Amount
FROM #InProcessCashouts
UNION ALL 
SELECT CAST(GETDATE() AS DATE) AS LoadDate,BalanceDate,Year_Month,'eMoney_BalanceUSD' InstrumentType,' ' 'Real/CFD',eMoney_BalanceUSD
FROM #eMoney_Balance mb
UNION ALL 
SELECT CAST(GETDATE() AS DATE) AS LoadDate,BalanceDate,Year_Month,'Crypto_Wallets_USD'InstrumentType,' ' 'Real/CFD' ,Crypto_Wallets_USD
FROM #Crypto_Wallets cw