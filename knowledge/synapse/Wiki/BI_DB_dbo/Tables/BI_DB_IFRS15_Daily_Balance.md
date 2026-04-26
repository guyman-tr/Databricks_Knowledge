# BI_DB_dbo.BI_DB_IFRS15_Daily_Balance

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED INDEX (Date ASC) |
| **Writer SP** | BI_DB_dbo.SP_IFRS_15_Balance |
| **ETL Pattern** | DELETE WHERE Date + ExcelOrder scope + INSERT (within WHILE loop for 2 days) |
| **OpsDB Priority** | 20 |
| **Frequency** | Daily |
| **Row Estimate** | ~600–800 rows/day (20+ metric rows × N instruments × dimension combinations) |
| **UC Target** | Not Migrated |

## Overview

Daily aggregated IFRS 15 revenue recognition metrics for eToro's crypto (real/settled) and CFD (synthetic) position book. Each row represents one combination of **metric × position type × instrument × customer segment dimensions** for a given date. The table is structured to mirror the Finance team's IFRS 15 reconciliation spreadsheet, with `ExcelOrder` providing the exact row ordering used in Tableau/Excel reporting.

**IFRS 15 context**: International Financial Reporting Standard 15 governs revenue recognition for contracts with customers. For eToro, the key question is: when does spread/commission revenue get recognized — at position open, position close, or proportionally over the position's life? The opening/closing balance metrics and flow metrics in this table form a complete reconciliation of the crypto position book from T-1 to T.

**Instrument scope**: Crypto only — InstrumentTypeID=10 (cryptocurrency) plus InstrumentID=624 (a crypto index added in 2025). FX, stocks, and commodities are excluded.

**Sister table**: `BI_DB_IFRS_15_Daily_Positions` (same writer SP, position-level granularity) is written first and then read back to generate the aggregated rows in this table.

## ETL Summary

```
WHILE @loopstartdate <= @date   (runs for @date-1 and @date):
  1. Build temp tables:
     #C2P_Positions   — Copy-to-Portfolio positions (CompensationReasonID=134)
     #realTanganystatus — Tangany/DLT status snapshot per CID at @startDateInt
     #outliers        — Outlier CIDs from BI_DB_Outliers_New
     #openingBalancPnl — BI_DB_PositionPnL at @date-1 + prices + regulation
     #ClosingBalancePnl — BI_DB_PositionPnL at @date + prices + regulation
     #intoDLT / #outFromDLT — DLT status changers (EXCEPT set logic)
     #Prices / #Prices2 — Latest prices per instrument
     #ticketfeepercentage — Ticket-fee-% commissions (Function_Revenue_TicketFeeByPercent)
     #relposFCA        — Open/close actions per position (Fact_CustomerAction)
     #relpos           — Positions with open or close on @date (Dim_Position JOIN)
     #changelogPrep    — CFD/Real conversion events (Dim_PositionChangeLog, ChangeTypeID 12/13)
     #dailyFlow        — Final CFD↔Real conversion flow
     #finalZeroAgg     — Zero-balance metrics (Client_Balance_Breakdown_Instrument_Level)
     #openingBalance   — Aggregated opening balance per instrument × segment
     #closingBalance   — Aggregated closing balance per instrument × segment
  2. DELETE FROM BI_DB_IFRS_15_Daily_Positions WHERE DateID = @startDateInt
     INSERT INTO BI_DB_IFRS_15_Daily_Positions (position-level detail)
  3. DELETE FROM BI_DB_IFRS15_Daily_Balance WHERE Date = @startDate AND ExcelOrder NOT IN (32,33)
     INSERT 29 UNION ALL branches (ExcelOrder 1–29)

After WHILE loop:
  4. DELETE WHERE Date = @DLTEndDate AND ExcelOrder IN (32,33)
     INSERT ExcelOrder 32 (IntoDLTStatusOpeningBalance) + 33 (OutOfDLTStatusClosingBalance)
     (DLT balance rows for customers entering/leaving DLT status)
```

**Two-day loop rationale**: Some crypto redeems only materialize in `Fact_BillingRedeem` the day after the actual event. Running the loop for both @date-1 and @date ensures the previous day is retroactively corrected.

## Column Reference

