SELECT CAST(DATEADD(month, DATEDIFF(month, 0, dd.FullDate), 0) AS date) 'ActiveDate'
   ,fca1.CountryID
   ,fca1.PlayerLevelID
   , SUM(CASE WHEN fca.AccountTypeID = 9 THEN gc.Cash+ gc.Investment+gc.PnL+gc.DetachedPosInvestment+gc.Dit_PnL END) AUM_CopyPortfolio
   , SUM(CASE WHEN fca.AccountTypeID <> 9  THEN gc.Cash+ gc.Investment+gc.PnL+gc.DetachedPosInvestment+gc.Dit_PnL END ) AUM_CopyTrading
   , SUM(gc.Cash+ gc.Investment+gc.PnL+gc.DetachedPosInvestment+gc.Dit_PnL) AUM 
	FROM  general.etoroGeneral_History_GuruCopiers gc WITH (NOLOCK)
	INNER JOIN DWH_dbo.Dim_Date dd WITH (NOLOCK)
		ON gc.Timestamp = DATEADD(DAY,1,dd.FullDate)
	INNER JOIN [DWH_dbo].[Fact_SnapshotCustomer] fca WITH (NOLOCK)
		ON fca.RealCID = gc.ParentCID
	INNER JOIN [DWH_dbo].Dim_Range dr1 WITH (NOLOCK)
		ON fca.DateRangeID = dr1.DateRangeID
	INNER JOIN [DWH_dbo].[Fact_SnapshotCustomer] fca1 WITH (NOLOCK)
		ON gc.CID = fca1.RealCID
	INNER JOIN [DWH_dbo].Dim_Range dr2 WITH (NOLOCK)
		ON fca1.DateRangeID = dr2.DateRangeID
	WHERE dd.IsLastDayOfMonth = 'Y' 
	AND fca1.IsValidCustomer = 1
	AND fca1.IsDepositor=1
	AND dr1.FromDateID <= dd.DateKey
	AND dr1.ToDateID >= dd.DateKey 
	AND dr2.FromDateID <= dd.DateKey 
	AND dr2.ToDateID >= dd.DateKey
	 and dd.DateKey >=20220901
	GROUP BY CAST(DATEADD(month, DATEDIFF(month, 0, dd.FullDate), 0) AS date)
	   ,fca1.CountryID
   ,fca1.PlayerLevelID