SELECT
 e.GCID
,e.RealCID
, e.CryptoName
, e.Balance
, e.BalanceUSD
, e.BalanceDate
, e.Regulation
, e.Country
, e.IsTestAccount
, dpl.Name Club
FROM EXW.dbo.EXW_UserCalculatedBalance e WITH (NOLOCK)
JOIN EXW.dbo.EXW_DimUser edu WITH (NOLOCK) ON e.GCID = edu.GCID 
JOIN DWH.dbo.Dim_PlayerLevel dpl WITH (NOLOCK) ON edu.PlayerLevelID = dpl.PlayerLevelID
WHERE e.BalanceDateId =CAST(CONVERT(VARCHAR(8), getdate()-1, 112) AS INT) 
AND CryptoId = <[Parameters].[Parameter 1]>