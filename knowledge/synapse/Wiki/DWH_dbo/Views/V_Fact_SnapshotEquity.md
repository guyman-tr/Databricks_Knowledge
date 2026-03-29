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
| 2 | CID | int | Fact_SnapshotEquity.CID | Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 3 | DateRangeID | bigint | Fact_SnapshotEquity.DateRangeID | Encoded date range as 12-digit bigint (YYYYMMDDYYYY). Decoded via Dim_Range. Part of PK. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 4 | TotalPositionsAmount | money | Fact_SnapshotEquity.TotalPositionsAmount | Sum of all open position amounts (NewAmount) for this CID on this date. Includes all asset classes. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 5 | TotalCash | money | Fact_SnapshotEquity.TotalCash | Customer's total cash balance for the day. Running-balance approach. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 6 | InProcessCashouts | money | Fact_SnapshotEquity.InProcessCashouts | Sum of pending withdrawal amounts not yet finalized. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 7 | TotalMirrorPositionsAmount | money | Fact_SnapshotEquity.TotalMirrorPositionsAmount | Sum of copy-trading position amounts (MirrorID > 0 AND ParentPositionID != 0). (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 8 | TotalMirrorCash | money | Fact_SnapshotEquity.TotalMirrorCash | Cash available for copy-trading. Formula: TotalCash - Credit. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 9 | TotalStockOrders | money | Fact_SnapshotEquity.TotalStockOrders | Legacy column, hardcoded to 0. Kept for schema compatibility. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 10 | TotalMirrorStockOrders | money | Fact_SnapshotEquity.TotalMirrorStockOrders | Legacy column, hardcoded to 0. Kept for schema compatibility. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 11 | RealizedEquity | money | Fact_SnapshotEquity.RealizedEquity | Total account value. From History.ActiveCredit.RealizedEquity if non-zero; otherwise TotalCash + TotalPositionsAmount + InProcessCashouts. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 12 | Credit | money | Fact_SnapshotEquity.Credit | Outstanding credit/bonus balance from History.ActiveCredit. Last credit event per CID per day. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 13 | AUM | money | Fact_SnapshotEquity.AUM | Assets Under Management. Formula: TotalMirrorPositionAmount + TotalCash - Credit. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 14 | BonusCredit | money | Fact_SnapshotEquity.BonusCredit | Bonus credit balance from History.ActiveCredit.BonusCredit. ISNULL to 0 in ETL. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 15 | CreditID | bigint | Fact_SnapshotEquity.CreditID | Last CreditID for this CID on this date from History.ActiveCredit. Audit column. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 16 | UpdateDate | datetime | Fact_SnapshotEquity.UpdateDate | ETL load timestamp (GETDATE() at MERGE/INSERT time). (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 17 | TotalStockPositionAmount | money | Fact_SnapshotEquity.TotalStockPositionAmount | Sum of position amounts where InstrumentTypeID IN (5,6) AND instrument is NOT a future. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 18 | TotalMirrorStockPositionAmount | money | Fact_SnapshotEquity.TotalMirrorStockPositionAmount | Mirror (copy-trading) subset of TotalStockPositionAmount. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 19 | TotalCryptoPositionAmount | money | Fact_SnapshotEquity.TotalCryptoPositionAmount | Sum of position amounts where InstrumentTypeID = 10 AND instrument is NOT a future. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 20 | TotalMirrorCryptoPositionAmount | money | Fact_SnapshotEquity.TotalMirrorCryptoPositionAmount | Mirror subset of TotalCryptoPositionAmount. MirrorID > 0 AND ParentPositionID != 0. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 21 | TotalRealStocks | decimal(16,2) | Fact_SnapshotEquity.TotalRealStocks | Sum of position amounts where IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT future. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 22 | TotalRealCrypto | decimal(16,2) | Fact_SnapshotEquity.TotalRealCrypto | Settled crypto positions (IsSettled = 1, InstrumentTypeID = 10, NOT future). (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 23 | TotalRealCryptoLoan | decimal(16,2) | Fact_SnapshotEquity.TotalRealCryptoLoan | Sum of InitialAmount for leveraged real crypto (IsSettled = 1, Leverage = 2). (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 24 | TotalCashCalculation | money | Fact_SnapshotEquity.TotalCashCalculation | Parallel computation of TotalCash for validation/audit. Cross-check column. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 25 | TotalCryptoPositionAmount_TRS | decimal(16,2) | Fact_SnapshotEquity.TotalCryptoPositionAmount_TRS | Crypto positions where SettlementTypeID = 2 (TRS). (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 26 | TotalMirrorCryptoPositionAmount_TRS | decimal(16,2) | Fact_SnapshotEquity.TotalMirrorCryptoPositionAmount_TRS | Mirror subset of TRS crypto positions. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 27 | Total_TRSCrypto | decimal(16,2) | Fact_SnapshotEquity.Total_TRSCrypto | CFD-style crypto under TRS settlement (IsSettled = 0, SettlementTypeID = 2). (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 28 | TotalMirrorRealFuturesPositionAmount | decimal(16,2) | Fact_SnapshotEquity.TotalMirrorRealFuturesPositionAmount | Futures position amounts where MirrorID > 0. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 29 | TotalRealFutures | decimal(16,2) | Fact_SnapshotEquity.TotalRealFutures | Sum of all futures position amounts (IsFuture = 1). (Tier 1 — inherited from Fact_SnapshotEquity wiki) |

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
