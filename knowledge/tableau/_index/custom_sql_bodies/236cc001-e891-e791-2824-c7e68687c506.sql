select 
		CAST(CONVERT(char(8), DateID) as date) EoW_Sat
		, Regulation
		 , SUM(isnull(CryptoCommission					,0)) as CryptoCommission		
		 , sum(isnull(TransferCoinFees					,0)) AS TransferCoinFees
		 , sum(ISNULL(CopyCommission					,0)) AS CopyCommission
		 , sum(ISNULL(InterestFees						,0)) AS InterestFees
		 , sum(ISNULL(DormantFee						,0)) AS DormantFee
		 , sum(ISNULL(TradingFees						,0)) AS TradingFees
		 , sum(ISNULL(SDRT								,0)) AS SDRT
		 , sum(ISNULL(TicketFees						,0)) AS TicketFees
		 , sum(ISNULL(CashoutFee						,0)) AS CashoutFee
                 ,SUM( 	
			ISNULL([FullTotalCommission],0)+
			ISNULL([InterestFees],0)   +
			ISNULL([ConversionFees],0) +
			ISNULL([DormantFee],0)     +
			(-1*ISNULL(TradingFees,0) - (-1 * ISNULL(TicketFees,0)) )
			+
			(--cal_rollover_fee
				ISNULL([OvernightFee],0) - ISNULL([DividendsPaid],0) - (-1 * ISNULL([SDRT],0)) - (-1 * ISNULL([TicketFees],0)) 
			)+
			-1 * ISNULL([SDRT],0)+
			ISNULL([TransferCoinFees],0)+
			ISNULL([CashoutFee],0)+
			-1 * ISNULL([TicketFees],0)
			
			)
			AS DDRdailyRevenue	
	from BI_DB_dbo.[BI_DB_DDR_TimeRange_Aggregated_Country_Level] 
	WHERE Region='USA'
	and IsCreditReportValidCB=1
	AND IsValidCustomer=1
	AND Regulation in ('FinCEN', 'FinCEN+FINRA', 'eToroUS', 'FINRAONLY','NYDFS+FINRA')
	--AND Country IN ('United States','US Virgin Islands','Puerto Rico') 
	AND TimeRange = 'ThisWeek'
	and DateID IN (
			SELECT dd.DateKey FROM DWH_dbo.Dim_Date dd
			WHERE dd.DateKey >= CONVERT(nvarchar(8),DATEADD(QUARTER,-1,GETDATE()),112) --AND CONVERT(nvarchar(8), GETDATE(), 112)	
				AND dd.DayNumberOfWeek_Sun_Start=7 -- target: saturdays		
			)
	GROUP BY CAST(CONVERT(char(8), DateID) as date)
	, Regulation
	--ORDER BY CAST(CONVERT(char(8), DateID) as date)