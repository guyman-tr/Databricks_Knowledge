SELECT	a.RealCID AS CID 
                ,a.GCID
		,a.ID  
		,a.AffiliateID
		,a.BannerID
                ,a.FunnelID
		,a.FunnelFromID
		,bb.Amount
		,bb.Amount_Indices
		,bb.Amount_Currencies
		,bb.Amount_Stocks
		,bb.Amount_ETF
		,bb.Amount_Crypto_Currencies
		,dc.Region
		,dc.Name AS Country
		,case when bb.CID is not null then 1 else 0 end as OpenTrade
		,a.FirstDepositDate as FTDdate
		,ISNULL(cc.DepositAmount,0) DepositAmount
		,CompensationCategory
		,ISNULL(dd.CompensationAmount,0) CompensationAmount
                ,a.SubSerialID
FROM DWH.dbo.Dim_Customer  a
JOIN DWH.dbo.Dim_Country dc
	ON a.CountryID = dc.CountryID
JOIN BI_DB.dbo.BI_DB_CIDFirstDates fd
	ON fd.CID = a.RealCID
LEFT JOIN(
			SELECT aa.RealCID AS CID
			,SUM(CASE WHEN InstrumentType='Indices' THEN dp.Amount ELSE 0 END) Amount_Indices
			,SUM(CASE WHEN InstrumentType='Currencies' THEN dp.Amount else 0 END) Amount_Currencies
			,SUM(CASE WHEN InstrumentType='Stocks' THEN dp.Amount else 0 END) Amount_Stocks
			,SUM(CASE WHEN InstrumentType='ETF' THEN dp.Amount else 0 END) Amount_ETF
			,SUM(CASE WHEN InstrumentType='Crypto Currencies' THEN dp.Amount else 0 END) Amount_Crypto_Currencies
				  ,SUM(dp.Amount) AS Amount
			FROM DWH.dbo.Dim_Customer  aa
			INNER JOIN DWH.dbo.Dim_Position dp
				ON dp.CID = aa.RealCID
            LEFT JOIN DWH.dbo.Dim_Instrument di	
				ON dp.InstrumentID = di.InstrumentID 
			JOIN BI_DB.dbo.BI_DB_CIDFirstDates fd
				ON fd.CID = aa.RealCID
			WHERE  dp.OpenOccurred BETWEEN  <[Parameters].[Parameter 2]> AND DATEADD(DAY,1,<[Parameters].[Parameter 3]>)
				AND aa.FirstDepositDate > '20000101'
				AND aa.FirstDepositDate BETWEEN  <[Parameters].[Parameter 2]> AND DATEADD(DAY,1,<[Parameters].[Parameter 3]>)
				AND aa.IsValidCustomer = 1
				AND IsDepositor = 1
				AND fd.Region IN ('USA','Australia')
				AND (fd.Channel IN('Affiliate','Introducing Agents','Media') OR fd.SerialID IN(92837,52912,38706))
				--AND dp.MirrorID = 0
			GROUP BY  aa.RealCID
			HAVING SUM(dp.Amount) >= <[Parameters].[Parameter 4]>
		)bb
	ON bb.CID = a.RealCID
LEFT JOIN (
			SELECT fca.RealCID CID
				 ,SUM(Amount) DepositAmount 
			FROM DWH.dbo.Fact_CustomerAction fca
			JOIN DWH.dbo.Dim_Customer  aa
				ON aa.RealCID = fca.RealCID
			JOIN BI_DB.dbo.BI_DB_CIDFirstDates fd
				ON fd.CID = fca.RealCID
			WHERE ActionTypeID = 7
				AND IsValidCustomer = 1
				AND IsDepositor = 1
				AND fd.Region IN ('USA','Australia')
				AND (fd.Channel IN('Affiliate','Introducing Agents','Media') OR fd.SerialID IN(92837,52912,38706))
				AND Occurred  BETWEEN  <[Parameters].[Parameter 2]> AND DATEADD(DAY,1,<[Parameters].[Parameter 3]>)
			GROUP BY  fca.RealCID
		) cc
	ON cc.CID = a.RealCID
LEFT JOIN (
			SELECT fca.RealCID CID
			,a.Name AS CompensationCategory
				 ,SUM(Amount) CompensationAmount
			FROM DWH.dbo.Fact_CustomerAction fca
			JOIN DWH.dbo.Dim_Customer  aa
				ON aa.RealCID = fca.RealCID
			JOIN BI_DB.dbo.BI_DB_CIDFirstDates fd
				ON fd.CID = fca.RealCID
			JOIN DWH..Dim_CompensationReason a
				ON a.CompensationReasonID=fca.CompensationReasonID
			WHERE ActionTypeID = 36
				AND IsValidCustomer = 1
				AND IsDepositor = 1
				AND fd.Region IN ('USA','Australia')
				AND (fd.Channel IN('Affiliate','Introducing Agents','Media') OR fd.SerialID IN(92837,52912,38706))
				AND fca.CompensationReasonID=20
			GROUP BY  fca.RealCID,a.Name		
		) dd
	ON dd.CID = a.RealCID
WHERE a.IsValidCustomer = 1
	AND fd.Region IN ('USA','Australia')
	AND (fd.Channel IN ('Affiliate','Introducing Agents','Media') OR fd.SerialID IN(92837,52912,38706))
	AND a.FirstDepositDate BETWEEN  <[Parameters].[Parameter 2]>  AND DATEADD(DAY,1,<[Parameters].[Parameter 3]>)
	AND a.FirstDepositDate > '20000101'