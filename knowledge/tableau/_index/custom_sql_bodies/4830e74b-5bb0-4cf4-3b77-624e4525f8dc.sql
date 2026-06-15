select 
	DateID
	 , convert(varchar(6),CONVERT(date, convert(varchar(10), ta.DateID)) ,112) AS TimeRange 
	 , dd.DateKey
	 , dd.IsLastDayOfMonth
	 , dd.FullDate
	 , Regulation
	 , IsBlocked
	 , IsCreditReportValidCB
	 , IsGermanBaFin
	 , IsValidCustomer
	 , MifidCategory
	 , PlayerLevel AS Club
	 , PlayerStatus
	 , FirstActionType
	 , Country
	 , dc.MarketingRegionManualName as Region
	 , isnull(CountUsers						,0) as CountUsers
	 , isnull(CASE WHEN PlayerLevel NOT IN ('Bronze', 'Internal') THEN CountUsers END, 0) as CountUsers_Club
	 , isnull(CASE WHEN PlayerLevel IN ('Platinum Plus', 'Diamond') THEN CountUsers END, 0) as CountUsers_HTClub
	 -- Funded count
	 , isnull(Funded_New_Def 					,0) as Funded_New_Def 
	 , isnull(CASE WHEN PlayerLevel NOT IN ('Bronze', 'Internal') THEN Funded_New_Def END, 0) as CountUsers_ClubFunded
	 , isnull(realizedEquity					,0) as realizedEquity					
	 , isnull(TotalLiability					,0) as TotalLiability					
	 , isnull(InProcessCashout					,0) as InProcessCashout					
	 , isnull(NOPCrypto							,0) as NOPCrypto							
	 , isnull(NOPCryptoCFD						,0) as NOPCryptoCFD						
	 , isnull(NOPStocks							,0) as NOPStocks							
	 , isnull(NOPStocksCFD						,0) as NOPStocksCFD						
	 , isnull(TotalRealCryptoLoan				,0) as TotalRealCryptoLoan				
	 , isnull(PositionPNL						,0) as PositionPNL						
	 , isnull(NOP								,0) as NOP								
	 , isnull(ActualNWA							,0) as ActualNWA							
	 , isnull(ActiveCopy						,0) as ActiveCopy						
	 , isnull(ActiveManualStocksETFs			,0) as ActiveManualStocksETFs			
	 , isnull(ActiveManualFXCommoditiesIndices	,0) as ActiveManualFXCommoditiesIndices	
	 , isnull(ActiveManualCrypto				,0) as ActiveManualCrypto				
	 , isnull(ActiveOpen						,0) as ActiveOpen						
	 , isnull(ActiveOpenManual					,0) as ActiveOpenManual					
	 , isnull(ActiveFunded						,0) as ActiveFunded						
	 , isnull(ActiveTrader						,0) as ActiveTrader						
	 , isnull(Equity							,0) as Equity							
	 , isnull(InvestedInManualTradeing			,0) as InvestedInManualTradeing			
	 , isnull(RealizedEquityCalculated			,0) as RealizedEquityCalculated			
	 , isnull(InvestedInStocksManual			,0) as InvestedInStocksManual			
	 , isnull(InvestedInCryptoManual			,0) as InvestedInCryptoManual			
	 , isnull(InvestedInCopyIncludingCash		,0) as InvestedInCopyIncludingCash		
	 , isnull(CustomerPnL						,0) as CustomerPnL						
	 , isnull(CustomerPnLStocks					,0) as CustomerPnLStocks					
	 , isnull(CustomerPnLCopy					,0) as CustomerPnLCopy					
	 , isnull(CustomerPnLManual					,0) as CustomerPnLManual					
	 , isnull(CustomerPnLCrypto					,0) as CustomerPnLCrypto					
	 , isnull(CustomerPnLStocksReal				,0) as CustomerPnLStocksReal				
	 , isnull(CustomerPnLCryptoReal				,0) as CustomerPnLCryptoReal				
	 , isnull(UnrealizedPnL						,0) as UnrealizedPnL						
	 , isnull(Credit							,0) as Credit							
	 , isnull(FirstTimeFunded					,0) as FirstTimeFunded					
--	 , isnull(Funded_New_Def 					,0) as Funded_New_Def 
	 , ISNULL(ta.InvestedInCryptoTRS			,0) AS InvestedInCryptoTRS
from BI_DB_dbo.[BI_DB_DDR_TimeRange_Aggregated_Country_Level] ta with (nolock)
JOIN DWH_dbo.Dim_Date dd
	ON ta.DateID = dd.DateKey AND dd.DayNumberOfWeek_Sun_Start =7  -- sat is the last day of the week
	AND ta.TimeRange = 'Yesterday'
JOIN DWH_dbo.Dim_Country dc
	ON ta.Country = dc.Name
WHERE 
ta.DateID BETWEEN
CAST(FORMAT(CAST(DATEADD(WEEK, -48, getdate()) AS DATE),'yyyyMMdd') as INT)
AND
CAST(FORMAT(CAST(DATEADD(WEEK, 0, getdate()) AS DATE),'yyyyMMdd') as INT)