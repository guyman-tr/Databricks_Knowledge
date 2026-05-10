# DWH_dbo.V_Fact_SnapshotEquity_FromDateID

## 1. Overview

| Property | Value |
|----------|-------|
| **Full Name** | `[DWH_dbo].[V_Fact_SnapshotEquity_FromDateID]` |
| **Type** | View |
| **Base Tables** | `Fact_SnapshotEquity`, `Dim_Range` |
| **Purpose** | Exposes Fact_SnapshotEquity with explicit `FromDateID` and `ToDateID` columns from `Dim_Range`, enabling date-range filtering without an additional join to Dim_Date. |

## 2. Business Context

This is a thin utility view that denormalizes the SCD Type 2 `DateRangeID` by joining `Dim_Range` to expose `FromDateID` and `ToDateID` alongside all `Fact_SnapshotEquity` columns. Unlike `V_Fact_SnapshotEquity` (which expands to daily rows), this view preserves the range-level grain — one row per customer per date range.

**Use case**: Queries that need to filter by date range boundaries (e.g., "find equity snapshots starting from a specific date") without expanding to daily rows.

## 3. View Definition

```sql
SELECT R.FromDateID, R.ToDateID, SE.*
FROM DWH_dbo.Fact_SnapshotEquity SE WITH(NOLOCK)
JOIN DWH_dbo.Dim_Range R WITH(NOLOCK)
  ON SE.DateRangeID = R.DateRangeID
```

## 4. Relationships & Joins

| Relationship | Join Column(s) | Type | Notes |
|-------------|----------------|------|-------|
| `Fact_SnapshotEquity` → `Dim_Range` | `DateRangeID` | INNER JOIN | Adds FromDateID and ToDateID columns |

## 5. Elements

