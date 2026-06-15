SELECT fbd.ModificationDate,fbd.DepositID,dbd.Name Depot,dc.Abbreviation Currency,fbd.Amount,fbd.ExchangeRate,fbd.AmountUSD 
FROM DWH..Fact_BillingDeposit fbd
JOIN DWH..Dim_BillingDepot dbd
	ON fbd.DepotID = dbd.DepotID
JOIN DWH..Dim_Currency dc
	ON fbd.CurrencyID = dc.CurrencyID
WHERE fbd.ModificationDateID>=20210101
AND fbd.PaymentStatusID = 2

UNION
SELECT adh.ModificationDate,adh.DepositID,dbd.Name Depot,adh.Currency COLLATE Latin1_General_100_BIN ,adh.[Amount In Orig Curr] Amount,adh.BaseExchangeRate ExchangeRate,adh.[Amount in $] AmountUSD
FROM BI_DB..BI_DB_All_Deposit_Hourly adh
JOIN DWH..Dim_BillingDepot dbd
	ON adh.DepotID = dbd.DepotID
WHERE  adh.PaymentStatus = 'Approved'