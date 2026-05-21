# DWH_dbo.V_Fact_SnapshotEquity

## 1. Overview

| Property | Value |
|----------|-------|
| **Full Name** | `[DWH_dbo].[V_Fact_SnapshotEquity]` |
| **Type** | View |
| **Base Tables** | `Fact_SnapshotEquity`, `Dim_Range`, `Dim_Date` |
| **Purpose** | Expands Fact_SnapshotEquity SCD2 date ranges into individual daily rows via `Dim_Range` + `Dim_Date` bridge. Adds `DateKey` for easy daily-grain queries. |

## 2. Business Context

This view converts the range-level SCD2 grain of `Fact_SnapshotEquity` into a daily grain by joining through `Dim_Range` and `Dim_Date` (same pattern as `V_Fact_SnapshotCustomer`). Each date range row is exploded into one row per day within the range, with `DateKey` identifying the specific day.

Uses `NOLOCK` on fact and range tables. Structurally identical to `V_Fact_SnapshotCustomer` but for equity data.

## 3. View Definition

```sql
SELECT DateKey, a.*
FROM DWH_dbo.Fact_SnapshotEquity a WITH(NOLOCK)
JOIN DWH_dbo.Dim_Range b WITH(NOLOCK) ON a.DateRangeID = b.DateRangeID
JOIN DWH_dbo.Dim_Date d ON d.DateKey BETWEEN FromDateID AND ToDateID
```

## 4. Elements

