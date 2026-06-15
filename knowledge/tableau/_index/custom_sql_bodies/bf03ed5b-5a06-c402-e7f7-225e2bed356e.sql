SELECT p.AffiliateID,
	p.AffiliatesGroupsName,
	p.Contact,
	p.CID, 
	p.Country,
	p.Reg_Date,
	p.FTD_Date,
	p.FirstAction,
	p.FirstAction_Date,
	r.Revenue,
	CASE WHEN r.Revenue >= 30 THEN 1 ELSE 0 END AS Reached_30$_Rev,
	ftr.Date Reached_30$_Rev_Date
FROM (SELECT fd.SerialID AffiliateID,
			da.AffiliatesGroupsName,
			da.Contact,
			fd.CID, 
			fd.Country,
			CAST(fd.registered AS DATE) Reg_Date,
			CAST(fd.FirstDepositDate AS DATE) FTD_Date, 
			fa.FirstAction_Detailed FirstAction,
			CAST(fa.FirstActionDate AS DATE) FirstAction_Date
		FROM BI_DB..BI_DB_CIDFirstDates fd
			JOIN BI_DB..BI_DB_First5Actions fa
			ON fd.CID = fa.CID
			JOIN DWH..Dim_Affiliate da
			ON fd.SerialID = da.AffiliateID
		WHERE CAST(fd.registered AS DATE) >= '20230101'
			AND fd.Channel = 'Affiliate'
			AND fa.FirstAction_Detailed IN ('FX/Commodities/Indices', 'CFD Stocks/ETFs')
		) p
	JOIN 
		(SELECT pop.CID, 
			SUM(CASE WHEN dp.CloseDateID = 0 THEN ISNULL(dp.CommissionByUnits,0) ELSE ISNULL(dp.CommissionOnClose,0) END) Revenue
		FROM (SELECT fd.CID
				FROM BI_DB..BI_DB_CIDFirstDates fd
					JOIN BI_DB..BI_DB_First5Actions fa
					ON fd.CID = fa.CID
				WHERE CAST(fd.registered AS DATE) >= '20230101'
					AND fd.Channel = 'Affiliate'
					AND fa.FirstAction_Detailed IN ('FX/Commodities/Indices', 'CFD Stocks/ETFs')
				) pop
			JOIN DWH..Dim_Position dp
			ON pop.CID = dp.CID
		WHERE dp.OpenDateID >= 20230101 
		GROUP BY pop.CID) r
	ON p.CID = r.CID
	LEFT JOIN BI_DB..BI_DB_FirstTimeRev30 ftr
	ON p.CID = ftr.CID