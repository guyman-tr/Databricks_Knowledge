---
object: Dealing_Daily_Slippage_Positions_TriggerVSReceived
schema: Dealing_dbo
type: table
lineage_type: column
batch: 11
---

## Column Lineage — Dealing_Daily_Slippage_Positions_TriggerVSReceived

Source SP: `Dealing_dbo.SP_Slippage_Report`

### Column-Level Lineage

| Column | Source Expression | Source Table(s) | Tier |
|--------|-------------------|-----------------|------|
| Date | `@Start` parameter | SP parameter | 2 |
| PositionID | `HP.PositionID` | DWH_dbo.Dim_Position | 2 |
| CID | `HP.CID` | DWH_dbo.Dim_Position | 1 |
| InstrumentID | `HP.InstrumentID` | DWH_dbo.Dim_Position | 1 |
| InstrumentName | `TGI.Name` | DWH_dbo.Dim_Instrument | 2 |
| InstrumentTypeID | `TGI.InstrumentTypeID` | DWH_dbo.Dim_Instrument | 2 |
| InstrumentType | `TGI.InstrumentType` | DWH_dbo.Dim_Instrument | 2 |
| HedgeServerID | `HP.HedgeServerID` | DWH_dbo.Dim_Position | 2 |
| MirrorID | `HP.MirrorID` | DWH_dbo.Dim_Position | 2 |
| IsBuy | Closed: `CASE WHEN HP.IsBuy=1 THEN 0 ELSE 1 END`; Open: `HP.IsBuy` | DWH_dbo.Dim_Position | 2 |
| OrigIsBuy | `HP.IsBuy` (original, not inverted) | DWH_dbo.Dim_Position | 2 |
| ExecutionAmountInUnits | `CONVERT(MONEY, hbc.RequestedAmountInUnits)` | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | 2 |
| AmountInUnitsDecimal | `HP.AmountInUnitsDecimal × COALESCE(Spl.AmountRatio, 1)` | Dim_Position + Dim_HistorySplitRatio | 2 |
| Occurred | Closed: `CloseOccurred`; Open/OpenOpen: `OpenOccurred` | DWH_dbo.Dim_Position | 2 |
| EndForexRate | Closed: `HP.EndForexRate × COALESCE(Spl.PriceRatio,1)`; Open: `HP.InitForexRate × COALESCE(Spl.PriceRatio,1)` | Dim_Position + Dim_HistorySplitRatio | 2 |
| ConversionRate | CASE: SellCurrencyID=1→1; BuyCurrencyID=1→1/EndForexRate; else UnitMargin/InitForexRate | Dim_Position + Dim_Instrument | 2 |
| ActionTypeID | Closed: `HP.ClosePositionReasonID`; Open: NULL | DWH_dbo.Dim_Position | 2 |
| ActionType | Closed: `Dim_ClosePositionReason.Name`; Open: 'Manual Open'/'Order' from HistoryOrderForOpen | Dim_ClosePositionReason + CopyFromLake.etoro_DWH_HistoryOrderForOpen | 2 |
| HedgingMode | `CASE WHEN HedgeExecutionModeID=1 THEN 'HBC' ELSE 'CBH' END` | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | 2 |
| Precision | `TGI.Precision` | DWH_dbo.Dim_Instrument | 2 |
| IsOpen | Closed: 0; Open/OpenOpen: 1 | Derived | 2 |
| ExecutionID | Closed: `HP.EndExecutionID`; Open: `HP.InitExecutionID` | DWH_dbo.Dim_Position | 2 |
| StopRate | `HP.StopRate × COALESCE(Spl.PriceRatio, 1)` | Dim_Position + Dim_HistorySplitRatio | 2 |
| LimitRate | `HP.LimitRate × COALESCE(Spl.PriceRatio, 1)` | Dim_Position + Dim_HistorySplitRatio | 2 |
| RequestID | `hbc.ClientRequestID` (matched via OrderID=ClientRequestID) | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | 2 |
| ClientViewRate | `REL.ClientViewRate × COALESCE(Spl.PriceRatio, 1)` from EMSOrders | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | 2 |
| CustomerChosenRate | CASE ActionTypeID: 1→StopRate, 5→LimitRate, 0/14→ClientViewRate; Open→ClientViewRate | Computed from above | 2 |
| RequestOccurred_SlippageInPips | `ABS(EndForexRate - RequestOccurred_CustomerChosenRate) × 10^Precision` (fallback to CustomerChosenRate) | Computed | 2 |
| RequestOccurred_SlippageInDollar | `(IsBuy=1?+1:-1) × (RequestOccurred_CustomerChosenRate − EndForexRate) × AmountInUnitsDecimal × ConversionRate` | Computed | 2 |
| [RequestOccurred_slippage %] | `±ABS((RequestOccurred_CustomerChosenRate − EndForexRate) / RequestOccurred_CustomerChosenRate)` | Computed | 2 |
| UpdateDate | `GETDATE()` | System timestamp | 2 |
| RequestTime | `REL.RequestTime` | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | 2 |
| OverThreshold | `ABS(Value) < ABS((RequestOccurred_CustomerChosenRate − EndForexRate) / RequestOccurred_CustomerChosenRate)` (Value=0.005 for all) | Computed + #ValuesPerAssetClass | 2 |
| OpenSession | `CASE WHEN Occurred BETWEEN OpenTimeUTC AND DATEADD(MINUTE,5,OpenTimeUTC) THEN 1 ELSE 0 END` | Dealing_staging.External_CalendarDB_Market_MergedDailySchedules | 2 |
| Volume | Closed: `HP.VolumeOnClose`; Open: `HP.Volume` | DWH_dbo.Dim_Position | 2 |
| Regulation | `DWH_dbo.Dim_Regulation.Name` | Fact_SnapshotCustomer + Dim_Regulation | 2 |

### Pipeline Flow

```
DWH_dbo.Dim_Position + DWH_dbo.Dim_HistorySplitRatio
    │  (#Closed + #Opened + #OpenOpen)
    ├── CopyFromLake.eToroLogs_Real_Hedge_EMSOrders  (#HedgingMode: HedgingMode, ClientViewRate, RequestTime)
    ├── DWH_dbo.Dim_Customer (IsValidCustomer filter)
    ├── DWH_dbo.Fact_SnapshotCustomer + Dim_Regulation (Regulation)
    ├── DWH_dbo.Dim_ClosePositionReason (ActionType text)
    └── CopyFromLake.etoro_DWH_HistoryOrderForClose/Open (manual vs Order classification)
    │
    ▼  #SplitAdjustments → #Main → #TotalData_WithMarketHours → #Main2
    │
    ├── CopyFromLake.PriceLog_History_CurrencyPrice  (#CurrencyPrice)
    │   CROSS APPLY: ReceivedOnPriceServer ≤ RequestCloseOccurred
    │   → #PriceFromRequestOccurred (split-adjusted Bid/Ask)
    ├── DWH_dbo.Dim_Position (Spread calculation: InitForex_AskSpreaded, CommissionByUnits)
    │   → #Add_Spread
    │
    ▼  #TotalData (RequestOccurred_CustomerChosenRate = price ± spread)
    ▼  #NEW (RequestOccurred_SlippageInPips, RequestOccurred_SlippageInDollar, slippage%)
    │
    ▼
Dealing_dbo.Dealing_Daily_Slippage_Positions_TriggerVSReceived
```
