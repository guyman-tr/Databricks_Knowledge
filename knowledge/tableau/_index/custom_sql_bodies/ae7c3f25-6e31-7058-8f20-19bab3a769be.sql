SELECT cp.DateID
      ,cp.Date
      ,cp.CID
	  ,i.ValidFrom
	  ,cp.RealizedEquity oldRE
	  ,vl.TotalRealCrypto+vl.TotalRealStocks+vl.Credit newRE
	  ,cp.DepositAmount
	  ,cp.WithdrawAmount
	  ,cp.Equity
	  ,dc.PlayerLevelID CurrentTier
	  ,vl.Credit
FROM [BI_DB].[dbo].[BI_DB_CID_DailyPanel_Club] cp WITH (NOLOCK)
INNER join DWH.dbo.V_Liabilities vl WITH (NOLOCK)
ON cp.CID = vl.CID
AND cp.DateID = vl.DateID
LEFT JOIN #interest i WITH (NOLOCK) 
ON i.CID = cp.CID
JOIN DWH.dbo.Dim_Customer dc
ON cp.CID=dc.RealCID
WHERE cp.DateID >=20220101
AND dc.PlayerLevelID IN (2,6,7)