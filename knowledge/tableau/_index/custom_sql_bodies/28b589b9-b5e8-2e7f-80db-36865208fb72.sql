SELECT
	bw.CID,
	bw.RequestDate,
	bw.ModificationDate AS ModificationDateWD,
	wtf.ModificationDate AS ModificationDateWDPId,
	DATEDIFF(HOUR,wtf.ModificationDate,GETDATE()) TimeSinceStatusInHr,
	bw.WithdrawID,
	wtf.ID AS WDPId,
	bw.FundingTypeID,
	ft.Name AS FundingType,
	bw.Comment,
	cs.Name AS CashoutStatus,
	cs1.Name AS CashoutStatusWPId,
	pl.Name AS PlayerLevel,
	bw.Amount AS Amount$,
	c.Abbreviation AS ProcessCurrency,
	wtf.ExchangeRate,
	bw.Amount/wtf.ExchangeRate AS AmountInProcessCurrency
FROM [AZR-W-REAL-DB-2-BIDBUser].etoro.Billing.Withdraw bw
JOIN [AZR-W-REAL-DB-2-BIDBUser].etoro.Dictionary.FundingType ft ON ft.FundingTypeID=bw.FundingTypeID
LEFT JOIN [AZR-W-REAL-DB-2-BIDBUser].etoro.Billing.vWithdrawToFunding wtf on wtf.WithdrawID=bw.WithdrawID
LEFT JOIN DWH.dbo.Dim_CashoutStatus cs ON cs.CashoutStatusID=bw.CashoutStatusID
LEFT JOIN DWH.dbo.Dim_CashoutStatus cs1 ON cs1.CashoutStatusID=wtf.CashoutStatusID
JOIN DWH.dbo.Dim_Customer cc ON cc.RealCID=bw.CID
LEFT JOIN  DWH.dbo.Dim_PlayerLevel pl ON pl.PlayerLevelID=cc.PlayerLevelID
LEFT JOIN  DWH.dbo.Dim_Currency c ON c.CurrencyID=wtf.ProcessCurrencyID
WHERE 

bw.FundingTypeID =33 --eToroMoney
AND 
(wtf.CashoutStatusID IN 
(
1	--Pending
,2 --InProcess
) OR bw.CashoutStatusID IN (
1 --Pending
,2	--InProcess
))
and bw.CID not in (21451770)
AND bw.Approved=1 
AND bw.Comment IN ('Auto Approval')