| # | Column | Type | Nullable | Description | Tier |
|---|--------|------|----------|-------------|------|
| 1 | ExcelOrder | int | YES | Display ordering key mapping rows to specific positions in the IFRS 15 reconciliation spreadsheet. Values 1–29 (loop body) + 32, 33 (DLT section, outside loop). ExcelOrder 15 is intentionally absent (metric removed; gap preserved for Tableau compatibility). | Tier 2 |
| 2 | Metric | varchar(100) | YES | Named IFRS 15 metric category. See Metric Taxonomy table below for all values and their IFRS meaning. Determines which financial flow or balance component this row represents. | Tier 2 |
| 3 | PositionType | varchar(100) | YES | Metric subcategory describing the position's settlement status at open and/or close. For balance rows: 'NA'. For flow rows: e.g., 'OpenReal', 'OpenRealLatestCFD', 'ClosedReal', 'ConvertedCFDToReal'. | Tier 2 |
| 4 | Date | date | YES | Report date — the date this metric row represents. Within the WHILE loop, this is @startDate (which ranges from @date-1 to @date). For DLT rows (ExcelOrder 32,33): @DLTEndDate = @date. | Tier 2 |
| 5 | YearMonth | varchar(6) | YES | YYYYMM format period identifier derived from Date. Used for monthly aggregation in Tableau/Excel reporting. | Tier 2 |
| 6 | Name | varchar(100) | YES | Crypto instrument name — specifically the BuyCurrency name from Dim_Instrument (e.g., 'BTC', 'ETH', 'XRP', 'SOL'). Identifies which crypto asset this row refers to. | Tier 2 |
| 7 | PositionTiming | varchar(100) | YES | Position lifecycle timing relative to the report period. For flow metrics: 'Opened_In_Period_Not_Closed' (opened today, still open), 'Opened_And_Closed_In_Period' (day trade), 'Opened_Before_Period_Closed_InPeriod' (previous open, closed today). 'NA' for balance and conversion metrics. | Tier 2 |
| 8 | TotalUnits | float | YES | Total position size in crypto units (number of tokens). For long positions: positive; for short positions: negative (multiplied by -1 in CASE). For commission and fee metrics: 0. Sourced from AmountInUnitsDecimal (closing balance) or InitialUnits (opening/flow). | Tier 2 |
| 9 | USDValue | float | YES | Total USD value for this metric row. Semantic depends on Metric: (a) Balance rows: SUM(TotalNOP) = net open position at market price; (b) Flow rows: SUM(ComputedVolumeOpen) or SUM(ComputedVolumeClose) = notional traded volume; (c) Commission rows: SUM(-FullCommission) = negative of commission charged; (d) Zero metrics: SUM(TotalZero) = uncommitted balance; (e) DLT rows: SUM(Amount + PositionPnL) = custodied crypto value. | Tier 2 |
| 10 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by the ETL pipeline (GETDATE() at INSERT time). | ETL_METADATA |
| 11 | IsValidCustomer | int | YES | Customer validity flag at report date. From Fact_SnapshotCustomer: 1 = valid customer; 0 = invalid. Used to separate valid vs. invalid customer book in IFRS reconciliation. | Tier 2 |
| 12 | IsCreditReportValidCB | int | YES | Credit bureau validity flag at report date. From Fact_SnapshotCustomer: 1 = customer has valid credit bureau check; 0 = invalid. Separates credit-valid from credit-invalid sub-books in IFRS reports. | Tier 2 |
| 13 | IsOutlier | int | YES | Statistical outlier flag. From BI_DB_Outliers_New: 1 = customer is a position-size outlier (large unusual position that could distort aggregate metrics); 0 = normal customer. NULL for DLT balance rows (ExcelOrder 32, 33). | Tier 2 |
| 14 | OutlierTransition | varchar(100) | YES | Outlier transition description from BI_DB_Outliers_New.Transition. 'NoTransition' = customer is not an outlier or has no transition. Specific transition names describe what kind of outlier event occurred. NULL for DLT balance rows. | Tier 2 |
| 15 | TanganyStatus | varchar(20) | YES | Crypto custody status from BI_DB_Client_Balance_CID_Level_New. Tangany is eToro's crypto custody provider. MAX(TanganyStatus) per CID at the report date. Distinguishes how the customer's real crypto is held (e.g., 'Internal' = eToro internal custody, 'Customer' = Tangany customer custody). | Tier 2 |
| 16 | IsDLTUser | int | YES | Distributed Ledger Technology user flag from BI_DB_Client_Balance_CID_Level_New. MAX(IsDLTUser) per CID at report date. 1 = customer holds real crypto in DLT/blockchain custody (Fact_SnapshotCustomer.DltStatusID=4); 0 = standard crypto position. DLT users appear or disappear from balance aggregations when their DLT status changes — the ExcelOrder 32/33 rows compensate for these gaps. | Tier 2 |
| 17 | TicketFeeVolume | decimal(16,8) | YES | Volume-weighted ticket fee percentage commission. Computed by Function_Revenue_TicketFeeByPercent(@startDateInt, @endDateInt, 0). SUM of TicketFeeByPercent per position grouped into each IFRS metric row. 0.0 for balance rows, zero metrics, and commission rows. Non-zero for BuyReal, SellReal, BuyCFD, SellCFD, Redeem, and Staking flow rows. | Tier 2 |
| 18 | IsC2P | int | YES | Copy-to-Portfolio flag: 1 = position was opened as a copy/mirror trade (identified via CompensationReasonID=134 in External_Bronze_etoro_Trade_AdminPositionLog); 0 = direct trade. "C2P" = Copy to Portfolio. | Tier 2 |
| 19 | IsTransferOut | int | YES | Transfer-out flag: 1 = position was closed due to an account transfer out (ClosePositionReasonID=22 in Dim_Position); 0 = normal position close. NULL for DLT balance rows (ExcelOrder 32,33) and for Zero metrics where NULL is passed explicitly. | Tier 2 |
| 20 | Regulation | varchar(50) | YES | Customer regulation name at the time of the action. Joined from Dim_Regulation via Fact_SnapshotCustomer.RegulationID at the SCD-valid date range. Represents the regulatory jurisdiction of the customer's positions (e.g., 'ASIC', 'CySEC', 'FCA'). | Tier 2 |

