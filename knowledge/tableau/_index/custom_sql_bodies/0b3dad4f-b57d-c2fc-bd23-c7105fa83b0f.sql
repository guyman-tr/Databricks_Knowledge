SELECT dc.RealCID
		,dc1.Name Country
		,dpl.Name Club
		,dp.OpenOccurred 'Open Position'
		,di.Symbol
		,di.InstrumentDisplayName
		,dp.Amount
		,dp.PositionID
		,dp.Leverage
		,CASE WHEN di.InstrumentDisplayName IN ('USD/JPY','USD/CAD','USD/CHF','EUR/JPY','EUR/GBP','EUR/CAD','EUR/CHF','GBP/CAD','GBP/CHF','CAD/CHF','EUR/USD','GBP/USD','GBP/JPY','CAD/JPY','CHF/JPY','EUR/AUD','EUR/NZD','AUD/NZD','AUD/USD','NZD/USD','GBP/AUD','GBP/NZD','AUD/JPY','NZD/JPY','AUD/CHF','NZD/CHF','AUD/CAD','NZD/CAD'

					) AND dp.Leverage>30 THEN 'X30' 
					WHEN (di.SymbolFull IN ('UK100','FRA40','GER40','DJ30','SPX500','NASDAQ Composite','NSDQ100','JPN225','AUS200','EUSTX50','GOLD') 
							OR di.InstrumentTypeID = 1 and di.InstrumentDisplayName NOT IN ('USD/JPY','USD/CAD','USD/CHF','EUR/JPY','EUR/GBP','EUR/CAD','EUR/CHF','GBP/CAD','GBP/CHF','CAD/CHF','EUR/USD','GBP/USD','GBP/JPY','CAD/JPY','CHF/JPY','EUR/AUD','EUR/NZD','AUD/NZD','AUD/USD','NZD/USD','GBP/AUD','GBP/NZD','AUD/JPY','NZD/JPY','AUD/CHF','NZD/CHF','AUD/CAD','NZD/CAD')
							) AND dp.Leverage>20 THEN 'X20' 
					WHEN di.InstrumentTypeID IN (2,4) AND dp.Leverage>10 and di.SymbolFull<> 'GOLD' 
                                        and di.SymbolFull not IN ('UK100','FRA40','GER40','DJ30','SPX500','NASDAQ Composite','NSDQ100','JPN225','AUS200','EUSTX50','GOLD')  THEN 'X10'
					WHEN di.InstrumentTypeID IN (6) AND di.InstrumentID NOT IN (1367,1369) AND dp.Leverage>5 THEN 'X5'
					WHEN (di.InstrumentTypeID IN (10) OR di.InstrumentID IN (1367,1369)) AND dp.Leverage>2 THEN 'X2' ELSE NULL END 'High leverage exposure'
        ,case when dp.MirrorID = 0 THEN 'Manual' ELSE 'Copy' END IsCopy
		,CASE WHEN dp.IsSettled = 1 THEN 'Real' ELSE 'CFD' END IsCFD
FROM DWH_dbo.Dim_Position dp
JOIN DWH_dbo.Dim_Customer dc
ON dc.RealCID = dp.CID
JOIN DWH_dbo.Dim_Instrument di
ON dp.InstrumentID = di.InstrumentID
JOIN DWH_dbo.Dim_Country dc1
ON dc.CountryID = dc1.CountryID
JOIN DWH_dbo.Dim_PlayerLevel dpl
ON dc.PlayerLevelID = dpl.PlayerLevelID
WHERE dp.CloseDateID = 0
AND dc.IsDepositor = 1
AND dc.IsValidCustomer = 1
AND dc.RegulationID = 11
AND dp.Leverage>2