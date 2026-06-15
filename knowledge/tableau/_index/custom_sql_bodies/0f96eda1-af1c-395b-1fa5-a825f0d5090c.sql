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
FROM BI_DB_dbo.External_etoro_Billing_Withdraw bw
JOIN DWH_dbo.Dim_FundingType ft ON ft.FundingTypeID=bw.FundingTypeID

LEFT JOIN [BI_DB_dbo].[External_etoro_Billing_vWithdrawToFunding] wtf on wtf.WithdrawID=bw.WithdrawID
LEFT JOIN [BI_DB_dbo].[External_etoro_Billing_Funding] funding on funding.FundingID=wtf.FundingID
LEFT JOIN DWH_dbo.Dim_CashoutStatus cs ON cs.CashoutStatusID=bw.CashoutStatusID
LEFT JOIN  DWH_dbo.Dim_CashoutStatus cs1 ON cs1.CashoutStatusID=wtf.CashoutStatusID
JOIN DWH_dbo.Dim_Customer cc ON cc.RealCID=bw.CID
LEFT JOIN DWH_dbo.Dim_PlayerLevel pl ON pl.PlayerLevelID=cc.PlayerLevelID
LEFT JOIN DWH_dbo.Dim_Currency c ON c.CurrencyID=wtf.ProcessCurrencyID
WHERE 

(bw.FundingTypeID =33  OR funding.FundingTypeID=33)--eToroMoney
AND ((wtf.CashoutStatusID IN (
9, ---PendingByProvider
10, --SentToProvider
11, --SentToBilling
12, --ReceivedByBilling
8 --RejectedbYProvider
) and bw.CashoutStatusID=2)
)
and bw.CID not in (21451770)