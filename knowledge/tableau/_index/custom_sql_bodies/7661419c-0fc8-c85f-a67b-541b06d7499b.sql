--Reimbursement Report -follow up
select 
		isnull(eccc.[Current Coin Balance],0) AS Balance,
		isnull(eccc.[Current Coin Balance],0) AS BalanceAmountDivAdjustments,
		case WHEN isnull(eccc.[Current Coin Balance],0) * isnull(x.EOD_Price,0) > 10 THEN 'Over 10' ELSE 'Under 10' end AS Indicator,
		isnull(eccc.[Current Coin Balance],0) * isnull(x.EOD_Price,0) AS CurrentValue,
		CompensationDate,
		isnull(x.EOD_Price,0) AS EOD_Bid_Prce,
		'Close Wallets' AS AccountName,
		'Close Wallets' AS SourceName,
		null AS SubAccountName,
		Null AS CoinAssetCodeCalc,
		0 AS PendingRewardsAmount,
		eccc.CryptoName,
		eccc.UserWalletAllowance


FROM EXW_dbo.EXW_ReimbursementFollowUp eccc
LEFT JOIN EXW_dbo.EXW_WalletEntity ewe
ON eccc.GCID = ewe.GCID
AND CompensationDate =ewe.Date
LEFT JOIN EXW_dbo.EXW_WalletEntity ewe2
ON eccc.GCID = ewe2.GCID
AND ewe2.Date =(SELECT max(Date) FROM EXW_dbo.EXW_WalletEntity)
left JOIN 
(SELECT bdcn.InstrumentName,Max(bdcn.EOD_Bid_Price) AS EOD_Price,bdcn.Date  from BI_DB_dbo.BI_DB_Crypto_NOP bdcn
WHERE bdcn.InstrumentName LIKE '%/USD' and bdcn.Date = <[Parameters].[Parameter 1]> 
GROUP BY bdcn.InstrumentName,bdcn.Date)  x
ON x.InstrumentName = CONCAT(CryptoName, '/USD')
WHERE 1=1
AND CompensationDate IS NOT NULL
AND [Reimbursement Coin Balance] >0
AND (
(eccc.Project LIKE 'AML%' AND LOWER(eccc.AMLStatus) IN ( 'compensated','reimbursed', 'completed'))
OR eccc.Project NOT LIKE 'AML%')
AND eccc.CompensationDate <= <[Parameters].[Parameter 1]>
union ALL 

--QA
SELECT * FROM (
SELECT TOP 30 *
FROM (
	SELECT
		sum(isnull(efrbn.Balance,0)) AS Balance,
		sum(isnull(efrbn.Balance,0)) AS BalanceAmountDivAdjustments,
		--case WHEN sum(isnull(efrbn.BalanceUSD,0) * isnull(x.EOD_Price,0)) >= 10 THEN 'Over 10' ELSE 'Under 10' end AS Indicator,
		null AS Indicator,
		sum(efrbn.BalanceUSD) AS CurrentValue,
		BalanceDate,
		max(isnull(x.EOD_Price,0)) AS EOD_Bid_Prce,
		'QA' AS AccountName,
		'QA' AS SourceName,
		null AS SubAccountName,
		Null AS CoinAssetCodeCalc,
		0 AS PendingRewardsAmount,
		efrbn.CryptoName,
		null AS UserWalletAllowance
	FROM EXW_dbo.EXW_FinanceReportsBalancesNew efrbn
	JOIN EXW_Wallet.CryptoTypes ect 
		ON efrbn.CryptoID = ect.CryptoID
		AND BalanceDateID = CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
	LEFT JOIN (
		SELECT bdcn.InstrumentName, MAX(bdcn.EOD_Bid_Price) AS EOD_Price , bdcn.Date 
		FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn
		WHERE bdcn.InstrumentName LIKE '%/USD' 
		  AND bdcn.Date = <[Parameters].[Parameter 1]>
		GROUP BY bdcn.InstrumentName,bdcn.Date
	) x
		ON x.InstrumentName = CONCAT(CryptoName, '/USD')
	WHERE efrbn.IsTestAccount = 1
	GROUP BY efrbn.CryptoName, BalanceDate
) t
ORDER BY t.CurrentValue DESC) v