| # | Column | Type | Source | Description |
|---|--------|------|--------|-------------|
| 1 | DateKey | int | Dim_Date.DateKey | Specific date within the snapshot range (YYYYMMDD integer). One row per day per customer. (Tier 2 — view DDL) |
| 2 | CID | int | Fact_SnapshotEquity.CID | Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK. (Tier 2 — via Fact_SnapshotEquity) |
| 3 | DateRangeID | bigint | Fact_SnapshotEquity.DateRangeID | Encoded date range as 12-digit bigint (YYYYMMDDYYYY). FromDate in first 8 digits, ToDate suffix in last 4 digits. New rows get @date+1231; updated rows get end-date set to @daybefore. Decoded via Dim_Range. Part of PK. (Tier 2 — via Fact_SnapshotEquity) |
| 4 | TotalPositionsAmount | money | Fact_SnapshotEquity.TotalPositionsAmount | Sum of all open position amounts (NewAmount) for this CID on this date. Includes all asset classes: CFD, stocks, crypto, futures, margin. Source: open positions (Trade.OpenPositionEndOfDay) + same-day closed positions (History.ClosePositionEndOfDay) minus History.Credit CreditTypeID=13 adjustments. (Tier 2 — via Fact_SnapshotEquity) |
| 5 | TotalCash | money | Fact_SnapshotEquity.TotalCash | Customer's total cash balance for the day. Computed as: previous day's TotalCash (from last row in current year) + sum of TotalCashChange from History.ActiveCredit for @dt. This running-balance approach was introduced 2020-06-07 replacing the direct History.Credit.TotalCash read. (Tier 2 — via Fact_SnapshotEquity) |
| 6 | InProcessCashouts | money | Fact_SnapshotEquity.InProcessCashouts | Sum of pending withdrawal amounts for this CID that have not yet been finalized (statuses other than 3=Processed, 4=Cancelled, 5,6). Includes partially processed amounts for split-payment withdrawals plus associated fees. Computed by SP_Fact_SnapshotEquity_InProcessCashouts from Billing.Withdraw, History.WithdrawAction, and History.WithdrawToFundingAction. (Tier 2 — via Fact_SnapshotEquity) |
| 7 | TotalMirrorPositionsAmount | money | Fact_SnapshotEquity.TotalMirrorPositionsAmount | Sum of position amounts where MirrorID > 0 AND ParentPositionID != 0 (copy-trading positions only, excluding the parent/guru's own positions). Represents the CID's total investment in copy relationships. (Tier 2 — via Fact_SnapshotEquity) |
| 8 | TotalMirrorCash | money | Fact_SnapshotEquity.TotalMirrorCash | Cash available for copy-trading. Formula: TotalCash - Credit. (Tier 2 — via Fact_SnapshotEquity) |
| 9 | TotalStockOrders | money | Fact_SnapshotEquity.TotalStockOrders | Legacy column, hardcoded to 0. Removed 2019-03-03 (Boris Slutski) — no data in PROD since 2015. Kept for schema compatibility. (Tier 2 — via Fact_SnapshotEquity) |
| 10 | TotalMirrorStockOrders | money | Fact_SnapshotEquity.TotalMirrorStockOrders | Legacy column, hardcoded to 0. Removed 2019-03-03 alongside TotalStockOrders. Kept for schema compatibility. (Tier 2 — via Fact_SnapshotEquity) |
| 11 | RealizedEquity | money | Fact_SnapshotEquity.RealizedEquity | Customer's **settled (realized) equity** — the realized portion of customer balance. **Excludes unrealized PnL on open positions** (the unrealized component is `Fact_CustomerUnrealized_PnL.PositionPnL`). Computed as `History.ActiveCredit.RealizedEquity` if non-zero, otherwise `TotalCash + TotalPositionsAmount + InProcessCashouts` (cash + invested principal in open positions + pending cashouts). Together with PositionPnL it sums to the customer's full `Balance` per V_Liabilities: `Balance = RealizedEquity + PositionPnL`. NOTE: the Confluence definition of **Unrealized Equity** ("the total funds in the account, including profit/loss from open positions … the Portfolio value figure represented on the platform is Unrealized equity") describes `Balance` (= RealizedEquity + PositionPnL), **not RealizedEquity itself** — do not confuse the two. (Tier 2 — via Fact_SnapshotEquity) |
| 12 | Credit | money | Fact_SnapshotEquity.Credit | Outstanding credit/bonus balance from History.ActiveCredit. Last credit event per CID per day (selected via ROW_NUMBER partition by CID, ordered by Occurred DESC, CreditID DESC). Negative values represent outstanding obligations. (Tier 2 — via Fact_SnapshotEquity) |
| 13 | AUM | money | Fact_SnapshotEquity.AUM | Assets Under Management. Formula: TotalMirrorPositionAmount + TotalCash - Credit. For MERGE INSERT: computed as TotalMirrorPositionsAmount + TotalMirrorCash. Confluence: "AUC (or AUM) on PI Dashboard: Total Unrealized Copy Amount of the Copiers.". (Tier 2 — via Fact_SnapshotEquity) |
| 14 | BonusCredit | money | Fact_SnapshotEquity.BonusCredit | Bonus credit balance from History.ActiveCredit.BonusCredit. Confluence: "History.Credit.CreditTypeID = 5, 7 → BackOffice.BonusType.BonusTypeID → History.Credit.BonusTypeID". ISNULL to 0 in ETL. (Tier 2 — via Fact_SnapshotEquity) |
| 15 | CreditID | bigint | Fact_SnapshotEquity.CreditID | Last CreditID for this CID on this date from History.ActiveCredit. Selected as the most recent credit event via ROW_NUMBER(PARTITION BY CID, DateID ORDER BY Occurred DESC, CreditID DESC). Used for auditing which credit record drives the snapshot. (Tier 2 — via Fact_SnapshotEquity) |
| 16 | UpdateDate | datetime | Fact_SnapshotEquity.UpdateDate | ETL load timestamp (GETDATE() at MERGE/INSERT time). Used for detecting recent updates in the year-end carryover and IsSettled change handling. (Tier 2 — via Fact_SnapshotEquity) |
| 17 | TotalStockPositionAmount | money | Fact_SnapshotEquity.TotalStockPositionAmount | Sum of position amounts where InstrumentTypeID IN (5,6) AND instrument is NOT a future. Represents CFD and real stock positions (excluding futures that also have InstrumentTypeID 5/6). Added with mutual exclusivity fix (Guy M, 2025-07-29). (Tier 2 — via Fact_SnapshotEquity) |
| 18 | TotalMirrorStockPositionAmount | money | Fact_SnapshotEquity.TotalMirrorStockPositionAmount | Mirror (copy-trading) subset of TotalStockPositionAmount. Adds MirrorID > 0 AND ParentPositionID != 0. Same mutual exclusivity fix with futures. (Tier 2 — via Fact_SnapshotEquity) |
| 19 | TotalCryptoPositionAmount | money | Fact_SnapshotEquity.TotalCryptoPositionAmount | Sum of position amounts where InstrumentTypeID = 10 AND instrument is NOT a future. Represents CFD and real crypto positions. Confluence: "TotalCryptoPositionAmount + TotalStockPositionAmount = TotalPositionsAmount" (approximately, excluding other types). (Tier 2 — via Fact_SnapshotEquity) |
| 20 | TotalMirrorCryptoPositionAmount | money | Fact_SnapshotEquity.TotalMirrorCryptoPositionAmount | Mirror (copy-trading) subset of TotalCryptoPositionAmount. Same conditions plus MirrorID > 0 AND ParentPositionID != 0. (Tier 2 — via Fact_SnapshotEquity) |
| 21 | TotalRealStocks | decimal(16,2) | Fact_SnapshotEquity.TotalRealStocks | Sum of position amounts where IsSettled = 1 AND InstrumentTypeID IN (5,6) AND instrument is NOT a future. "Real" means the customer owns the underlying asset (settled/delivered). Updated via IsSettled change tracking from History.PositionChangeLog. (Tier 2 — via Fact_SnapshotEquity) |
| 22 | TotalRealCrypto | decimal(16,2) | Fact_SnapshotEquity.TotalRealCrypto | Sum of position amounts where IsSettled = 1 AND InstrumentTypeID = 10 AND instrument is NOT a future. Real crypto ownership (settled positions). Updated via IsSettled change tracking. (Tier 2 — via Fact_SnapshotEquity) |
| 23 | TotalRealCryptoLoan | decimal(16,2) | Fact_SnapshotEquity.TotalRealCryptoLoan | Sum of InitialAmount where IsSettled = 1 AND InstrumentTypeID = 10 AND NOT future AND Leverage = 2. Represents the initial investment in leveraged real crypto positions (the loan portion). Changed from Amount to InitialAmount on 2020-03-25. (Tier 2 — via Fact_SnapshotEquity) |
| 24 | TotalCashCalculation | money | Fact_SnapshotEquity.TotalCashCalculation | Parallel computation of TotalCash (same formula: TotalCashPreviousDate + TotalCashChangeAll). Exists as a validation/audit column to cross-check TotalCash. (Tier 2 — via Fact_SnapshotEquity) |
| 25 | TotalCryptoPositionAmount_TRS | decimal(16,2) | Fact_SnapshotEquity.TotalCryptoPositionAmount_TRS | Sum of crypto position amounts where SettlementTypeID = 2 (TRS — Total Return Swap) AND instrument is NOT a future. Added 2022-01-27 (Inbal BML). TRS positions have different regulatory treatment than settled positions. (Tier 2 — via Fact_SnapshotEquity) |
| 26 | TotalMirrorCryptoPositionAmount_TRS | decimal(16,2) | Fact_SnapshotEquity.TotalMirrorCryptoPositionAmount_TRS | Mirror (copy-trading) subset of TotalCryptoPositionAmount_TRS. TRS crypto positions in copy relationships. Added 2022-01-27. (Tier 2 — via Fact_SnapshotEquity) |
| 27 | Total_TRSCrypto | decimal(16,2) | Fact_SnapshotEquity.Total_TRSCrypto | Sum of crypto position amounts where IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2. CFD-style crypto positions under TRS settlement (not yet settled to real ownership). Added 2022-01-27. (Tier 2 — via Fact_SnapshotEquity) |
| 28 | TotalMirrorRealFuturesPositionAmount | decimal(16,2) | Fact_SnapshotEquity.TotalMirrorRealFuturesPositionAmount | Sum of futures position amounts where MirrorID > 0. From Dim_Instrument_Snapshot.IsFuture = 1. Added 2024-10-30 (Daniel Kaplan). (Tier 2 — via Fact_SnapshotEquity) |
| 29 | TotalRealFutures | decimal(16,2) | Fact_SnapshotEquity.TotalRealFutures | Sum of all futures position amounts. Identified via JOIN to Dim_Instrument_Snapshot where IsFuture = 1 for the snapshot DateID. Added 2024-10-30. (Tier 2 — via Fact_SnapshotEquity) |

## 5. Relationships

| Element | Related Object | Join | Description |
|---------|---------------|------|-------------|
| DateRangeID | Dim_Range | INNER JOIN ON DateRangeID | Decodes SCD2 range to FromDateID/ToDateID |
| DateKey | Dim_Date | INNER JOIN ON DateKey BETWEEN FromDateID AND ToDateID | Expands range to individual daily rows |
| CID | Dim_Customer | FK | Customer dimension (CID = RealCID) |

## 6. Access Patterns

```sql
-- Daily equity snapshot for a specific customer
SELECT * FROM DWH_dbo.V_Fact_SnapshotEquity
WHERE CID = @CID AND DateKey BETWEEN @FromDate AND @ToDate;
```

---
*Generated: 2026-03-28 | Quality: 8.5/10 (★★★★☆) | Batch: 17 | 29 columns expanded (28 Tier 1 from Fact_SnapshotEquity wiki + 1 DateKey) | Sources: SSDT DDL, Fact_SnapshotEquity.md*
