SELECT  SUM(a.BalanceUSD) 'Balance USD'
, Sum(a.Users) AS 'Total Users'
, SUM (CASE WHEN a.BalanceUSD=0 THEN 1 ELSE 0 END) 'Zero Users' 
, SUM (CASE WHEN a.BalanceUSD<>0 THEN 1 ELSE 0 END) 'Non Zero Users' 
,a.FullDate
FROM
(SELECT  SUM(efb.BalanceUSD) 'BalanceUSD'
, COUNT(DISTINCT efb.GCID) Users ,efb.FullDate
FROM EXW_FactBalance efb WITH (NOLOCK)
JOIN EXW_DimUser edu ON efb.GCID = edu.GCID AND edu.IsTestAccount =0
WHERE efb.GCID >0 AND efb.FullDateID =  CAST(CONVERT(VARCHAR(8), GETDATE()-1, 112) AS INT) 
GROUP BY edu.GCID, efb.FullDate
 )a 
group by a.FullDate