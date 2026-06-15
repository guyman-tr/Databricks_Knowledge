SELECT [PP_DD_max_tick_count].[Date] AS [Date],
   b.Name as InstrumentName,
  [PP_DD_max_tick_count].[InstrumentID] AS [InstrumentID],
  [PP_DD_max_tick_count].[IsUS] AS [IsUS],
  c.LiquidityAccountName,
  [PP_DD_max_tick_count].[LiquidityAccountID] AS [LiquidityAccountID],
  [PP_DD_max_tick_count].[PcntOfTotal] AS [PcntOfTotal],
  [PP_DD_max_tick_count].[TotalTicks] AS [TotalTicks],
  [PP_DD_max_tick_count].[index] AS [index],
  [PP_DD_max_tick_count].[max_tick_count] AS [max_tick_count],
boo.Priority1
FROM [dbo].[PP_DD_max_tick_count] [PP_DD_max_tick_count]
join DWH.dbo.Dim_Instrument b on [PP_DD_max_tick_count].InstrumentID = b.InstrumentID
JOIN (select * 			
from openquery ( [AZR-W-REAL-DB-2-BIDBUser],				
		'select		
		LiquidityAccountName		
,LiquidityAccountID				
FROM [etoro].[Trade].[LiquidityAccounts]  TP WITH(NOLOCK)				'
)) c ON c.LiquidityAccountID = PP_DD_max_tick_count.LiquidityAccountID
left join 
(Select p.InstrumentID, Symbol, Priority1 From
(select distinct IRS.InstrumentID,Symbol  From  [AZR-W-REAL-DB-2-BIDBUser].etoro.Price.InstrumentRateSources IRS left join  [AZR-W-REAL-DB-2-BIDBUser].etoro.Price.AccountRateSource ARS on IRS.AccountRateSourceID = ARS.AccountRateSourceID
 left join [AZR-W-REAL-DB-2-BIDBUser].etoro.Trade.InstrumentMetaData TM on IRS.InstrumentID=TM.InstrumentID)p
left join
(select IRS.InstrumentID,Name  as Priority1 From [AZR-W-REAL-DB-2-BIDBUser].etoro.Price.InstrumentRateSources IRS left join [AZR-W-REAL-DB-2-BIDBUser].etoro.Price.AccountRateSource ARS on IRS.AccountRateSourceID = ARS.AccountRateSourceID Where Priority=10 )a on p.InstrumentID=a.InstrumentID) boo on boo.InstrumentID = [PP_DD_max_tick_count].InstrumentID