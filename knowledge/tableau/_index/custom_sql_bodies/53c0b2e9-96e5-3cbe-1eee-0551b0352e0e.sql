SELECT
 tr.TranID 
, tr.AmountUSD  AS 'USD'
,tr.Amount AS 'Coin'
, tr.EtoroFeesUSD
, tr.EtoroFees
,tr.GCID
,tr.CryptoName
,tr.TranDate
, dc.Country
, dc.Regulation
, tr.ActionTypeID
, dc.IsTestAccount
, dpl.Name AS Club
	  FROM
 [EXW].[dbo].EXW_FactTransactions tr with (NOLOcK) 
LEFT JOIN EXW.dbo.EXW_DimUser dc WITH (nolock) on dc.GCID= tr.GCID
LEFT JOIN DWH.dbo.Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
where tr.TranDateID >=  cast(CONVERT (VARCHAR(8) , dateadd(month,-12,getdate()), 112 ) AS INT)
	AND tr.TranStatusID=2
	AND tr.IsRedeem =1