# Lineage: BI_DB_dbo.BI_DB_IFRS_15_Daily_Positions

**Writer SP**: `SP_IFRS_15_Balance`
**Scope**: Crypto positions only (InstrumentTypeID=10 OR InstrumentID=624)
**Pattern**: DELETE WHERE DateID=@startDateInt + INSERT; WHILE loop @date-1 to @date (2-day retroactive window)
**UC Target**: Not Migrated

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|--------------|-----------|------|
| 1 | DateID | ETL | @startDateInt | CAST(CONVERT(VARCHAR(8), @startDate, 112) AS INT) | Tier 2 |
| 2 | PositionID | DWH_dbo.Dim_Position | PositionID | Passthrough (via BI_DB_PositionPnL/#relpos) | Tier 1 |
| 3 | CID | DWH_dbo.Dim_Position | CID | Passthrough (via BI_DB_PositionPnL/#relpos) | Tier 1 |
| 4 | InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Passthrough (via Dim_Position JOIN Dim_Instrument) | Tier 1 |
| 5 | Name | DWH_dbo.Dim_Instrument | BuyCurrency | Passthrough — instrument base currency code (e.g. 'BTC','XRP') | Tier 1 |
| 6 | CFD_Real_On_Open | DWH_dbo.Fact_SnapshotCustomer | IsSettled (StartDay) | CASE WHEN StartDayIsSettled=1 THEN 'RealOnOpen' ELSE 'CFDOnOpen' | Tier 2 |
| 7 | CFD_Real_Latest | DWH_dbo.Fact_SnapshotCustomer | IsSettled (EndDay) | CASE WHEN EndDayIsSettled=1 THEN 'Real' ELSE 'CFD' | Tier 2 |
| 8 | Long_Short | DWH_dbo.Dim_Position | IsBuy | CASE WHEN IsBuy=1 THEN 'Long' ELSE 'Short' | Tier 2 |
| 9 | IsRedeem | DWH_dbo.Fact_CustomerAction | IsRedeem | CASE WHEN IsRedeem=1 THEN 'Redeem' ELSE 'Not_Redeem' | Tier 2 |
| 10 | Staking | DWH_dbo.Dim_Position | IsAirDrop | CASE WHEN IsAirDrop=1 THEN 'Staking' ELSE 'Not_Staking' | Tier 2 |
| 11 | PositionTiming | DWH_dbo.Dim_Position | OpenDateID, CloseDateID | CASE: 'Opened_In_Period_Not_Closed'/'Opened_And_Closed_In_Period'/'Opened_Before_Period_Closed_InPeriod'/'bla' | Tier 2 |
| 12 | InitialUnits | DWH_dbo.Dim_Position | InitialUnits | Passthrough (via BI_DB_PositionPnL/#relpos) | Tier 1 |
| 13 | AmountInUnitsDecimal | DWH_dbo.Dim_Position | AmountInUnitsDecimal | Passthrough (via BI_DB_PositionPnL/#relpos) | Tier 1 |
| 14 | IsPartialCloseParent | DWH_dbo.Dim_Position | IsPartialCloseParent | ISNULL(IsPartialCloseParent, 0) | Tier 1 |
| 15 | IsPartialCloseChild | DWH_dbo.Dim_Position | IsPartialCloseChild | ISNULL(IsPartialCloseChild, 0) | Tier 1 |
| 16 | IsPartialCloseChildFromReOpen | DWH_dbo.Dim_Position | IsPartialCloseChildFromReOpen | ISNULL(IsPartialCloseChildFromReOpen, 0) | Tier 1 |
| 17 | Leverage | DWH_dbo.Dim_Position | Leverage | Passthrough (via BI_DB_PositionPnL/#relpos) | Tier 1 |
| 18 | ComputedVolumeOpen | DWH_dbo.Dim_Position | InitialUnits, InitForexRate, InitForex_USDConversionRate | CASE PositionTiming: if opened today then InitialUnits*InitForexRate*COALESCE(InitForex_USD/InitConv/LastOpConv), else 0 | Tier 2 |
| 19 | ComputedVolumeClose | DWH_dbo.Dim_Position | AmountInUnitsDecimal, EndForexRate, LastOpConversionRate | AmountInUnitsDecimal * EndForexRate * ISNULL(LastOpConversionRate,1), 0 if not closed today | Tier 2 |
| 20 | FullCommission | DWH_dbo.Dim_Position | FullCommissionByUnits, FullCommissionOnClose | CASE PositionTiming: Opened_In→FullCommissionByUnits; Opened_And_Closed→FullCommissionOnClose; Opened_Before_Closed→FullCommissionOnClose - FullCommissionByUnits | Tier 2 |
| 21 | IsValidCustomer | DWH_dbo.Dim_Customer | IsValidCustomer | Passthrough via Fact_SnapshotCustomer+Dim_Range at @ClosingBalanceDateInt | Tier 1 |
| 22 | IsCreditReportValidCB | DWH_dbo.Dim_Customer | IsCreditReportValidCB | Passthrough via Fact_SnapshotCustomer+Dim_Range at @ClosingBalanceDateInt | Tier 1 |
| 23 | UpdateDate | ETL | GETDATE() | Passthrough — ETL timestamp | Tier 3 |
| 24 | Regulation | DWH_dbo.Dim_Regulation | Name | JOIN via Fact_SnapshotCustomer.RegulationID at @ClosingBalanceDateInt | Tier 2 |
| 25 | Changed_CFD_Real | — | — | Always NULL (from #relpos branch; changelog inserts handled separately) | Tier 4 |
| 26 | Change_Type | — | — | Always NULL (from #relpos branch; changelog inserts handled separately) | Tier 4 |
| 27 | IsOutlier | BI_DB_dbo.BI_DB_Outliers_New | RealCID | CASE WHEN o.CID IS NOT NULL THEN 1 ELSE 0 — outlier flag excluding DLT transitions | Tier 2 |
| 28 | OutlierTransition | BI_DB_dbo.BI_DB_Outliers_New | Transition | CASE WHEN Transition IS NULL THEN 'NoTransition' ELSE Transition | Tier 2 |
| 29 | TanganyStatus | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | TanganyStatus | MAX(TanganyStatus) per CID at @startDateInt | Tier 2 |
| 30 | IsDLTUser | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | IsDLTUser | MAX(IsDLTUser) per CID at @startDateInt | Tier 2 |
| 31 | TicketFeePercentOpen | Function_Revenue_TicketFeeByPercent | TicketFeeByPercent | WHERE TicketFeeByPercentAction='Open' for @endDateInt,@endDateInt,0 | Tier 2 |
| 32 | TicketFeePercentClose | Function_Revenue_TicketFeeByPercent | TicketFeeByPercent | WHERE TicketFeeByPercentAction='Close' for @endDateInt,@endDateInt,0 | Tier 2 |
| 33 | IsC2P | External_Bronze_etoro_Trade_AdminPositionLog | PositionID | CASE WHEN PositionID IN (SELECT PositionID WHERE CompensationReasonID=134) THEN 1 ELSE 0 | Tier 2 |
| 34 | IsTransferOut | DWH_dbo.Dim_Position | ClosePositionReasonID | CASE WHEN ClosePositionReasonID=22 THEN 1 ELSE 0 | Tier 2 |

## Source Objects

| Source | Role |
|--------|------|
| BI_DB_dbo.BI_DB_PositionPnL | Primary position data source (all position dimensions and metrics) |
| DWH_dbo.Dim_Position | Position dimensions (PositionID, CID, InitialUnits, Leverage, IsBuy, IsAirDrop, etc.) |
| DWH_dbo.Dim_Instrument | Instrument dimension (InstrumentID, BuyCurrency, InstrumentTypeID filter) |
| DWH_dbo.Fact_CustomerAction | Redeem detection (ActionTypeID IN 1-6,28,39,40; IsRedeem flag) |
| DWH_dbo.Fact_SnapshotCustomer + Dim_Range | Customer validity snapshot (IsValidCustomer, IsCreditReportValidCB, RegulationID) |
| DWH_dbo.Dim_Customer | Customer validity passthrough |
| DWH_dbo.Dim_Regulation | Regulation name lookup |
| DWH_dbo.Dim_PositionChangeLog | CFD↔Real change tracking (ChangeTypeID 12/13) — populates Changed_CFD_Real/Change_Type |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Price lookups for changlog section |
| DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted | Price candles for changelog section |
| BI_DB_dbo.BI_DB_Outliers_New | Outlier flags (IsOutlier, OutlierTransition) |
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | TanganyStatus + IsDLTUser per CID |
| BI_DB_dbo.Function_Revenue_TicketFeeByPercent | Ticket fee percentages (Open/Close) |
| BI_DB_dbo.External_Bronze_etoro_Trade_AdminPositionLog | C2P positions (CompensationReasonID=134) |

## ETL Pipeline

```
etoro.Trade.PositionTbl (production)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_dbo.Dim_Position (staging → Dim)
  |
  +-- SP_PositionPnL_DL_To_Synapse ---|
  v
BI_DB_dbo.BI_DB_PositionPnL (daily PnL fact)
  |
  +-- SP_IFRS_15_Balance @date --------|
  |   WHILE @date-1 to @date           |
  |   DELETE WHERE DateID=@startDateInt |
  |   INSERT INTO                       |
  v
BI_DB_dbo.BI_DB_IFRS_15_Daily_Positions (317M rows, crypto-only position detail)
  |
  v [read back by same SP]
BI_DB_dbo.BI_DB_IFRS15_Daily_Balance (20-col aggregated IFRS metrics)
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 11 | PositionID, CID, InstrumentID, Name, InitialUnits, AmountInUnitsDecimal, IsPartialCloseParent, IsPartialCloseChild, IsPartialCloseChildFromReOpen, Leverage, IsValidCustomer, IsCreditReportValidCB |
| Tier 2 | 19 | DateID, CFD_Real_On_Open, CFD_Real_Latest, Long_Short, IsRedeem, Staking, PositionTiming, ComputedVolumeOpen, ComputedVolumeClose, FullCommission, Regulation, IsOutlier, OutlierTransition, TanganyStatus, IsDLTUser, TicketFeePercentOpen, TicketFeePercentClose, IsC2P, IsTransferOut |
| Tier 3 | 1 | UpdateDate |
| Tier 4 | 2 | Changed_CFD_Real, Change_Type |
