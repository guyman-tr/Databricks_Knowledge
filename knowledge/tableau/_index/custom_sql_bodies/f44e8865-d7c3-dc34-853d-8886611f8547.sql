SELECT  		
  efrbn.BalanceDate		
, efrbn.GCID		
, efrbn.RealCID		
, efrbn.Regulation		
, efrbn.Country		
, efrbn.CryptoID		
, efrbn.CryptoName		
, efrbn.PublicAddress		
, efrbn.Balance		
, efrbn.BalanceUSD BalanceUSDApproximated		
, efrbn.UserWalletAllowance		
, efrbn.PlayerStatus
, WalletEntity		
FROM EXW_dbo.EXW_FinanceReportsBalancesNew efrbn		
WHERE efrbn.WalletEntity ='eToroME'		
AND efrbn.BalanceDateID = CAST(CONVERT(varchar(8), cast(<[Parameters].[Parameter 1]> as date), 112) AS int)


AND efrbn.AMLClosureEvent =0
AND Rate<>0		
AND efrbn.IsTestAccount =0