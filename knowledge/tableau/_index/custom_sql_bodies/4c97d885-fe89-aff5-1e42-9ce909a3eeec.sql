SELECT 
([Nixar_TheoreticalHedgeCost_Prod].[DeltaPnl_Long] + [Nixar_TheoreticalHedgeCost_Prod].[DeltaPnl_Short]) * 0.25 AS [StrategyPnL],
  '25DeltaPnl' as StrategyName,
  [Nixar_TheoreticalHedgeCost_Prod].[InstrumentID] AS [InstrumentID],
  [Nixar_TheoreticalHedgeCost_Prod].[InstrumentName] AS [InstrumentName],
  [Nixar_TheoreticalHedgeCost_Prod].[PositionsTime] AS [PositionsTime],
  [Nixar_TheoreticalHedgeCost_Prod].[Sigma] AS [Sigma],
  [Nixar_TheoreticalHedgeCost_Prod].[Strat] AS [Parameters],
  [Nixar_TheoreticalHedgeCost_Prod].[T] AS [T],
  [Nixar_TheoreticalHedgeCost_Prod].[UpdateDate] AS [UpdateDate],
  [Nixar_TheoreticalHedgeCost_Prod].[Zero] AS [Zero],
  ([Nixar_TheoreticalHedgeCost_Prod].[DeltaRatio_Long] + [Nixar_TheoreticalHedgeCost_Prod].[DeltaRatio_Short])/2 AS [HedgeRatio]
FROM [dbo].[Nixar_TheoreticalHedgeCost_Prod] [Nixar_TheoreticalHedgeCost_Prod]
union all
SELECT 
([Nixar_TheoreticalHedgeCost_Prod].[DeltaPnl_Long] + [Nixar_TheoreticalHedgeCost_Prod].[DeltaPnl_Short]) * 0.5 AS [StrategyPnL],
  '50DeltaPnl' as StrategyName,
  [Nixar_TheoreticalHedgeCost_Prod].[InstrumentID] AS [InstrumentID],
  [Nixar_TheoreticalHedgeCost_Prod].[InstrumentName] AS [InstrumentName],
  [Nixar_TheoreticalHedgeCost_Prod].[PositionsTime] AS [PositionsTime],
  [Nixar_TheoreticalHedgeCost_Prod].[Sigma] AS [Sigma],
  [Nixar_TheoreticalHedgeCost_Prod].[Strat] AS [Parameters],
  [Nixar_TheoreticalHedgeCost_Prod].[T] AS [T],
  [Nixar_TheoreticalHedgeCost_Prod].[UpdateDate] AS [UpdateDate],
  [Nixar_TheoreticalHedgeCost_Prod].[Zero] AS [Zero],
  ([Nixar_TheoreticalHedgeCost_Prod].[DeltaRatio_Long] + [Nixar_TheoreticalHedgeCost_Prod].[DeltaRatio_Short])/2 AS [HedgeRatio]
FROM [dbo].[Nixar_TheoreticalHedgeCost_Prod] [Nixar_TheoreticalHedgeCost_Prod]
union all
SELECT 
[Nixar_TheoreticalHedgeCost_Prod].[DeltaPnl_Long] + [Nixar_TheoreticalHedgeCost_Prod].[DeltaPnl_Short] AS [StrategyPnL],
  'DeltaPnl' as StrategyName,
  [Nixar_TheoreticalHedgeCost_Prod].[InstrumentID] AS [InstrumentID],
  [Nixar_TheoreticalHedgeCost_Prod].[InstrumentName] AS [InstrumentName],
  [Nixar_TheoreticalHedgeCost_Prod].[PositionsTime] AS [PositionsTime],
  [Nixar_TheoreticalHedgeCost_Prod].[Sigma] AS [Sigma],
  [Nixar_TheoreticalHedgeCost_Prod].[Strat] AS [Parameters],
  [Nixar_TheoreticalHedgeCost_Prod].[T] AS [T],
  [Nixar_TheoreticalHedgeCost_Prod].[UpdateDate] AS [UpdateDate],
  [Nixar_TheoreticalHedgeCost_Prod].[Zero] AS [Zero],
  ([Nixar_TheoreticalHedgeCost_Prod].[DeltaRatio_Long] + [Nixar_TheoreticalHedgeCost_Prod].[DeltaRatio_Short])/2 AS [HedgeRatio]
