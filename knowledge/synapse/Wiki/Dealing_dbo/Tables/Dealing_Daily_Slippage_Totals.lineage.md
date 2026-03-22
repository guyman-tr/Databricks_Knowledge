---
object: Dealing_Daily_Slippage_Totals
schema: Dealing_dbo
type: table
lineage_type: column
batch: 11
---

## Column Lineage — Dealing_Daily_Slippage_Totals

Source SP: `Dealing_dbo.SP_Slippage_Report`

### Column-Level Lineage

| Column | Source Expression | Source Table(s) | Tier |
|--------|-------------------|-----------------|------|
| Date | `@Start` parameter | SP parameter | 2 |
| InstrumentID | `A.InstrumentID` from #NEW | DWH_dbo.Dim_Position → Dim_Instrument | 1 |
| InstrumentName | `A.InstrumentName` | DWH_dbo.Dim_Instrument | 2 |
| InstrumentType | `A.InstrumentType` | DWH_dbo.Dim_Instrument | 2 |
| ActionType | `A.ActionType` (from Dim_ClosePositionReason or derivation) | Dim_ClosePositionReason + derived | 2 |
| [Total No of Trades] | `COUNT(1)` | Aggregated from #NEW | 2 |
| [Trades with Positive Slippage] | `SUM(CASE WHEN SlippageInDollar > 0 THEN 1 ELSE 0 END)` | Computed | 2 |
| [Trades with Negative Slippage] | `SUM(CASE WHEN SlippageInDollar < 0 THEN 1 ELSE 0 END)` | Computed | 2 |
| [Total Slippage $] | `SUM(SlippageInDollar)` where `SlippageInDollar=(IsBuy=1?+1:-1)×(CustomerChosenRate−EndForexRate)×AmountInUnitsDecimal×ConversionRate` | Computed | 2 |
| [Total Profit $] | `SUM(CASE WHEN SlippageInDollar > 0 THEN SlippageInDollar ELSE 0 END)` | Computed | 2 |
| [Total Loss $] | `SUM(CASE WHEN SlippageInDollar < 0 THEN SlippageInDollar ELSE 0 END)` | Computed | 2 |
| UpdateDate | `GETDATE()` | System timestamp | 2 |
| OverThreshold | `CASE WHEN ABS(Value) < ABS((CustomerChosenRate−EndForexRate)/CustomerChosenRate) THEN 1 ELSE 0 END` | Computed + #ValuesPerAssetClass (Value=0.005) | 2 |
| OpenSession | `CASE WHEN Occurred BETWEEN OpenTimeUTC AND DATEADD(MINUTE,5,OpenTimeUTC) THEN 1 ELSE 0 END` | External_CalendarDB_Market_MergedDailySchedules | 2 |
| HedgingMode | `CASE WHEN HedgeExecutionModeID=1 THEN 'HBC' ELSE 'CBH' END` | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | 2 |
| [Volume of Trades with Positive Slippage] | `SUM(CASE WHEN SlippageInDollar > 0 THEN CAST(Volume AS BIGINT) ELSE 0 END)` | DWH_dbo.Dim_Position | 2 |
| [Volume of Trades with Negative Slippage] | `SUM(CASE WHEN SlippageInDollar < 0 THEN CAST(Volume AS BIGINT) ELSE 0 END)` | DWH_dbo.Dim_Position | 2 |
| [Total Volume] | `SUM(CAST(Volume AS BIGINT))` | DWH_dbo.Dim_Position | 2 |
| Regulation | `DWH_dbo.Dim_Regulation.Name` | Fact_SnapshotCustomer + Dim_Regulation | 2 |
| WithinFirst5Minutes_MarketHours | `CASE WHEN RequestCloseOccurred BETWEEN OpenTimeUTC AND DATEADD(MINUTE,5,OpenTimeUTC) THEN 1 ELSE 0 END` | External_CalendarDB_Market_MergedDailySchedules | 2 |
| IsSettled | `HP.IsSettled` | DWH_dbo.Dim_Position | 2 |

### Pipeline Summary

```
DWH_dbo.Dim_Position  (positions: Closed, Opened, OpenOpen)
    + CopyFromLake.eToroLogs_Real_Hedge_EMSOrders  (HedgingMode, ClientViewRate)
    + DWH_dbo.Dim_HistorySplitRatio  (split adjustments)
    + Market Hours data  (OpenSession, WithinFirst5Minutes_MarketHours)
    + CustomerChosenRate logic  (StopRate / LimitRate / ClientViewRate)
    + ConversionRate logic  (USD conversion)
    │
    ▼  #NEW  (SlippageInDollar = (IsBuy=1?+1:-1)×(CustomerChosenRate−EndForexRate)×Units×ConvRate)
    │
    ▼  GROUP BY InstrumentID, ActionType, HedgingMode, OverThreshold, OpenSession, Regulation,
                WithinFirst5Minutes_MarketHours, IsSettled
    │
    ▼
Dealing_dbo.Dealing_Daily_Slippage_Totals
```
