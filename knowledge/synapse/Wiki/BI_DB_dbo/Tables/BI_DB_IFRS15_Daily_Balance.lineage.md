# Lineage: BI_DB_dbo.BI_DB_IFRS15_Daily_Balance

**Generated**: 2026-04-22 | **Writer SP**: `BI_DB_dbo.SP_IFRS_15_Balance` | **Schema**: BI_DB_dbo

## ETL Chain

```
BI_DB_dbo.BI_DB_PositionPnL (daily crypto position P&L snapshot — primary source)
  + DWH_dbo.Fact_CurrencyPriceWithSplit (NOP computation)
  + DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted (candle prices)
DWH_dbo.Dim_Position (position metadata, IsBuy, forex rates, partial-close flags)
DWH_dbo.Dim_PositionChangeLog (ChangeTypeID 12/13 = CFD/Real conversions)
DWH_dbo.Fact_CustomerAction (IsSettled, IsRedeem on open/close)
DWH_dbo.Fact_SnapshotCustomer + DWH_dbo.Dim_Range (customer validity, RegulationID at SCD date)
DWH_dbo.Dim_Customer (customer attributes)
DWH_dbo.Dim_Instrument (InstrumentTypeID=10 Crypto scope, or InstrumentID=624)
DWH_dbo.Dim_Regulation (regulation name)
BI_DB_dbo.BI_DB_Outliers_New (outlier flags)
BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level (Zero metrics — uncommitted balance)
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New (TanganyStatus / IsDLTUser snapshot)
BI_DB_dbo.Function_Revenue_TicketFeeByPercent (ticket-fee-percentage commission function)
BI_DB_dbo.External_Bronze_etoro_Trade_AdminPositionLog (C2P positions, CompensationReasonID=134)
DWH_dbo.Fact_BillingRedeem (redeem status correction for late-materializing redeems)
  |-- SP_IFRS_15_Balance @date (WHILE loop: @date-1 to @date) ---|
  |   → DELETE WHERE Date = @loopdate AND ExcelOrder NOT IN (32,33)
  |   → INSERT aggregated IFRS metrics (ExcelOrder 1–29)
  |   Also writes: BI_DB_IFRS_15_Daily_Positions (position-level detail, same SP)
  |-- DLT section (outside loop) ---|
  |   → DELETE WHERE Date = @date-1 AND ExcelOrder IN (32,33)
  |   → INSERT ExcelOrder 32 (IntoDLTStatusOpeningBalance) + 33 (OutOfDLTStatusClosingBalance)
  v
BI_DB_dbo.BI_DB_IFRS15_Daily_Balance
  (UC Target: Not Migrated)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | ExcelOrder | Literal | — | Integer display-order key (1–29, 32, 33) mapping to specific IFRS metric rows | Tier 2 |
| 2 | Metric | Literal | — | Named IFRS metric category (e.g., 'OpeningBalanceReal', 'BuyReal', 'SellCFD', 'RedeemSell') | Tier 2 |
| 3 | PositionType | Literal | — | Metric subcategory (e.g., 'OpenReal', 'ClosedReal', 'ConvertedCFDToReal', 'NA') | Tier 2 |
| 4 | Date | Loop variable | @startDate | Report date = @startDate within WHILE loop | Tier 2 |
| 5 | YearMonth | Loop variable | @yearMonth | CONVERT(VARCHAR(6), @startDate, 112) = YYYYMM | Tier 2 |
| 6 | Name | DWH_dbo.Dim_Instrument | BuyCurrency | Crypto instrument name (e.g., 'BTC', 'ETH', 'XRP') | Tier 2 |
| 7 | PositionTiming | DWH_dbo.Dim_Position | OpenDateID, CloseDateID | CASE derivation: Opened_In_Period_Not_Closed / Opened_And_Closed_In_Period / Opened_Before_Period_Closed_InPeriod / 'NA' | Tier 2 |
| 8 | TotalUnits | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal / InitialUnits | SUM of units (negative for shorts, 0 for commission rows) | Tier 2 |
| 9 | USDValue | BI_DB_dbo.BI_DB_PositionPnL + Prices | NOP / ComputedVolumeOpen / ComputedVolumeClose | Metric-dependent: SUM(TotalNOP) for balances, SUM(ComputedVolume) for flows, SUM(TotalZero) for zero metrics, SUM(-FullCommission) for commission metrics | Tier 2 |
| 10 | UpdateDate | ETL | — | GETDATE() at INSERT time | ETL_METADATA |
| 11 | IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer | Passthrough; customer validity flag at report date | Tier 2 |
| 12 | IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough; credit bureau validity at report date | Tier 2 |
| 13 | IsOutlier | BI_DB_dbo.BI_DB_Outliers_New | RealCID | CASE WHEN RealCID IS NOT NULL THEN 1 ELSE 0; NULL for DLT rows (ExcelOrder 32,33) | Tier 2 |
| 14 | OutlierTransition | BI_DB_dbo.BI_DB_Outliers_New | Transition | Passthrough; 'NoTransition' when not outlier; NULL for DLT rows | Tier 2 |
| 15 | TanganyStatus | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | TanganyStatus | MAX(TanganyStatus) per CID at @startDateInt | Tier 2 |
| 16 | IsDLTUser | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | IsDLTUser | MAX(IsDLTUser) per CID at @startDateInt; 1=DLT-custodied crypto customer | Tier 2 |
| 17 | TicketFeeVolume | BI_DB_dbo.Function_Revenue_TicketFeeByPercent | TicketFeeByPercent | SUM of ticket-fee-percentage commissions per position; 0 for balance/zero/commission metrics | Tier 2 |
| 18 | IsC2P | BI_DB_dbo.External_Bronze_etoro_Trade_AdminPositionLog | PositionID | CASE WHEN PositionID IN (CompensationReasonID=134 positions) THEN 1 ELSE 0; Copy-to-Portfolio flag | Tier 2 |
| 19 | IsTransferOut | DWH_dbo.Dim_Position | ClosePositionReasonID | CASE WHEN ClosePositionReasonID=22 THEN 1 ELSE 0; NULL for DLT and Zero metric rows | Tier 2 |
| 20 | Regulation | DWH_dbo.Dim_Regulation | Name | Customer regulation name at report date via Fact_SnapshotCustomer + Dim_Range | Tier 2 |

## Source Objects

| Object | Type | Role |
|--------|------|------|
| BI_DB_dbo.BI_DB_PositionPnL | Table | Primary source — daily crypto position P&L snapshot (NOP, units, IsSettled) |
| BI_DB_dbo.BI_DB_IFRS_15_Daily_Positions | Table | Position-level detail written by same SP; read back for flow metrics (ExcelOrder 2–17, 26, 27) |
| BI_DB_dbo.BI_DB_Outliers_New | Table | Outlier CID list with transition type |
| BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level | Table | Uncommitted balance ("zero") metrics by instrument |
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Table | TanganyStatus and IsDLTUser per customer per date |
| BI_DB_dbo.Function_Revenue_TicketFeeByPercent | Function | Ticket-fee-percentage commission calculation |
| BI_DB_dbo.External_Bronze_etoro_Trade_AdminPositionLog | External Table | Copy-to-Portfolio position identification (CompensationReasonID=134) |
| DWH_dbo.Dim_Position | Table | Position metadata (IsBuy, OpenDateID, CloseDateID, forex rates, partial-close flags) |
| DWH_dbo.Dim_PositionChangeLog | Table | CFD↔Real settlement conversion events (ChangeTypeID 12/13) |
| DWH_dbo.Fact_CustomerAction | Table | Open/close action events (IsSettled, IsRedeem) |
| DWH_dbo.Fact_SnapshotCustomer + DWH_dbo.Dim_Range | Tables | Customer validity, regulation at SCD date |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Table | Instrument prices for NOP/volume computation |
| DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted | Table | 60-min candle prices (AskLast/BidLast) for changelog pricing |
| DWH_dbo.Fact_BillingRedeem | Table | Late-redeem status corrections (latest RedeemStatusID=8 check) |
| DWH_dbo.Dim_Instrument | Table | Instrument type filter (InstrumentTypeID=10 Crypto) + name/currency |
| DWH_dbo.Dim_Customer | Table | Customer attributes |
| DWH_dbo.Dim_Regulation | Table | Regulation name lookup |

## Key Constraints (from SP)

- **Instrument scope**: InstrumentTypeID=10 (Crypto) OR InstrumentID=624 (crypto index, added 2025-05-15)
- **WHILE loop**: Runs for @date-1 and @date (2-day window to catch late-materializing redeems)
- **DLT rows (32,33)**: Written outside the WHILE loop; deleted and re-inserted separately
- **Zero metrics (22–25)**: Sourced from Client_Balance_Breakdown_Instrument_Level, not BI_DB_IFRS_15_Daily_Positions
- **ExcelOrder 15**: Not present in SP (numbering gap — metric removed but gap left for Tableau compatibility)
- **Two-table writer**: Same SP writes BI_DB_IFRS_15_Daily_Positions (position detail) then reads it for balance metric aggregation

## UC Target

Not Migrated
