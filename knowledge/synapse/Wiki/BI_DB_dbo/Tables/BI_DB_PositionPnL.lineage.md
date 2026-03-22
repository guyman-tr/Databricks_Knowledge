# Column Lineage -- BI_DB_dbo.BI_DB_PositionPnL

**Writer SP**: `BI_DB_dbo.SP_PositionPnL` @dt  
**OpsDB**: Priority 99 -- ProcessType 4 (FinanceReportSPS), Daily  
**ETL pattern**: Temp pipeline (`#Positions` -- `#OpenPositions` -- `#Pre_UnrealizedPnL` -- `#UnrealizedPnL`) -- `INSERT` into `BI_DB_PositionPnL_SWITCH_SINGLE` -- `SP_BI_DB_PositionPnL_SWITCH` -- `UPDATE DailyPnL` vs prior `DateID`

---

## Source tables

| Source | Alias / stage | Role |
|--------|----------------|------|
| DWH_dbo.Dim_Position | `#Positions`, `#OpenPositions` | Open positions, amounts, rates from production PnL fields, settlement, fees |
| DWH_dbo.Fact_CurrencyPriceWithSplit | `#Prices` | Latest 60m spreaded bid/ask per instrument before `@ReportDate` |
| DWH_dbo.Dim_HistorySplitRatio | `#Prices` join | Split window, `PriceRatio`, `AmountRatio` for rate/unit adjustment |
| DWH_dbo.Dim_PositionChangeLog | `#PositionChangeLog_*`, `#IsSettled` | Rewind and delete rules for changes after `@dt` |
| DWH_dbo.Dim_Instrument | `Pair`, `I2`, `I3` | Sell/Buy currency IDs and USD cross instruments for `Price` / `NOP` math |
| #Prices | `PairPrice`, `I2Price`, `I3Price` | Repeated join of EOD rates for pair and conversion legs |

---

## Column-level lineage

| BI_DB_PositionPnL column | Primary source | Source column / object | Transform |
|--------------------------|----------------|------------------------|-----------|
| CID | Dim_Position | CID | Filter open positions; passthrough |
| PositionID | Dim_Position | PositionID | Passthrough; distribution key |
| InstrumentID | Dim_Position | InstrumentID | Passthrough |
| MirrorID | Dim_Position | MirrorID | Passthrough |
| Commission | Dim_Position | Commission | Passthrough |
| InitForexRate | Dim_Position + Dim_HistorySplitRatio + #Prices | InitForexRate, PriceRatio, SplitMaxDate | Divide by `PriceRatio` when open/close span split |
| SpreadedPipBid | Dim_Position | SpreadedPipBid | Passthrough |
| SpreadedPipAsk | Dim_Position | SpreadedPipAsk | Passthrough |
| PositionPnL | Dim_Position | PnLInDollars | Replaces legacy computed PnL (mapped as `PositionPnL` in `#UnrealizedPnL`) |
| Price | #Pre_UnrealizedPnL | computed | `(Bid/Ask - InitForexRate) * USD FX chain` × unit scaling from `Dim_Instrument` joins and `#Prices` |
| HedgeServerID | Dim_Position | HedgeServerID | Passthrough |
| Amount | Dim_Position + PositionChangeLog | Amount, PreviousAmount | UPDATE to `PreviousAmount` when first change type 1/12 after `@dt` |
| AmountInUnitsDecimal | Dim_Position + PositionChangeLog + split | AmountInUnitsDecimal, PreviousAmountInUnits, AmountRatio | Split adjust; UPDATE units from first partial-close row |
| LimitRate | Dim_Position | LimitRate | Passthrough |
| StopRate | Dim_Position + PositionChangeLog | StopRate, PreviousStopRate | UPDATE to `PreviousStopRate` when first change type 1/12 after `@dt` |
| IsBuy | Dim_Position | IsBuy | Passthrough |
| Occurred | Dim_Position | OpenOccurred | Renamed as Occurred |
| Date | SP parameter | @dt | Literal |
| DateID | SP parameter | @dt | `CAST(CONVERT(CHAR(8),@dt,112) AS INT)` |
| UpdateDate | n/a | GETDATE() | Set at INSERT into switch table |
| IsSettled | Dim_Position + PositionChangeLog | IsSettled, PreviousIsSettled | UPDATE from first `ChangeTypeID=13` when values differ |
| NOP | #Pre_UnrealizedPnL | computed | Units × pair bid/ask × `(2*IsBuy-1)` × USD conversion chain |
| DailyPnL | BI_DB_PositionPnL (self) | PositionPnL | `A.PositionPnL - ISNULL(B.PositionPnL,0)` for `B.DateID = @PreviousDateINT` |
| Leverage | Dim_Position | Leverage | Passthrough |
| RateBid | Fact_CurrencyPriceWithSplit + split + IsDiscounted | BidSpreaded / Bid, PriceRatio | Latest price row `rn=1`; split adjust; discounted uses `BidLastWithoutSpread` path |
| RateAsk | Fact_CurrencyPriceWithSplit + split | AskSpreaded, PriceRatio | Latest price row; split adjust |
| USD_CR | Dim_Position | CurrentConversionRate | Aliased from HPOS in `#Pre_UnrealizedPnL` |
| SettlementTypeID | Dim_Position | SettlementTypeID | Passthrough |
| EstimateCloseFeeForCFD | Dim_Position | EstimateCloseFeeForCFD | Passthrough |
| EstimateCloseFeeOnOpenByUnits | Dim_Position | EstimateCloseFeeOnOpenByUnits | Passthrough |
| EstimateCloseFeeOnOpen | Dim_Position | EstimateCloseFeeOnOpen | Passthrough |
| Close_PnLInDollars | Dim_Position | Close_PnLInDollars | Passthrough |
| Close_CalculationRate | Dim_Position | Close_CalculationRate | Passthrough |
| Close_ConversionRate | Dim_Position | Close_ConversionRate | Passthrough |
| Close_PriceType | Dim_Position | Close_PriceType | Passthrough |
| CurrentCalculationRate | Dim_Position | CurrentCalculationRate | Passthrough |
| CurrentConversionRate | Dim_Position | CurrentConversionRate | Passthrough |
| Close_NOP | #Pre_UnrealizedPnL | computed | `AmountInUnitsDecimal * Close_CalculationRate * Close_ConversionRate` |
| Current_NOP | #Pre_UnrealizedPnL | computed | `AmountInUnitsDecimal * CurrentCalculationRate * CurrentConversionRate` |

**Production bridge (high level)**: `Dim_Position` is fed from eToro Trade position and open-position PnL sources (see `DWH_dbo.Dim_Position` wiki); this table is the **Synapse BI_DB daily snapshot** of that state plus EOD rates and SP-side rewind/split/NOP/Price math.

---

## Switch / partition objects

| Object | Role |
|--------|------|
| BI_DB_dbo.BI_DB_PositionPnL_SWITCH_SINGLE | Staging table for the load day; same partition function boundaries as main |
| BI_DB_dbo.BI_DB_PositionPnL_SWITCH | Switch partner used by `SP_BI_DB_PositionPnL_SWITCH` |
| BI_DB_dbo.BI_DB_PositionPnL | Final partitioned table after swap |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
