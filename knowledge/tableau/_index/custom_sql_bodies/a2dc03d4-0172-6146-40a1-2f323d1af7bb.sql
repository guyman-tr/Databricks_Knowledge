----- final table ---

SELECT 
	p.*
   ,r.Revenue_Total
   ,r.Revenue_Copy
   ,r.Revenue_Real_Stocks
   ,r.Revenue_CFD_Stocks
   ,r.Revenue_Real_Crypto
   ,r.Revenue_CFD_Crypto
   ,r.[Revenue_FX/Comm/Ind]
   ,r.AmountIn_NewTrades_Total
   ,r.AmountIn_NewTrades_Copy
   ,r.AmountIn_NewTrades_Real_Stocks
   ,r.AmountIn_NewTrades_CFD_Stocks
   ,r.AmountIn_NewTrades_Real_Crypto
   ,r.AmountIn_NewTrades_CFD_Crypto
   ,r.[AmountIn_NewTrades_FX/Comm/Ind]
   ,r.Active
   ,r.Active_Copy
   ,r.Active_Real_Stocks
   ,r.Active_CFD_Stocks
   ,r.Active_Real_Crypto
   ,r.Active_CFD_Crypto
   ,r.[Active_FX/Comm/Ind]

   ,r1.Avg_RE_sinceJan24
   ,r1.Max_RE_sinceJan24
   ,r1.Min_RE_sinceJan24
   ,r1.std_dev
   ,r1.[Is_MinRE>=$10K_sinceJan24]
   ,r1.[Is_MinRE>=$15K_sinceJan24]
   ,r1.[Is_MinRE>=$20K_sinceJan24]
   ,r1.[Is_MinRE>=$25K_sinceJan24]

   ,m.Deposit_Count
   ,m.Deposit_Amount
   ,m.Cashout_Count
   ,m.Cashout_Amount
   ,m.NetDeposit_Amount
FROM
	#pop p
	LEFT JOIN #rev r ON p.RealCID = r.RealCID
	LEFT JOIN #RE r1 ON p.RealCID = r1.RealCID
	LEFT JOIN #MIMO m ON p.RealCID = m.RealCID