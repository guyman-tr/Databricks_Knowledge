select  aa.Date as [index], bb.InstrumentID, aa.InstrumentName
, aa.HourNopPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as HourNopPnl
, aa.Hour80NopPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as Hour80NopPnl
, aa.Zero
, aa.DeltaPnl * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end   as DeltaPnl
, aa.[50DeltaPnl] * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end  as [50DeltaPnl]   
, aa.[25DeltaPnl] * case when bb.SellCurrencyID = 1 then 1 when (bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) then  ((Ask+Bid)/2) else  1/((Ask+Bid)/2) end    as [25DeltaPnl]
, aa.T
, aa.Sigma
, aa.Strat
from Dealing_Dev.dbo.Nixar_TheoreticalHedgeCost_FX_Sq aa
join DWH.dbo.Dim_Instrument bb on aa.InstrumentName = bb.Name collate Latin1_General_100_BIN
left join DWH.dbo.Dim_Instrument cc on ((bb.SellCurrencyID = cc.BuyCurrencyID and cc.SellCurrencyID = 1) or (bb.SellCurrencyID = cc.SellCurrencyID and cc.BuyCurrencyID = 1)) and cc.InstrumentTypeID = 1 and cc.IsMajor = 'Yes'
left join   DWH.dbo.Fact_CurrencyPriceWithSplit dd on cast(aa.[Date] as DATE) = dd.OccurredDate and cc.InstrumentID = dd.InstrumentID