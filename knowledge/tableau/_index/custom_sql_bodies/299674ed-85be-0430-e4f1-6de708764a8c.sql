SELECT 
[Nixar_TheoreticalHedgeCost_Prod].[25DeltaPnl] AS [StrategyPnL],
  '25DeltaPnl' as StrategyName,
  [Nixar_TheoreticalHedgeCost_Prod].[InstrumentID] AS [InstrumentID],
  [Nixar_TheoreticalHedgeCost_Prod].[InstrumentName] AS [InstrumentName],
  [Nixar_TheoreticalHedgeCost_Prod].[PositionsTime] AS [PositionsTime],
  [Nixar_TheoreticalHedgeCost_Prod].[Sigma] AS [Sigma],
  [Nixar_TheoreticalHedgeCost_Prod].[Strat] AS [Parameters],
  [Nixar_TheoreticalHedgeCost_Prod].[T] AS [T],
  [Nixar_TheoreticalHedgeCost_Prod].[Zero] AS [Zero],
  [Nixar_TheoreticalHedgeCost_Prod].[HedgeRatio] AS [HedgeRatio]
FROM 
(
select  aa.[PositionsTime], bb.InstrumentID, aa.InstrumentName
, aa.HourNopPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as HourNopPnl
, aa.Hour80NopPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as Hour80NopPnl
, aa.Zero
, aa.DeltaPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as DeltaPnl
, aa.[50DeltaPnl] * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end  as [50DeltaPnl]   
, aa.[25DeltaPnl] * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end    as [25DeltaPnl]
, aa.T
, aa.Sigma
, aa.Strat
, aa.HedgeRatio
from Dealing_Dev.dbo.Nixar_TheoreticalHedgeCost_Prod_FX aa
join DWH.dbo.Dim_Instrument bb on aa.InstrumentName = bb.Name collate Latin1_General_100_BIN
left join DWH.dbo.Dim_Instrument cc on ((bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) or (bb.SellCurrencyID = cc.SellCurrencyID and cc.BuyCurrencyID = 1)) and cc.InstrumentTypeID = 1 and cc.IsMajor = 'Yes'
left join   DWH.dbo.Fact_CurrencyPriceWithSplit dd on cast(aa.[PositionsTime] as DATE) = dd.OccurredDate and cc.InstrumentID = dd.InstrumentID
) [Nixar_TheoreticalHedgeCost_Prod]
union all
SELECT 
[Nixar_TheoreticalHedgeCost_Prod].[50DeltaPnl] AS [StrategyPnL],
  '50DeltaPnl' as StrategyName,
  [Nixar_TheoreticalHedgeCost_Prod].[InstrumentID] AS [InstrumentID],
  [Nixar_TheoreticalHedgeCost_Prod].[InstrumentName] AS [InstrumentName],
  [Nixar_TheoreticalHedgeCost_Prod].[PositionsTime] AS [PositionsTime],
  [Nixar_TheoreticalHedgeCost_Prod].[Sigma] AS [Sigma],
  [Nixar_TheoreticalHedgeCost_Prod].[Strat] AS [Parameters],
  [Nixar_TheoreticalHedgeCost_Prod].[T] AS [T],
  [Nixar_TheoreticalHedgeCost_Prod].[Zero] AS [Zero],
  [Nixar_TheoreticalHedgeCost_Prod].[HedgeRatio] AS [HedgeRatio]
FROM 
(
select  aa.[PositionsTime], bb.InstrumentID, aa.InstrumentName
, aa.HourNopPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as HourNopPnl
, aa.Hour80NopPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as Hour80NopPnl
, aa.Zero
, aa.DeltaPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as DeltaPnl
, aa.[50DeltaPnl] * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end  as [50DeltaPnl]   
, aa.[25DeltaPnl] * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end    as [25DeltaPnl]
, aa.T
, aa.Sigma
, aa.Strat
, aa.HedgeRatio
from Dealing_Dev.dbo.Nixar_TheoreticalHedgeCost_Prod_FX aa
join DWH.dbo.Dim_Instrument bb on aa.InstrumentName = bb.Name collate Latin1_General_100_BIN
left join DWH.dbo.Dim_Instrument cc on ((bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) or (bb.SellCurrencyID = cc.SellCurrencyID and cc.BuyCurrencyID = 1)) and cc.InstrumentTypeID = 1 and cc.IsMajor = 'Yes'
left join   DWH.dbo.Fact_CurrencyPriceWithSplit dd on cast(aa.[PositionsTime] as DATE) = dd.OccurredDate and cc.InstrumentID = dd.InstrumentID
)

 [Nixar_TheoreticalHedgeCost_Prod]
union all
SELECT 
[Nixar_TheoreticalHedgeCost_Prod].[DeltaPnl] AS [StrategyPnL],
  'DeltaPnl' as StrategyName,
  [Nixar_TheoreticalHedgeCost_Prod].[InstrumentID] AS [InstrumentID],
  [Nixar_TheoreticalHedgeCost_Prod].[InstrumentName] AS [InstrumentName],
  [Nixar_TheoreticalHedgeCost_Prod].[PositionsTime] AS [PositionsTime],
  [Nixar_TheoreticalHedgeCost_Prod].[Sigma] AS [Sigma],
  [Nixar_TheoreticalHedgeCost_Prod].[Strat] AS [Parameters],
  [Nixar_TheoreticalHedgeCost_Prod].[T] AS [T],
  [Nixar_TheoreticalHedgeCost_Prod].[Zero] AS [Zero],
  [Nixar_TheoreticalHedgeCost_Prod].[HedgeRatio] AS [HedgeRatio]
