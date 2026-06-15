SELECT [Nixar_TheoreticalHedgeCost].[25DeltaPnl] AS [25DeltaPnl],
  [Nixar_TheoreticalHedgeCost].[50DeltaPnl] AS [50DeltaPnl],
  [Nixar_TheoreticalHedgeCost].[DeltaPnl] AS [DeltaPnl],
  [Nixar_TheoreticalHedgeCost].[Hour50NopPnl] AS [Hour50NopPnl],
  [Nixar_TheoreticalHedgeCost].[Hour80NopPnl] AS [Hour80NopPnl],
  [Nixar_TheoreticalHedgeCost].[HourNopPnl] AS [HourNopPnl],
  [Nixar_TheoreticalHedgeCost].[InstrumentID] AS [InstrumentID],
  [Nixar_TheoreticalHedgeCost].[InstrumentName] AS [InstrumentName],
  [Nixar_TheoreticalHedgeCost].[Sigma] AS [Sigma],
  [Nixar_TheoreticalHedgeCost].[Strat] AS [Strat],
  [Nixar_TheoreticalHedgeCost].[T] AS [T],
  [Nixar_TheoreticalHedgeCost].[Zero] AS [Zero],
  [Nixar_TheoreticalHedgeCost].[index] AS [index]
FROM [dbo].[Nixar_TheoreticalHedgeCost_Squared_150_100_All] [Nixar_TheoreticalHedgeCost]