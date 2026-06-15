SELECT [PP_DD_dist_avg_ask_per_lp].[Date] AS [Date],
  b.Name as InstrumentName,
  [PP_DD_dist_avg_ask_per_lp].[InstrumentID] AS [InstrumentID],
  [PP_DD_dist_avg_ask_per_lp].[IsUS] AS [IsUS],
  c.LiquidityAccountName,
  [PP_DD_dist_avg_ask_per_lp].[LiquidityAccountID] AS [LiquidityAccountID],
  [PP_DD_dist_avg_ask_per_lp].[avg_dif_ask] AS [avg_dif_ask],
  [PP_DD_dist_avg_ask_per_lp].[pcnt_avg_dif_ask] AS [pcnt_avg_dif_ask],
  [PP_DD_dist_avg_ask_per_lp].[avg_dif_bid] AS [avg_dif_bid],
  [PP_DD_dist_avg_ask_per_lp].[pcnt_avg_dif_bid] AS [pcnt_avg_dif_bid],
boo.Priority1
FROM [dbo].[PP_DD_dist_avg_ask_per_lp_150772] [PP_DD_dist_avg_ask_per_lp]
join DWH.dbo.Dim_Instrument b on [PP_DD_dist_avg_ask_per_lp].InstrumentID = b.InstrumentID
JOIN (select * 			
from openquery ( [AZR-W-REAL-DB-2-BIDBUser],				
		'select		
		LiquidityAccountName		
,LiquidityAccountID				
FROM [etoro].[Trade].[LiquidityAccounts]  TP WITH(NOLOCK)				'
)) c ON c.LiquidityAccountID = PP_DD_dist_avg_ask_per_lp.LiquidityAccountID
left join 
(Select p.InstrumentID, Symbol, Priority1 From
(select distinct IRS.InstrumentID,Symbol  From  [AZR-W-REAL-DB-2-BIDBUser].etoro.Price.InstrumentRateSources IRS left join  [AZR-W-REAL-DB-2-BIDBUser].etoro.Price.AccountRateSource ARS on IRS.AccountRateSourceID = ARS.AccountRateSourceID
 left join [AZR-W-REAL-DB-2-BIDBUser].etoro.Trade.InstrumentMetaData TM on IRS.InstrumentID=TM.InstrumentID)p
left join
(select IRS.InstrumentID,Name  as Priority1 From [AZR-W-REAL-DB-2-BIDBUser].etoro.Price.InstrumentRateSources IRS left join [AZR-W-REAL-DB-2-BIDBUser].etoro.Price.AccountRateSource ARS on IRS.AccountRateSourceID = ARS.AccountRateSourceID Where Priority=10 )a on p.InstrumentID=a.InstrumentID) boo on boo.InstrumentID = [PP_DD_dist_avg_ask_per_lp].InstrumentID