FROM 
(
select  aa.[PositionsTime], bb.InstrumentID, aa.InstrumentName
, aa.HourNopPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as HourNopPnl
, aa.Hour80NopPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as Hour80NopPnl
, aa.Zero
, aa.DeltaPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as DeltaPnl
, aa.[50DeltaPnl] * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end  as [50DeltaPnl]   
, aa.[25DeltaPnl] * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end    as [25DeltaPnl]
, aa.T
, aa.Sigma
, aa.Strat
, aa.HedgeRatio
from Dealing_Dev.dbo.Nixar_TheoreticalHedgeCost_Prod_FX aa
join DWH.dbo.Dim_Instrument bb on aa.InstrumentName = bb.Name collate Latin1_General_100_BIN
left join DWH.dbo.Dim_Instrument cc on ((bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) or (bb.SellCurrencyID = cc.SellCurrencyID and cc.BuyCurrencyID = 1)) and cc.InstrumentTypeID = 1 and cc.IsMajor = 'Yes'
left join   DWH.dbo.Fact_CurrencyPriceWithSplit dd on cast(aa.[PositionsTime] as DATE) = dd.OccurredDate and cc.InstrumentID = dd.InstrumentID
)
 [Nixar_TheoreticalHedgeCost_Prod]
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
  [Nixar_TheoreticalHedgeCost_Prod].[Zero] AS [Zero],
  [Nixar_TheoreticalHedgeCost_Prod].[HedgeRatio] AS [HedgeRatio]
FROM
(
select  aa.[PositionsTime], bb.InstrumentID, aa.InstrumentName
, aa.HourNopPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as HourNopPnl
, 0.5*aa.HourNopPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as Hour50NopPnl
, aa.Hour80NopPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as Hour80NopPnl
, aa.Zero
, aa.DeltaPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as DeltaPnl
, aa.[50DeltaPnl] * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end  as [50DeltaPnl]   
, aa.[25DeltaPnl] * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end    as [25DeltaPnl]
, aa.T
, aa.Sigma
, aa.Strat
, aa.HedgeRatio
from Dealing_Dev.dbo.Nixar_TheoreticalHedgeCost_Prod_FX aa
join DWH.dbo.Dim_Instrument bb on aa.InstrumentName = bb.Name collate Latin1_General_100_BIN
left join DWH.dbo.Dim_Instrument cc on ((bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) or (bb.SellCurrencyID = cc.SellCurrencyID and cc.BuyCurrencyID = 1)) and cc.InstrumentTypeID = 1 and cc.IsMajor = 'Yes'
left join   DWH.dbo.Fact_CurrencyPriceWithSplit dd on cast(aa.[PositionsTime] as DATE) = dd.OccurredDate and cc.InstrumentID = dd.InstrumentID
)
[Nixar_TheoreticalHedgeCost_Prod]
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
  [Nixar_TheoreticalHedgeCost_Prod].[Zero] AS [Zero],
  [Nixar_TheoreticalHedgeCost_Prod].[HedgeRatio] AS [HedgeRatio]
FROM [dbo].[Nixar_TheoreticalHedgeCost_Prod_FX] [Nixar_TheoreticalHedgeCost_Prod]
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
  [Nixar_TheoreticalHedgeCost_Prod].[Zero] AS [Zero],
  [Nixar_TheoreticalHedgeCost_Prod].[HedgeRatio] AS [HedgeRatio]
FROM 
(
select  aa.[PositionsTime], bb.InstrumentID, aa.InstrumentName
, aa.HourNopPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as HourNopPnl
, aa.Hour80NopPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as Hour80NopPnl
, aa.Zero
, aa.DeltaPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as DeltaPnl
, aa.[50DeltaPnl] * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end  as [50DeltaPnl]   
, aa.[25DeltaPnl] * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end    as [25DeltaPnl]
, aa.T
, aa.Sigma
, aa.Strat
, aa.HedgeRatio
from Dealing_Dev.dbo.Nixar_TheoreticalHedgeCost_Prod_FX aa
join DWH.dbo.Dim_Instrument bb on aa.InstrumentName = bb.Name collate Latin1_General_100_BIN
left join DWH.dbo.Dim_Instrument cc on ((bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) or (bb.SellCurrencyID = cc.SellCurrencyID and cc.BuyCurrencyID = 1)) and cc.InstrumentTypeID = 1 and cc.IsMajor = 'Yes'
left join   DWH.dbo.Fact_CurrencyPriceWithSplit dd on cast(aa.[PositionsTime] as DATE) = dd.OccurredDate and cc.InstrumentID = dd.InstrumentID
)
[Nixar_TheoreticalHedgeCost_Prod]