| # | Column | Type | Source | Description |
|---|--------|------|--------|-------------|
| 1 | FromDateID | int | Dim_Range.FromDateID | Start date of the equity snapshot range (YYYYMMDD integer). First 8 digits of the encoded DateRangeID. (Tier 1 — inherited from Dim_Range wiki) |
| 2 | ToDateID | int | Dim_Range.ToDateID | End date of the equity snapshot range (YYYYMMDD integer). Active rows have ToDateID = YYYY1231. (Tier 1 — inherited from Dim_Range wiki) |
| 3 | CID | int | Fact_SnapshotEquity.CID | Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 4 | DateRangeID | bigint | Fact_SnapshotEquity.DateRangeID | Encoded date range as 12-digit bigint (YYYYMMDDYYYY). Decoded via Dim_Range. Part of PK. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 5 | TotalPositionsAmount | money | Fact_SnapshotEquity.TotalPositionsAmount | Sum of all open position amounts (NewAmount) for this CID on this date. Includes all asset classes. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 6 | TotalCash | money | Fact_SnapshotEquity.TotalCash | Customer's total cash balance for the day. Running-balance approach. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 7 | InProcessCashouts | money | Fact_SnapshotEquity.InProcessCashouts | Sum of pending withdrawal amounts not yet finalized. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 8 | TotalMirrorPositionsAmount | money | Fact_SnapshotEquity.TotalMirrorPositionsAmount | Sum of copy-trading position amounts (MirrorID > 0 AND ParentPositionID != 0). (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 9 | TotalMirrorCash | money | Fact_SnapshotEquity.TotalMirrorCash | Cash available for copy-trading. Formula: TotalCash - Credit. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 10 | TotalStockOrders | money | Fact_SnapshotEquity.TotalStockOrders | Legacy column, hardcoded to 0. Kept for schema compatibility. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 11 | TotalMirrorStockOrders | money | Fact_SnapshotEquity.TotalMirrorStockOrders | Legacy column, hardcoded to 0. Kept for schema compatibility. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 12 | RealizedEquity | money | Fact_SnapshotEquity.RealizedEquity | Customer's settled (realized) equity — the realized portion of customer balance, excluding unrealized PnL on open positions (which lives in Fact_CustomerUnrealized_PnL.PositionPnL). From History.ActiveCredit.RealizedEquity if non-zero; otherwise TotalCash + TotalPositionsAmount + InProcessCashouts. Together with PositionPnL it sums to Balance per V_Liabilities (Balance = RealizedEquity + PositionPnL). (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 13 | Credit | money | Fact_SnapshotEquity.Credit | Outstanding credit/bonus balance from History.ActiveCredit. Last credit event per CID per day. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 14 | AUM | money | Fact_SnapshotEquity.AUM | Assets Under Management. Formula: TotalMirrorPositionAmount + TotalCash - Credit. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 15 | BonusCredit | money | Fact_SnapshotEquity.BonusCredit | Bonus credit balance from History.ActiveCredit.BonusCredit. ISNULL to 0 in ETL. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 16 | CreditID | bigint | Fact_SnapshotEquity.CreditID | Last CreditID for this CID on this date from History.ActiveCredit. Audit column. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 17 | UpdateDate | datetime | Fact_SnapshotEquity.UpdateDate | ETL load timestamp (GETDATE() at MERGE/INSERT time). (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 18 | TotalStockPositionAmount | money | Fact_SnapshotEquity.TotalStockPositionAmount | Sum of position amounts where InstrumentTypeID IN (5,6) AND instrument is NOT a future. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 19 | TotalMirrorStockPositionAmount | money | Fact_SnapshotEquity.TotalMirrorStockPositionAmount | Mirror (copy-trading) subset of TotalStockPositionAmount. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 20 | TotalCryptoPositionAmount | money | Fact_SnapshotEquity.TotalCryptoPositionAmount | Sum of position amounts where InstrumentTypeID = 10 AND instrument is NOT a future. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 21 | TotalMirrorCryptoPositionAmount | money | Fact_SnapshotEquity.TotalMirrorCryptoPositionAmount | Mirror subset of TotalCryptoPositionAmount. MirrorID > 0 AND ParentPositionID != 0. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 22 | TotalRealStocks | decimal(16,2) | Fact_SnapshotEquity.TotalRealStocks | Sum of position amounts where IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT future. "Real" = customer owns underlying asset. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 23 | TotalRealCrypto | decimal(16,2) | Fact_SnapshotEquity.TotalRealCrypto | Sum of settled crypto positions (IsSettled = 1, InstrumentTypeID = 10, NOT future). (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 24 | TotalRealCryptoLoan | decimal(16,2) | Fact_SnapshotEquity.TotalRealCryptoLoan | Sum of InitialAmount where IsSettled = 1 AND InstrumentTypeID = 10 AND Leverage = 2. Leveraged crypto loan portion. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 25 | TotalCashCalculation | money | Fact_SnapshotEquity.TotalCashCalculation | Parallel computation of TotalCash for validation/audit. Cross-check column. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 26 | TotalCryptoPositionAmount_TRS | decimal(16,2) | Fact_SnapshotEquity.TotalCryptoPositionAmount_TRS | Crypto position amounts where SettlementTypeID = 2 (TRS). (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 27 | TotalMirrorCryptoPositionAmount_TRS | decimal(16,2) | Fact_SnapshotEquity.TotalMirrorCryptoPositionAmount_TRS | Mirror subset of TotalCryptoPositionAmount_TRS. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 28 | Total_TRSCrypto | decimal(16,2) | Fact_SnapshotEquity.Total_TRSCrypto | CFD-style crypto positions under TRS settlement (IsSettled = 0, SettlementTypeID = 2). (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 29 | TotalMirrorRealFuturesPositionAmount | decimal(16,2) | Fact_SnapshotEquity.TotalMirrorRealFuturesPositionAmount | Sum of futures position amounts where MirrorID > 0. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 30 | TotalRealFutures | decimal(16,2) | Fact_SnapshotEquity.TotalRealFutures | Sum of all futures position amounts (IsFuture = 1). (Tier 1 — inherited from Fact_SnapshotEquity wiki) |

## 6. Data Lake / UC Mapping

| Path | UC Table |
|------|----------|
| Gold/sql_dp_prod_we/DWH_dbo/V_Fact_SnapshotEquity_FromDateID/ | dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid |

## 7. Access Patterns

```sql
-- Find equity snapshot active on a specific date
SELECT * FROM DWH_dbo.V_Fact_SnapshotEquity_FromDateID
WHERE FromDateID <= @DateID AND ToDateID >= @DateID AND CID = @CID;
```

---
*Generated: 2026-03-28 | Quality: 8.5/10 (★★★★☆) | Batch: 17 | 30 columns expanded (28 Tier 1 from Fact_SnapshotEquity wiki + 2 from Dim_Range) | Sources: SSDT DDL, Fact_SnapshotEquity.md, Dim_Range.md*
