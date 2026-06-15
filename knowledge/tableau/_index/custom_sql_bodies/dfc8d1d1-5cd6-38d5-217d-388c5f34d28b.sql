SELECT 
EOMONTH (BalanceDate) AS 'Date'    
,YEAR(BalanceDate) * 100 + MONTH(BalanceDate) AS Year_Month
,sum(b.TotalBalance*USDApproxRate)/COUNT(DISTINCT b.BalanceDate) Avg_eMoney_BalanceUSD
FROM eMoney_dbo.eMoney_Calculated_Balance b
WHERE b.IsValidETM=1
AND b.BalanceDateID>=20220101
AND b.BalanceDateID<20240401
group by EOMONTH (BalanceDate)  
,YEAR(BalanceDate) * 100 + MONTH(BalanceDate)
UNION ALL
SELECT
EOMONTH (BalanceDate) AS 'Date'    
,YEAR(BalanceDate) * 100 + MONTH(BalanceDate) AS Year_Month
,SUM(cb.ClosingBalanceBO*cb.USDApproxRate)/COUNT(DISTINCT BalanceDate) AS AvgeMoney_Balance
FROM eMoney_dbo.eMoneyClientBalance cb
INNER JOIN eMoney_dbo.eMoney_Dim_Account mda WITH (NOLOCK)
ON cb.CID = mda.CID AND mda.IsValidETM=1 AND mda.GCID_Unique_Count=1
WHERE cb.IsExistingUser=1
AND cb.BalanceDateID>=20240401
AND BalanceDateID<=CAST(FORMAT( GETDATE()-1, 'yyyyMMdd') AS INT)
GROUP BY EOMONTH (BalanceDate)
,YEAR(BalanceDate) * 100 + MONTH(BalanceDate)