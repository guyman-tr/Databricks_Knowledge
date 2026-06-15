SELECT dp.Date,
		dr.Name AS 'Regulation',
		di.Name AS 'InstrumentDisplayName',
		COUNT(distinct(dc.RealCID)) AS 'Count_CID',
		SUM(dp.Amount) AS 'Amount',
		SUM(dp.AmountInUnitsDecimal) AS 'AmountInUnitsDecimal',
		CAST(SUM(dp.NOP) AS BIGINT) AS  NOP,
        dp.IsSettled,
        CASE WHEN di.InstrumentTypeID IN (5) AND dp.IsSettled=1 THEN 'RealStocks'
		   WHEN di.InstrumentTypeID IN (5) AND dp.IsSettled=0 THEN 'CFDStocks'
			WHEN di.InstrumentTypeID IN (6) AND dp.IsSettled=0 THEN 'CFDETF'
			WHEN di.InstrumentTypeID IN (6) AND dp.IsSettled=1 THEN 'RealETF'
			WHEN di.InstrumentTypeID IN (10) AND dp.IsSettled=1 THEN 'RealCrypto' 
			WHEN di.InstrumentTypeID IN (10) AND dp.IsSettled=0 THEN 'CFDCrypto' 
			WHEN di.InstrumentTypeID IN (1) AND dp.IsSettled=0 THEN 'CFDCurrencies'
			WHEN di.InstrumentTypeID IN (2) AND dp.IsSettled=0 THEN 'CFDCommodities'
			WHEN di.InstrumentTypeID IN (4) AND dp.IsSettled=0 then 'CFDIndecies'
			ELSE 'NA' END AS 'InstrumentType',
        CASE WHEN dp.IsBuy=1 THEN 'Buy' ELSE 'Sell' END AS  'SellBuy'
 FROM BI_DB.dbo.BI_DB_PositionPnL dp 
 INNER JOIN DWH..Dim_Customer dc ON dp.CID=dc.RealCID
			AND dc.IsValidCustomer=1
 INNER JOIN DWH.dbo.Dim_Instrument di ON di.DWHInstrumentID=dp.InstrumentID
 INNER JOIN DWH..Dim_Regulation dr ON dc.RegulationID=dr.DWHRegulationID
								AND dr.DWHRegulationID IN (4,10)
 WHERE dp.DateID=CAST(CONVERT(CHAR(8),<[Parameters].[Parameter 2]>, 112) AS INT)
 GROUP BY  dp.Date,
 			dr.Name,
			di.Name,
           dp.IsSettled,
           CASE WHEN di.InstrumentTypeID IN (5) AND dp.IsSettled=1 THEN 'RealStocks'
		   WHEN di.InstrumentTypeID IN (5) AND dp.IsSettled=0 THEN 'CFDStocks'
			WHEN di.InstrumentTypeID IN (6) AND dp.IsSettled=0 THEN 'CFDETF'
			WHEN di.InstrumentTypeID IN (6) AND dp.IsSettled=1 THEN 'RealETF'
			WHEN di.InstrumentTypeID IN (10) AND dp.IsSettled=1 THEN 'RealCrypto' 
			WHEN di.InstrumentTypeID IN (10) AND dp.IsSettled=0 THEN 'CFDCrypto' 
			WHEN di.InstrumentTypeID IN (1) AND dp.IsSettled=0 THEN 'CFDCurrencies'
			WHEN di.InstrumentTypeID IN (2) AND dp.IsSettled=0 THEN 'CFDCommodities'
			WHEN di.InstrumentTypeID IN (4) AND dp.IsSettled=0 then 'CFDIndecies'
			ELSE 'NA' END,
           CASE WHEN dp.IsBuy=1 THEN 'Buy' ELSE 'Sell' END