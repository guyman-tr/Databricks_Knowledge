SELECT t1.BalanceDate, t2.TxCreatedDate, t1.Total_C_Wallet_Balance_Per_Date, t2.num_C2F_Tx FROM 
(
SELECT a.BalanceDate, sum(a.BalanceUSD) AS Total_C_Wallet_Balance_Per_Date  
from [EXW_dbo].[EXW_FinanceReportsBalancesNew] a
INNER JOIN (
SELECT mdt.CID
FROM eMoney_dbo.eMoney_Dim_Transaction mdt
WHERE mdt.TxStatusModificationDateID>=20250301 AND mdt.TxTypeID=14
GROUP BY mdt.CID)c ON a.RealCID=c.CID
where a.BalanceDate>=GETDATE()-60
and a.IsTestAccount =0
and a.ComplianceClosureEvent =0
and a.AMLClosureEvent =0
GROUP BY a.BalanceDate
) t1  

JOIN 

(
SELECT mdt.TxCreatedDate, count(*) num_C2F_Tx 
FROM eMoney_dbo.eMoney_Dim_Transaction mdt
WHERE mdt.TxTypeID=14 
and mdt.TxCreatedDate>= getdate()-60 
group BY mdt.TxCreatedDate
) t2 ON t1.BalanceDate=t2.TxCreatedDate