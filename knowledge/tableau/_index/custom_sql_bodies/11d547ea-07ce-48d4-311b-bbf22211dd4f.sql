SELECT di.SymbolFull
	  ,di.InstrumentDisplayName
	  ,di.InstrumentType
	  ,CAST(fca.Occurred AS DATE) Date
	  ,SUM(CASE WHEN fca.ActionTypeID=1 THEN -fca.Amount ELSE 0 END) AS MoneyIN
	  ,SUM(CASE WHEN fca.ActionTypeID=4 THEN -fca.Amount ELSE 0 END) AS MoneyOut
	  ,SUM(-fca.Amount) NetMI
FROM [DWH_dbo].Fact_CustomerAction fca
JOIN [DWH_dbo].Dim_Instrument di
ON fca.InstrumentID = di.InstrumentID
WHERE fca.ActionTypeID IN (1,4)
AND fca.DateID BETWEEN CONVERT(CHAR(8),DATEADD(MONTH,-2,GETDATE()-1),112) AND CONVERT(CHAR(8),GETDATE()-1,112)
GROUP BY di.SymbolFull
	    ,di.InstrumentDisplayName
		,di.InstrumentType
		,CAST(fca.Occurred AS DATE)