## Metric Taxonomy

| ExcelOrder | Metric | PositionType Values | Financial Meaning |
|-----------|--------|---------------------|------------------|
| 1 | OpeningBalanceReal | NA | Real (settled) crypto book balance at T-1 close |
| 1 | OpeningBalanceCFD | NA | CFD (synthetic) crypto book balance at T-1 close |
| 2 | BuyReal | OpenReal, OpenReal (redeem) | New real crypto positions opened on T |
| 3 | BuyReal | OpenRealLatestCFD | Real crypto opened on T that converted to CFD by day end |
| 4 | SellReal | ClosedReal | Real crypto positions closed on T (started real) |
| 5 | SellReal | ClosedRealOpenedCFD | Real crypto positions closed on T (started as CFD) |
| 6 | BuyCFD | OpenCFD | New CFD crypto positions opened on T |
| 7 | BuyCFD | OpenCFDLatestReal | CFD crypto opened on T that converted to real by day end |
| 8 | BuyCFD | OpenCFD_SellShort | Short-sell CFD positions opened on T |
| 9 | SellCFD | OpenCFDLatestCFD | CFD crypto positions closed on T (started + closed CFD) |
| 10 | SellCFD | OpenRealLatestCFD | CFD positions closed on T (started real, closed CFD) |
| 11 | SellCFD | OpenCFD_BuyShort | Short CFD positions closed on T |
| 12 | RedeemSell | CloseReal | Real crypto positions redeemed (crypto withdrawal) on T |
| 13 | StakingBuy | OpenReal | Staking/airdrop positions opened on T (non-redeem) |
| 14 | StakingSell | CloseReal | Staking positions closed on T |
| 15 | *(absent)* | — | Intentional gap in numbering (metric removed) |
| 16 | StakingBuy | OpenReal | Staking positions opened via redeem mechanism on T |
| 17 | RedeemStakingSell | CloseReal | Staking-redeem positions closed on T |
| 18 | SellReal | ConvertedRealToCFD | Volume of Real→CFD conversion events on T |
| 19 | BuyReal | ConvertedCFDToReal | Volume of CFD→Real conversion events on T |
| 20 | SellCFD | ConvertedCFDToReal | CFD sold leg of CFD→Real conversions on T |
| 21 | BuyCFD | ConvertedRealToCFD | CFD bought leg of Real→CFD conversions on T |
| 22 | ValidZeroReal | NA | Uncommitted real balance for valid customers |
| 23 | ValidZeroCFD | NA | Uncommitted CFD balance for valid customers |
| 24 | InValidZeroReal | NA | Uncommitted real balance for invalid customers |
| 25 | InValidZeroCFD | NA | Uncommitted CFD balance for invalid customers |
| 26 | FullCommissionReal | NA | Total full commission on real positions (negated) |
| 27 | FullCommissionCFD | NA | Total full commission on CFD positions (negated) |
| 28 | ClosingBalanceReal | NA | Real crypto book balance at T close |
| 29 | ClosingBalanceCFD | NA | CFD crypto book balance at T close |
| 32 | IntoDLTStatusOpeningBalance | NA | Opening balance of customers who entered DLT status on T |
| 33 | OutOfDLTStatusClosingBalance | NA | Closing balance of customers who exited DLT status on T |

