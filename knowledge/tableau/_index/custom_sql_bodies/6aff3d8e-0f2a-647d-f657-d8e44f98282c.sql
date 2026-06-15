SELECT cmf.Country,
	  EOMONTH(cmf.DepositDate) AS [Month],
	  SUM(isnull(a1.Revenue,0)) Revenue

	  FROM 
	  
	  (SELECT cmf.CID,cmf.DepositDate,cmf.Country
	  FROM BI_DB.dbo.BI_DB_Money_In_New_Management_Dashboard cmf
	  WHERE cmf.IsFTD=1 AND cmf.DepositMethod='MoneyBookers' AND cmf.PaymentStatusID=2 
	  AND cmf.Country IN   ('Thailand','Morocco','Egypt','Ukraine' ,'Vietnam','Brazil','Argentina','Philippines','United Arab Emirates')
		)  cmf

left JOIN (SELECT bddcr.FullDate,
			bddcr.RealCID,
			bddcr.FullCommissions+bddcr.RollOverFee AS 'Revenue' ,
			bddcr.Country
           FROM BI_DB.dbo.BI_DB_DailyCommisionReport bddcr
		   WHERE bddcr.DateID>=20220701 AND /*bddcr.CountryID IN (9,28,63,138,162,202,216,217,226)*/bddcr.Country IN   ('Thailand','Morocco','Egypt','Ukraine' ,'Vietnam','Brazil','Argentina','Philippines','United Arab Emirates'))AS a1  
			ON cmf.CID = a1.RealCID 
			   AND a1.FullDate>=dateadd(dd,30,cmf.DepositDate) 
GROUP BY cmf.Country,
	  EOMONTH(cmf.DepositDate)