# Column Lineage: Dealing_dbo.Dealing_Daily_Slippage_Positions

**Generated**: 2026-03-21 | **Batch**: 5 | **Writer SP**: SP_Slippage_Report
**⚠️ Pipeline status**: POTENTIALLY DECOMMISSIONED — max date 2025-01-11

## Pipeline Summary

```
CopyFromLake.eToroLogs_Real_Hedge_EMSOrders ─┐ (ClientViewRate, CustomerChosenRate, ExecutionID)
DWH_dbo.Dim_Position                        ─┤ (position attributes, rates)
DWH_dbo.Dim_Instrument                      ─┤─► SP_Slippage_Report ──► Dealing_Daily_Slippage_Positions
DWH_dbo.Dim_HistorySplitRatio               ─┤   (all positions,       (DELETE+INSERT by Date)
CopyFromLake.PriceLog_History_CurrencyPrice ─┤    split-adjusted)
DWH_dbo.Dim_Regulation                      ─┘
                                                          │
                                                          └──► Dealing_Best_Execution_Compensation_CBH/HBC
                                                               └──► Dealing_Daily_Latency_Compensation
                                                                    (SlippageInDollar reference)
```

## Column-Level Lineage

| Column | Source Table | Source Column | Transformation |
|--------|-------------|---------------|----------------|
| Date | @Start parameter | — | Report date |
| PositionID | DWH_dbo.Dim_Position | PositionID | Direct |
| CID | DWH_dbo.Dim_Position | CID | Direct |
| InstrumentID | DWH_dbo.Dim_Position | InstrumentID | Direct |
| InstrumentName | DWH_dbo.Dim_Instrument | Name | Direct join |
| InstrumentTypeID | DWH_dbo.Dim_Instrument | InstrumentTypeID | Direct join |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Direct join |
| HedgeServerID | DWH_dbo.Dim_Position | HedgeServerID | Direct |
| MirrorID | DWH_dbo.Dim_Position | MirrorID | Direct |
| IsBuy | DWH_dbo.Dim_Position | IsBuy | Direct |
| OrigIsBuy | DWH_dbo.Dim_Position | OrigIsBuy | Direct |
| ExecutionAmountInUnits | DWH_dbo.Dim_Position | ExecutionAmountInUnits | Direct |
| AmountInUnitsDecimal | DWH_dbo.Dim_Position | AmountInUnitsDecimal × Dim_HistorySplitRatio.AmountRatio | Split-adjusted |
| Occurred | DWH_dbo.Dim_Position | OpenOccurred / CloseOccurred | Action timestamp |
| EndForexRate | DWH_dbo.Dim_Position | OpenForexRate / CloseForexRate × Dim_HistorySplitRatio.PriceRatio | Split-adjusted actual rate |
| ConversionRate | DWH_dbo.Dim_Position | InitForexRate (opens) / EndForexRate (closes) | FX to USD |
| ActionTypeID | DWH_dbo.Dim_Position | ActionTypeID | Direct |
| ActionType | DWH_dbo.Dim_Position | ActionType | Direct |
| HedgingMode | DWH_dbo.Dim_Position | HedgingMode | Direct (CBH / HBC) |
| Precision | DWH_dbo.Dim_Instrument | Precision | Instrument decimal precision |
| IsOpen | — | Derived from ActionType | 1 for open actions, 0 for close actions |
| ExecutionID | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | ExecutionID | From EMS match on PositionID/RequestID |
| StopRate | DWH_dbo.Dim_Position | StopRate | Direct |
| LimitRate | DWH_dbo.Dim_Position | LimitRate | Direct |
| RequestID | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | ClientRequestID | Mapped from EMS |
| ClientViewRate | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | ClientViewRate | Price shown to client; fallback to PriceLog if NULL |
| CustomerChosenRate | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | CustomerChosenRate | Accepted execution rate |
| SlippageInPips | — | (CustomerChosenRate − EndForexRate) / Precision | Computed |
| SlippageInDollar | — | SlippageInPips × AmountInUnitsDecimal × ConversionRate | Computed |
| slippage % | — | ABS((CustomerChosenRate − EndForexRate) / CustomerChosenRate) × sign | Computed; NULL when CustomerChosenRate ≤ 0 |
| UpdateDate | GETDATE() | — | Batch timestamp |
| RequestTime | CopyFromLake.eToroLogs_Real_Hedge_EMSOrders | RequestTime | Client request time from EMS |
| OverThreshold | — | CASE WHEN ABS(slippage%) >= 0.005 THEN 1 ELSE 0 | 0.5% threshold flag |
| OpenSession | DWH_dbo.Dim_Position | OpenSession | Market session ID |
| Volume | DWH_dbo.Dim_Position | Volume | Trade volume |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN via customer snapshot |
| IsSettled | DWH_dbo.Dim_Position | IsSettled | 1=Real, 0=CFD |

## Split Ratio Adjustment

```
Open positions: AmountInUnitsDecimal × Spl.AmountRatio (by CloseOccurred range)
               EndForexRate × Spl.PriceRatio (by CloseOccurred range)
Close positions: AmountInUnitsDecimal × Spl.AmountRatio (by OpenOccurred range)
                EndForexRate × Spl.PriceRatio (by CloseOccurred range)
                InitForexRate × Spl2.PriceRatio (by CloseOccurred range, for init rate)
```

## ETL Pattern

- DELETE WHERE Date=@Start → INSERT DISTINCT
- All position actions included; OverThreshold flags compensation candidates
