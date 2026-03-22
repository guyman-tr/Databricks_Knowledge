---
object: Dealing_Daily_Slippage_Totals_TriggerVSReceived
schema: Dealing_dbo
type: table
lineage_type: column
batch: 11
---

## Column Lineage — Dealing_Daily_Slippage_Totals_TriggerVSReceived

Source SP: `Dealing_dbo.SP_Slippage_Report`

### Column-Level Lineage

| Column | Source Expression | Source Table(s) | Tier |
|--------|-------------------|-----------------|------|
| Date | `@Start` parameter | SP parameter | 2 |
| InstrumentID | `A.InstrumentID` from #NEW | DWH_dbo.Dim_Position → Dim_Instrument | 1 |
| InstrumentName | `A.InstrumentName` | DWH_dbo.Dim_Instrument | 2 |
| InstrumentType | `A.InstrumentType` | DWH_dbo.Dim_Instrument | 2 |
| ActionType | `A.ActionType` | Dim_ClosePositionReason + derived | 2 |
| [Total No of Trades] | `COUNT(1)` | Aggregated from #NEW | 2 |
| [Trades with Positive Slippage] | `SUM(CASE WHEN RequestOccurred_SlippageInDollar > 0 THEN 1 ELSE 0 END)` | Computed | 2 |
| [Trades with Negative Slippage] | `SUM(CASE WHEN RequestOccurred_SlippageInDollar < 0 THEN 1 ELSE 0 END)` | Computed | 2 |
| [Total Slippage $] | `SUM(RequestOccurred_SlippageInDollar)` = `(IsBuy=1?+1:-1)×(RequestOccurred_CustomerChosenRate−EndForexRate)×AmountInUnitsDecimal×ConversionRate` | Computed | 2 |
| [Total Profit $] | `SUM(CASE WHEN RequestOccurred_SlippageInDollar > 0 THEN value ELSE 0 END)` | Computed | 2 |
| [Total Loss $] | `SUM(CASE WHEN RequestOccurred_SlippageInDollar < 0 THEN value ELSE 0 END)` | Computed | 2 |
| UpdateDate | `GETDATE()` | System timestamp | 2 |
| OverThreshold | `CASE WHEN ABS(Value) < ABS((RequestOccurred_CustomerChosenRate−EndForexRate)/RequestOccurred_CustomerChosenRate) THEN 1 ELSE 0 END` | Computed + #ValuesPerAssetClass | 2 |
| OpenSession | `CASE WHEN Occurred BETWEEN OpenTimeUTC AND DATEADD(MINUTE,5,OpenTimeUTC) THEN 1 ELSE 0 END` | External_CalendarDB_Market_MergedDailySchedules | 2 |
| HedgingMode | `CASE WHEN HedgeExecutionModeID=1 THEN 'HBC' ELSE 'CBH' END` | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | 2 |
| [Volume of Trades with Positive Slippage] | `SUM(CASE WHEN RequestOccurred_SlippageInDollar > 0 THEN CAST(Volume AS BIGINT) ELSE 0 END)` | DWH_dbo.Dim_Position | 2 |
| [Volume of Trades with Negative Slippage] | `SUM(CASE WHEN RequestOccurred_SlippageInDollar < 0 THEN CAST(Volume AS BIGINT) ELSE 0 END)` | DWH_dbo.Dim_Position | 2 |
| [Total Volume] | `SUM(CAST(Volume AS BIGINT))` | DWH_dbo.Dim_Position | 2 |
| Regulation | `DWH_dbo.Dim_Regulation.Name` | Fact_SnapshotCustomer + Dim_Regulation | 2 |

### Key Difference from Non-TVR

Both tables read from `#NEW` in the same SP. The aggregation SELECTs differ only in which slippage column is used:
- Non-TVR: `SUM(SlippageInDollar)` based on `CustomerChosenRate`
- **TVR (this table)**: `SUM(RequestOccurred_SlippageInDollar)` based on `RequestOccurred_CustomerChosenRate`

The GROUP BY dimensions are identical except the non-TVR table also groups by `WithinFirst5Minutes_MarketHours` and `IsSettled`.

### RequestOccurred_CustomerChosenRate Derivation Path

```
CopyFromLake.PriceLog_History_CurrencyPrice
    CROSS APPLY: ReceivedOnPriceServer ≤ RequestCloseOccurred
    + Split adjustment (Dim_HistorySplitRatio)
    → #PriceFromRequestOccurred (split-adjusted Bid/Ask at request time)

DWH_dbo.Dim_Position (InitForex_AskSpreaded, CommissionByUnits)
    → #Add_Spread (spread component: CBH or HBC)

#TotalData:
    RequestOccurred_CustomerChosenRate =
      Close/SL/TP: IsBuy=1→Bid−Spread; IsBuy=0→Ask+Spread
      Open: IsBuy=1→Ask+Spread; IsBuy=0→Bid−Spread
    (fallback to CustomerChosenRate when NULL)
```
