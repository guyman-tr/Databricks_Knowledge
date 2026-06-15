select aa.* , bb.Zero
FROM
(
SELECT sum([aa].[DeltaPnl_Long] ) AS [DeltaPnl_Long],
 sum( [aa].[DeltaPnl_Short] ) AS [DeltaPnl_Short],
  sum([aa].[DeltaRatio_Long])  AS [DeltaRatio_Long],
  avg([aa].[DeltaRatio_Short] ) AS [DeltaRatio_Short],
  sum([aa].[Hour50NopPnl])  AS [Hour50NopPnl],
  sum([aa].[Hour80NopPnl])  AS [Hour80NopPnl],
  sum([aa].[HourNopPnl]) AS [HourNopPnl],
  [aa].[InstrumentID] AS [InstrumentID],
  [aa].[InstrumentName] AS [InstrumentName],
  cast([aa].[PositionsTime] as DATE) AS [PositionsTime],
  [aa].[Sigma] AS [Sigma],
  [aa].[Strat] AS [Strat],
  [aa].[T] AS [T]
FROM [dbo].[Nixar_TheoreticalHedgeCost_Prod] aa
group by 
  [aa].[InstrumentID],
  [aa].[InstrumentName],
  cast([aa].[PositionsTime] as DATE),
  [aa].[Sigma],
  [aa].[Strat],
  [aa].[T] 
) aa
join 
(select 
Date,InstrumentID, SUM(TotalZero) Zero from BI_DB.dbo.BI_DB_DailyZero_TreeSize_NEW where InstrumentType in ('Commodities', 'Indices') and Date >= '2022-01-01' and HedgeServerID in (21,8,127)
group by Date, InstrumentID
union all
select Date, InstrumentID, SUM(TotalZero) Zero from BI_DB.dbo.BI_DB_DailyZero_TreeSize_NEW where InstrumentType in ('Commodities', 'Indices') and Date < '2022-01-01'
group by Date, InstrumentID
)  bb on aa.InstrumentID = bb.InstrumentID and aa.PositionsTime = bb.Date