SELECT [PP_DD_count_mins].[Date] AS [Date],
  b.Name as InstrumentName,
  [PP_DD_count_mins].[InstrumentID] AS [InstrumentID],
  [PP_DD_count_mins].[IsUS] AS [IsUS],
   c.LiquidityAccountName,
  [PP_DD_count_mins].[LiquidityAccountID] AS [LiquidityAccountID],
  [PP_DD_count_mins].[PcntOfTotal] AS [PcntOfTotal],
  [PP_DD_count_mins].[TotalTicks] AS [TotalTicks],
  [PP_DD_count_mins].[count_min] AS [count_min],
  [PP_DD_count_mins].[index] AS [index],
boo.Priority1
FROM [dbo].[PP_DD_count_mins] [PP_DD_count_mins]
join DWH.dbo.Dim_Instrument b on [PP_DD_count_mins].InstrumentID = b.InstrumentID
JOIN (select * 			
from openquery ( [AZR-W-REAL-DB-2-BIDBUser],				
		'select		
		LiquidityAccountName		
,LiquidityAccountID				
FROM [etoro].[Trade].[LiquidityAccounts]  TP WITH(NOLOCK)				'
)) c ON c.LiquidityAccountID = PP_DD_count_mins.LiquidityAccountID
left join 
(Select p.InstrumentID, Symbol, Priority1 From
(select distinct IRS.InstrumentID,Symbol  From  [AZR-W-REAL-DB-2-BIDBUser].etoro.Price.InstrumentRateSources IRS left join  [AZR-W-REAL-DB-2-BIDBUser].etoro.Price.AccountRateSource ARS on IRS.AccountRateSourceID = ARS.AccountRateSourceID
 left join [AZR-W-REAL-DB-2-BIDBUser].etoro.Trade.InstrumentMetaData TM on IRS.InstrumentID=TM.InstrumentID)p
left join
(select IRS.InstrumentID,Name  as Priority1 From [AZR-W-REAL-DB-2-BIDBUser].etoro.Price.InstrumentRateSources IRS left join [AZR-W-REAL-DB-2-BIDBUser].etoro.Price.AccountRateSource ARS on IRS.AccountRateSourceID = ARS.AccountRateSourceID Where Priority=10 )a on p.InstrumentID=a.InstrumentID) boo on boo.InstrumentID = [PP_DD_count_mins].InstrumentID