FROM [dbo].[Nixar_TheoreticalHedgeCost_Prod] [Nixar_TheoreticalHedgeCost_Prod]
union all
SELECT
[Nixar_TheoreticalHedgeCost_Prod].[Hour50NopPnl] AS [StrategyPnL],
  'Hour50NopPnl' as StrategyName,
  [Nixar_TheoreticalHedgeCost_Prod].[InstrumentID] AS [InstrumentID],
  [Nixar_TheoreticalHedgeCost_Prod].[InstrumentName] AS [InstrumentName],
  [Nixar_TheoreticalHedgeCost_Prod].[PositionsTime] AS [PositionsTime],
  [Nixar_TheoreticalHedgeCost_Prod].[Sigma] AS [Sigma],
  [Nixar_TheoreticalHedgeCost_Prod].[Strat] AS [Parameters],
  [Nixar_TheoreticalHedgeCost_Prod].[T] AS [T],
  [Nixar_TheoreticalHedgeCost_Prod].[UpdateDate] AS [UpdateDate],
  [Nixar_TheoreticalHedgeCost_Prod].[Zero] AS [Zero],
  ([Nixar_TheoreticalHedgeCost_Prod].[DeltaRatio_Long] + [Nixar_TheoreticalHedgeCost_Prod].[DeltaRatio_Short])/2 AS [HedgeRatio]
FROM [dbo].[Nixar_TheoreticalHedgeCost_Prod] [Nixar_TheoreticalHedgeCost_Prod]
union all
SELECT
[Nixar_TheoreticalHedgeCost_Prod].[Hour80NopPnl] AS [StrategyPnL],
  'Hour80NopPnl' as StrategyName,
  [Nixar_TheoreticalHedgeCost_Prod].[InstrumentID] AS [InstrumentID],
  [Nixar_TheoreticalHedgeCost_Prod].[InstrumentName] AS [InstrumentName],
  [Nixar_TheoreticalHedgeCost_Prod].[PositionsTime] AS [PositionsTime],
  [Nixar_TheoreticalHedgeCost_Prod].[Sigma] AS [Sigma],
  [Nixar_TheoreticalHedgeCost_Prod].[Strat] AS [Parameters],
  [Nixar_TheoreticalHedgeCost_Prod].[T] AS [T],
  [Nixar_TheoreticalHedgeCost_Prod].[UpdateDate] AS [UpdateDate],
  [Nixar_TheoreticalHedgeCost_Prod].[Zero] AS [Zero],
  ([Nixar_TheoreticalHedgeCost_Prod].[DeltaRatio_Long] + [Nixar_TheoreticalHedgeCost_Prod].[DeltaRatio_Short])/2 AS [HedgeRatio]
FROM [dbo].[Nixar_TheoreticalHedgeCost_Prod] [Nixar_TheoreticalHedgeCost_Prod]
union all
SELECT
[Nixar_TheoreticalHedgeCost_Prod].[HourNopPnl] AS [StrategyPnL],
  'HourNopPnl' as StrategyName,
  [Nixar_TheoreticalHedgeCost_Prod].[InstrumentID] AS [InstrumentID],
  [Nixar_TheoreticalHedgeCost_Prod].[InstrumentName] AS [InstrumentName],
  [Nixar_TheoreticalHedgeCost_Prod].[PositionsTime] AS [PositionsTime],
  [Nixar_TheoreticalHedgeCost_Prod].[Sigma] AS [Sigma],
  [Nixar_TheoreticalHedgeCost_Prod].[Strat] AS [Parameters],
  [Nixar_TheoreticalHedgeCost_Prod].[T] AS [T],
  [Nixar_TheoreticalHedgeCost_Prod].[UpdateDate] AS [UpdateDate],
  [Nixar_TheoreticalHedgeCost_Prod].[Zero] AS [Zero],
  ([Nixar_TheoreticalHedgeCost_Prod].[DeltaRatio_Long] + [Nixar_TheoreticalHedgeCost_Prod].[DeltaRatio_Short])/2 AS [HedgeRatio]
FROM [dbo].[Nixar_TheoreticalHedgeCost_Prod] [Nixar_TheoreticalHedgeCost_Prod]