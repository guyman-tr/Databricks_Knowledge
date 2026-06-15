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
LEFT JOIN (SELECT bdic.CID
			,MAX(bdic.ValidFrom) ValidFrom
			FROM BI_DB.dbo.BI_DB_InterestConsent bdic
			WHERE bdic.ConsentStatusID = 1
			AND bdic.ValidTo = '9999-12-31 23:59:59.99'
			GROUP BY bdic.CID) i
ON i.CID = cp.CID
JOIN DWH.dbo.Dim_Customer dc
ON cp.CID=dc.RealCID
WHERE cp.DateID >=20230101