# BI_DB_dbo.BI_DB_Finance_Real_Futures_Custody_And_Transfers — Column Lineage

## Source Objects

| # | Source Object | Type | Role |
|---|--------------|------|------|
| 1 | BI_DB_dbo.BI_DB_Futures_Finance_Prep_Data | Table | Position change ledger (parent/child events, amounts, rates, lot counts) |
| 2 | DWH_dbo.Dim_Instrument_Snapshot | Table | Futures instrument snapshot (IsFuture=1): Multiplier, ProviderMarginPerLot, eToroMarginPerLot |
| 3 | DWH_dbo.Fact_Settlement_Prices | Table | Daily settlement prices per instrument |
| 4 | BI_DB_dbo.External_Fivetran_google_sheets_adj | External Table | SQF adjustment values from Google Sheets via Fivetran |
| 5 | Dealing_dbo.External_Gold_Dealing_Marex_Trader_OrderID | External Table | Marex trader tag50 IDs per position |
| 6 | DWH_dbo.Dim_Position | Table | HedgeServerID, ReopenForPositionID, IsReOpen, RegulationIDOnOpen, ClosePositionReasonID |
| 7 | DWH_dbo.Dim_Instrument | Table | InstrumentName |
| 8 | DWH_dbo.Dim_ClosePositionReason | Table | Close reason name lookup |
| 9 | DWH_dbo.Dim_Regulation | Table | Regulation name lookup |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform |
|---|---------------|-------------|---------------|-----------|
| 1 | ReportDateID | ETL param | @dateID | The report run date |
| 2 | SnapshotDateID | BI_DB_Futures_Finance_Prep_Data | DateID | The historical snapshot date for this event |
| 3 | PositionID | BI_DB_Futures_Finance_Prep_Data | PositionID | Child position (from CHILDS CTE) — NULL if parent-only |
| 4 | OriginalPositionID | BI_DB_Futures_Finance_Prep_Data | OriginalPositionID | Parent/original position ID |
| 5 | CID | BI_DB_Futures_Finance_Prep_Data | CID | Passthrough |
| 6 | InstrumentID | BI_DB_Futures_Finance_Prep_Data | InstrumentID | Passthrough |
| 7 | ActionType | BI_DB_Futures_Finance_Prep_Data | ActionType | Open, Hold, PartialCloseOrig, CloseOrig, EditSLIncreaseAmount, EditSLReduceAmount, ChildClose |
| 8 | SettlementTime | BI_DB_Futures_Finance_Prep_Data | SettlementTime | Passthrough |
| 9 | SettlementTimePrev | BI_DB_Futures_Finance_Prep_Data | SettlementTimePrev | Passthrough |
| 10 | Occurred | BI_DB_Futures_Finance_Prep_Data | Occurred | Position change timestamp |
| 11 | OccurredDateID | BI_DB_Futures_Finance_Prep_Data | OccurredDateID | YYYYMMDD of Occurred |
| 12 | ChangeTypeID | BI_DB_Futures_Finance_Prep_Data | ChangeTypeID | Position change type (1=open, 6=close, 11/12=parent/child) |
| 13-15 | PreviousAmount, AmountChanged, NewAmount | BI_DB_Futures_Finance_Prep_Data | Same | USD amount delta chain |
| 16-17 | PreviousStopRate, StopRate | BI_DB_Futures_Finance_Prep_Data | Same | Stop loss rate changes |
| 18-19 | PreviousAmountInUnits, AmountInUnits | Computed | LastKnownAmountInUnits | LAG-filled via correlated subquery + UPDATE |
| 20-21 | LotCountDecimal, PreviousLotCountDecimal | Computed | LastKnownLotCount | LAG-filled, NULLed for ChangeTypeID=1 |
| 22 | IsBuy | BI_DB_Futures_Finance_Prep_Data | IsBuy | 1=long, 0=short |
| 23 | InitForexRate | BI_DB_Futures_Finance_Prep_Data + SQF adj | InitForexRate + ISNULL(adj.Adj, 0) | Adjusted open rate |
| 24 | EndForexRate | BI_DB_Futures_Finance_Prep_Data + SQF adj | COALESCE(child.EndForexRate, parent.EndForexRate) + adj | Adjusted close rate |
| 25-26 | IsStartOfDay, IsEndOfDay | Computed | ROW_NUMBER partitioned by OriginalPositionID, DateID | First/last event of the day |
| 27 | Multiplier | Dim_Instrument_Snapshot | Multiplier | Contract multiplier (OUTER APPLY latest IsFuture=1 snapshot) |
| 28-29 | ProviderMarginPerLot, ProviderMarginPerLotPrev | Dim_Instrument_Snapshot | ProviderMarginPerLot | Current and previous day snapshot |
| 30-31 | eToroMarginPerLot, eToroMarginPerLotPrev | Dim_Instrument_Snapshot | eToroMarginPerLot | Current and previous day snapshot |
| 32-34 | SettlementPrice, SettlementPricePrev, SettlementPriceChange | Fact_Settlement_Prices + SQF adj | SettlementPrice + adj | Adjusted current and previous settlement prices, and delta |
| 35 | ActionLotCount | Computed | CASE on IsBuy × ActionType × LotCount delta | Signed lot count change for this event |
| 36 | RunningLotCount | Computed | SUM(ActionLotCount) OVER partition by OriginalPositionID | Cumulative lot position |
| 37 | TodayBeginLotCountRunning | Computed | LAG(RunningLotCount) | Lot count at start of day |
| 38 | TodayLotCountFinal | Computed | IsEndOfDay RunningLotCount | End-of-day lot count |
| 39 | ProviderMargin | Computed | ABS(TodayLotCountFinal × ProviderMarginPerLot) | EOD provider margin (only on IsEndOfDay=1) |
| 40 | TodayMarexPnL | Computed | (SettlementPrice - InitForexRate/EndForexRate) × ActionLotCount × Multiplier | Marex P&L for this action |
| 41 | MTM | Computed | (SettlementPrice - SettlementPricePrev) × TodayBeginLotCountRunning × Multiplier | Mark-to-market on held positions |
| 42 | PreviousProviderMargin | Computed | LAG of ProviderMargin across days + propagation | Previous day's provider margin |
| 43 | TodayMarexPnLPlusMTM | Computed | TodayMarexPnL + MTM | Combined Marex P&L |
| 44 | ProviderMarginChange | Computed | ProviderMargin - PreviousProviderMargin | Margin delta |
| 45-46 | TransferToMarex, TransferToMarexRunning | Computed | ProviderMarginChange - TodayMarexPnLPlusMTM, SUM running | Cash transfer to Marex and running total |
| 47-48 | InvestedAmountChange, InvestedAmountRunning | Computed | IsBuy × ActionLotCount × eToroMarginPerLot + AmountChanged, SUM running | eToro client invested amount |
| 49 | eToroPnL | Computed | IsBuy direction × (EndRate/SettlementPrice - InitForexRate) × lots × Multiplier | eToro-side P&L |
| 50-51 | ToUser, ToUserRunning | Computed | -InvestedAmountChange + close eToroPnL, SUM running | Cash to/from user |
| 52 | PositionValueAtSettlement | Computed | InvestedAmountRunning + TodayLotCountFinal × Multiplier × (SettlementPrice - InitForexRate) | EOD position value |
| 53 | eToroBalance | Computed | PositionValueAtSettlement - ProviderMargin | EOD eToro custody balance |
| 54 | UpdateDate | ETL | GETDATE() | ETL timestamp |
| 55 | MTMRunning | Computed | SUM(MTM) OVER running | Cumulative MTM |
| 56 | TodayMarexPnLRunning | Computed | SUM(TodayMarexPnL) OVER running | Cumulative Marex P&L |
| 57 | TodayMarexPnLPlusMTMRunning | Computed | SUM(TodayMarexPnLPlusMTM) OVER running | Cumulative combined |
| 58 | OpenPositionsMarexPnLPlusMTM | Computed | TodayMarexPnLPlusMTMRunning WHERE IsEndOfDay=1 AND NOT Close | Open positions Marex P&L+MTM |
| 59 | PreviousMarexPnLPlusMTMRunning | Computed | LAG(TodayMarexPnLPlusMTMRunning) on EOD rows | Previous EOD cumulative |
| 60 | MarexPnLPlusMTMRunningChange | Computed | TodayMarexPnLPlusMTMRunning - PreviousMarexPnLPlusMTMRunning | Day-over-day change |
| 61 | Trader | External_Gold_Dealing_Marex_Trader_OrderID | Trader | Tag50 trader ID, deduped, reopen-corrected |
| 62 | InstrumentName | DWH_dbo.Dim_Instrument | Name | Passthrough |
| 63 | IsOpenEOD | Computed | FIRST_VALUE(ActionType) partitioned by DateID, OriginalPositionID DESC | 0 if last action is CloseOrig, 1 otherwise |
| 64 | HedgeServerID | DWH_dbo.Dim_Position | HedgeServerID | Via OriginalPositionID JOIN |
| 65 | InitForexRateUnAdjusted | BI_DB_Futures_Finance_Prep_Data | InitForexRate | Original unadjusted open rate |
| 66 | EndForexRateUnAdjusted | BI_DB_Futures_Finance_Prep_Data | COALESCE(child, parent) EndForexRate | Original unadjusted close rate |
| 67-69 | SettlementPriceUnAdjusted, SettlementPriceUnAdjustedPrev, SettlementPriceUnAdjustedChange | Fact_Settlement_Prices | SettlementPrice | Unadjusted settlement prices and delta |
| 70-72 | Adj, PreviousAdj, AdjChange | External_Fivetran_google_sheets_adj | adj | SQF adjustment current, previous, delta |
| 73 | ClosePositionReason | DWH_dbo.Dim_ClosePositionReason | Name | Via Dim_Position.ClosePositionReasonID. NULLed when EndForexRate IS NULL. |
| 74 | IsSQF | Computed | CASE WHEN ISNULL(Adj, 0) <> 0 THEN 1 ELSE 0 END | 1 if SQF adjustment applied |
| 75 | Regulation | DWH_dbo.Dim_Regulation | Name | Via Dim_Position.RegulationIDOnOpen (regulation at position open time) |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_Futures_Finance_Prep_Data (position change ledger)
  |-- PARENTS CTE (ChangeTypeID <> 11) + CHILDS CTE (ChangeTypeID <> 12) ---|
  + BI_DB_dbo.External_Fivetran_google_sheets_adj (SQF adjustments via Fivetran)
  + DWH_dbo.Dim_Instrument_Snapshot (IsFuture=1: margins, multiplier)
  + DWH_dbo.Fact_Settlement_Prices (daily settlement prices)
  + Dealing_dbo.External_Gold_Dealing_Marex_Trader_OrderID (tag50 trader IDs)
  + DWH_dbo.Dim_Position (HedgeServerID, RegulationIDOnOpen, ClosePositionReasonID)
  + DWH_dbo.Dim_Instrument (InstrumentName)
  + DWH_dbo.Dim_ClosePositionReason + Dim_Regulation (lookups)
    |-- SP_Finance_Real_Futures_Custody_And_Transfers @date ---|
    |-- Loop: @date-2 to @date (holiday coverage) ---|
    |-- DELETE+INSERT per ReportDateID ---|
    v
  BI_DB_dbo.BI_DB_Finance_Real_Futures_Custody_And_Transfers (1.22M rows, ~4-6K/day)
```

*Generated: 2026-04-26*
