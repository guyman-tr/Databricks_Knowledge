SELECT ftd.EOM,
	  ftd.FirstDepositFundingType,
	  ftd.Country,
	  COUNT( ftd.CID) AS Clients,
	  SUM(ftd.FirstDepositAmount) 'FTDA',
	  SUM(rev_total.Revenue) 'Revenue'
	  from
	  (
	  SELECT EOMONTH(CAST(bdcd.FirstDepositDate AS date)) 'EOM',
	  bdcd.FirstDepositFundingType,
	  bdcd.FirstDepositAmount,
	  bdcd.CID,
	  bdcd.Country
      FROM BI_DB..BI_DB_CIDFirstDates bdcd
	  WHERE bdcd.FirstDepositDate IS NOT NULL AND CAST(bdcd.FirstDepositDate AS DATE)>=DATEADD(mm,-3,GETDATE()-1)
	  AND bdcd.Country IN ('Thailand','Morocco','Egypt','Ukraine' ,'Vietnam','Brazil','Argentina','Philippines','United Arab Emirates')
	  )AS ftd
	  LEFT JOIN 
	  (
			SELECT EOMONTH(bddcr.FullDate) 'EOM',
			bddcr.RealCID,
			bddcr.Country,
			SUM(bddcr.FullCommissions+bddcr.RollOverFee) AS 'Revenue' 
			
           FROM BI_DB.dbo.BI_DB_DailyCommisionReport bddcr
		   WHERE bddcr.DateID>=CAST(CONVERT(VARCHAR(8), DATEADD(mm,-3,getdate()-1), 112) AS INT)
                 AND bddcr.Country IN ('Thailand','Morocco','Egypt','Ukraine' ,'Vietnam','Brazil','Argentina','Philippines','United Arab Emirates')               
		GROUP BY EOMONTH(bddcr.FullDate),
			bddcr.RealCID,
			bddcr.Country
		)rev_total
		ON ftd.EOM=rev_total.EOM AND rev_total.RealCID=ftd.CID AND ftd.Country=rev_total.Country
		GROUP BY ftd.EOM,
	  ftd.FirstDepositFundingType,
	  ftd.Country