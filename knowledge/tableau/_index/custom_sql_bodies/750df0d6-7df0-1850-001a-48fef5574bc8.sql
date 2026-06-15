SELECT b.*
, tr.[USD OUT - 1 d]
, tr.[USD OUT - 2 d]
, tr.[USD OUT - 3 d]
, tr.[USD OUT - 7 d]
, tr.[Units OUT - 1 d]
,tr.[Units OUT - 2 d]
, tr.[Units OUT - 3 d]
, tr.[Units OUT - 7 d]
FROM 
(

SELECT   edct.Name AS CryptoName
,efb.CryptoId 
,eiw.InternalType
,eiw.Address
,SUM(CASE  WHEN efb.LevelId IS NULL THEN efb.BloxBalance 
                WHEN efb.LevelId IS NOT NULL AND efb.BitgoValue IS NULL THEN efb.BloxBalance 
                ELSE   efb.BitgoValue END)  UnitBalance
,SUM((CASE  WHEN efb.LevelId IS NULL THEN efb.BloxBalance 
                WHEN efb.LevelId IS NOT NULL AND efb.BitgoValue IS NULL THEN efb.BloxBalance 
                ELSE   efb.BitgoValue END)*AvgPrice  ) USDBalance
 
FROM CopyFromLake.WalletBalancesReportDB_Wallet_FinanceReportsBalances efb with (NOLOCK)
    JOIN EXW_dbo.EXW_InternalWallet eiw with (NOLOCK)          ON UPPER(LOWER (efb.WalletId))  = UPPER(LOWER (eiw.Id)) AND efb.CryptoId = eiw.CryptoId
    JOIN EXW_Wallet.CryptoTypes edct     ON eiw.CryptoId = edct.CryptoID   
    JOIN ( SELECT  MAX( efr.Id)Id , max(cast(efr.StartTime AS DATE)) Date  FROM EXW_Wallet.FinanceReports efr   WHERE EndTime IS NOT NULL ) rd ON rd.Id= efb.ReportId
   LEFT JOIN EXW_Wallet.EXW_PriceDaily epd ON epd.CryptoID = efb.CryptoId  AND epd.FullDate = rd.Date
WHERE   1=1
AND efb.Gcid <= 0
GROUP BY  edct.Name,efb.CryptoId,eiw.InternalType, eiw.Address
) b
Left JOIN 
(
SELECT eft.SenderAddress, eft.CryptoId,
	sum(CASE WHEN eft.TranDate >= CAST(GETDATE()-1 AS DATE) THEN eft.AmountUSD ELSE 0 END) AS [USD OUT - 1 d],
	sum(CASE WHEN eft.TranDate >= CAST(GETDATE()-2 AS DATE) THEN eft.AmountUSD ELSE 0 END) AS [USD OUT - 2 d],
	sum(CASE WHEN eft.TranDate >= CAST(GETDATE()-3 AS DATE) THEN eft.AmountUSD ELSE 0 END) AS [USD OUT - 3 d],
	sum(CASE WHEN eft.TranDate >= CAST(GETDATE()-7 AS DATE) THEN eft.AmountUSD ELSE 0 END) AS [USD OUT - 7 d],
	sum(CASE WHEN eft.TranDate >= CAST(GETDATE()-1 AS DATE) THEN eft.Amount ELSE 0 END) AS [Units OUT - 1 d],
		sum(CASE WHEN eft.TranDate >= CAST(GETDATE()-2 AS DATE) THEN eft.Amount ELSE 0 END) AS [Units OUT - 2 d],
	sum(CASE WHEN eft.TranDate >= CAST(GETDATE()-3 AS DATE) THEN eft.Amount ELSE 0 END) AS [Units OUT - 3 d],
	sum(CASE WHEN eft.TranDate >= CAST(GETDATE()-7 AS DATE) THEN eft.Amount ELSE 0 END) AS [Units OUT - 7 d]
FROM EXW_dbo.EXW_FactTransactions eft with (NOLOCK)
WHERE eft.ActionTypeID = 1 
GROUP BY  eft.SenderAddress, eft.CryptoId
) tr 
ON b.Address = tr.SenderAddress
and b.CryptoId =tr.CryptoId