## Dimension Cuts

Each metric row in this table is split across combinations of these dimension values (GROUP BY keys):

| Dimension | Column | Source |
|-----------|--------|--------|
| Instrument | Name | Dim_Instrument.BuyCurrency |
| Position lifecycle | PositionTiming | SP CASE logic |
| Customer validity | IsValidCustomer | Fact_SnapshotCustomer |
| Credit validity | IsCreditReportValidCB | Fact_SnapshotCustomer |
| Outlier status | IsOutlier / OutlierTransition | BI_DB_Outliers_New |
| Custody status | TanganyStatus | BI_DB_Client_Balance_CID_Level_New |
| DLT user | IsDLTUser | BI_DB_Client_Balance_CID_Level_New |
| Copy-trade | IsC2P | External_Bronze_etoro_Trade_AdminPositionLog |
| Transfer | IsTransferOut | Dim_Position.ClosePositionReasonID |
| Regulation | Regulation | Dim_Regulation via Fact_SnapshotCustomer |

## Upstream Dependencies

| Upstream Object | Type | Role |
|----------------|------|------|
| BI_DB_dbo.BI_DB_PositionPnL | Table | Primary — daily crypto NOP snapshot |
| BI_DB_dbo.BI_DB_IFRS_15_Daily_Positions | Table | Sister table; position-level rows written first, then read back for aggregation |
| BI_DB_dbo.BI_DB_Outliers_New | Table | Outlier CID flags |
| BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level | Table | Zero/uncommitted balance metrics |
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Table | TanganyStatus + IsDLTUser per CID |
| BI_DB_dbo.Function_Revenue_TicketFeeByPercent | Function | Ticket-fee-percentage commissions |
| BI_DB_dbo.External_Bronze_etoro_Trade_AdminPositionLog | External Table | C2P position identification |
| DWH_dbo.Dim_Position | Table | Position metadata, forex rates, partial-close |
| DWH_dbo.Dim_PositionChangeLog | Table | CFD↔Real conversions |
| DWH_dbo.Fact_CustomerAction | Table | IsSettled, IsRedeem per action |
| DWH_dbo.Fact_SnapshotCustomer + Dim_Range | Tables | Customer validity + regulation at SCD date |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Table | Instrument prices for NOP/volume |
| DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted | Table | 60-min candle prices for changelog flows |
| DWH_dbo.Fact_BillingRedeem | Table | Late-redeem status corrections |
| DWH_dbo.Dim_Instrument | Table | Crypto scope filter + instrument name |
| DWH_dbo.Dim_Regulation | Table | Regulation name lookup |

## Data Quality Notes

- **Two-day loop (retroactive fix)**: The SP always re-runs the previous day (@date-1) in the same execution to catch late-materializing redeems from Fact_BillingRedeem. The last date run may be slightly off until the next day's execution corrects it.
- **DLT rows are written outside the loop**: ExcelOrder 32 and 33 are excluded from the main DELETE scope (`ExcelOrder NOT IN (32,33)`) and handled separately. This means a re-run for a historical date will NOT update the DLT rows for that date unless the DLT DELETE block is also triggered.
- **ExcelOrder 15 intentionally absent**: The numbering skips from 14 to 16. This is a legacy gap from a metric that was removed. Tableau reports must not assume sequential ExcelOrder values.
- **float precision**: TotalUnits and USDValue use FLOAT, which can introduce floating-point rounding errors in large aggregations. For exact financial reconciliation, sum discrepancies of ≤ 0.001 may be artifacts.
- **NOLOCK hints throughout**: The SP uses `WITH (NOLOCK)` extensively. Under high concurrency, dirty reads are possible in some temp tables. The 2-day loop partially mitigates this by correcting the prior day.

## UC Target

Not Migrated. No `.alter.sql` generated (wiki-only batch).
