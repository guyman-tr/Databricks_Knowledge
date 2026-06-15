SELECT  DateID
	  , Date
	  , sum(isnull(PreviuosDayBalance,0)) as PreviuosDayBalance
	  , sum(isnull(Deposit			 ,0)) as Deposit			 
	  , sum(isnull(Withdrawal		 ,0)) as Withdrawal		 
	  , sum(isnull(ClosedPnL		 ,0)) as ClosedPnL		 
	  , sum(isnull(CurrentDayBalance ,0)) as CurrentDayBalance 
	  , sum(isnull(OpenPosition		 ,0)) as OpenPosition		 
	  , sum(isnull(Equity			 ,0)) as Equity			 
	  , sum(isnull(TotalOpenMargin	 ,0)) as TotalOpenMargin	 
	  , sum(isnull(RealAssetEquity	 ,0)) as RealAssetEquity	 
	  , CurrentLabel
	  , PrevLabel
	  , Country
	  , UpdateDate
	  , RegulationName
	  , IsGermanBaFin 
FROM BI_DB_dbo.[BI_DB_ASIC_ClientBalanceFinance]  with (nolock)
WHERE Date = <[Parameters].[Parameter 5]>
group by 
DateID
	  , Date
	  , CurrentLabel
	  , PrevLabel
	  , Country
	  , UpdateDate
	  , RegulationName
	  , IsGermanBaFin