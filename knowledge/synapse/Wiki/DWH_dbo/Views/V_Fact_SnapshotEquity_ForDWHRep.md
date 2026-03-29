# DWH_dbo.V_Fact_SnapshotEquity_ForDWHRep

## 1. Overview

| Property | Value |
|----------|-------|
| **Full Name** | `[DWH_dbo].[V_Fact_SnapshotEquity_ForDWHRep]` |
| **Type** | View |
| **Base Tables** | `Fact_SnapshotEquity` |
| **Purpose** | Column subset of Fact_SnapshotEquity for replication to the legacy on-prem DWH (DWHFromSynapse). Adds a computed `PartitionCol` for replication partitioning. |

## 2. Business Context

This view selects 26 of 32 Fact_SnapshotEquity columns and adds a computed `PartitionCol = CID % 10` (integer 0–9). Used by the "Import Tables From Synapse To DWH" pipeline to partition the replication workload across 10 buckets.

**Excluded columns**: `TotalFuturesLockedCash`, `TotalMirrorRealFuturesPositionAmount`, `TotalRealFutures`, `TotalFuturesProviderMargin`, `TotalStockOrders`, `TotalMirrorStockOrders`.

## 3. View Definition

```sql
SELECT [CID], [DateRangeID], [TotalPositionsAmount], [TotalCash], [InProcessCashouts],
       [TotalMirrorPositionsAmount], [TotalMirrorCash], [TotalStockOrders], [TotalMirrorStockOrders],
       [RealizedEquity], [Credit], [AUM], [BonusCredit], [CreditID], [UpdateDate],
       [TotalStockPositionAmount], [TotalMirrorStockPositionAmount],
       [TotalCryptoPositionAmount], [TotalMirrorCryptoPositionAmount],
       [TotalRealStocks], [TotalRealCrypto], [TotalRealCryptoLoan], [TotalCashCalculation],
       [TotalCryptoPositionAmount_TRS], [TotalMirrorCryptoPositionAmount_TRS], [Total_TRSCrypto],
       CAST([CID] % 10 AS INT) AS [PartitionCol]
FROM [DWH_dbo].[Fact_SnapshotEquity]
```

## 4. Elements

| # | Column | Type | Source | Description |
|---|--------|------|--------|-------------|
| 1 | CID | int | Fact_SnapshotEquity.CID | Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 2 | DateRangeID | bigint | Fact_SnapshotEquity.DateRangeID | Encoded date range as 12-digit bigint (YYYYMMDDYYYY). FromDate in first 8 digits, ToDate suffix in last 4 digits. Decoded via Dim_Range. Part of PK. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 3 | TotalPositionsAmount | money | Fact_SnapshotEquity.TotalPositionsAmount | Sum of all open position amounts (NewAmount) for this CID on this date. Includes all asset classes: CFD, stocks, crypto, futures, margin. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 4 | TotalCash | money | Fact_SnapshotEquity.TotalCash | Customer's total cash balance for the day. Running-balance approach: previous day's TotalCash + sum of TotalCashChange from History.ActiveCredit. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 5 | InProcessCashouts | money | Fact_SnapshotEquity.InProcessCashouts | Sum of pending withdrawal amounts not yet finalized. Includes partially processed amounts and fees. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 6 | TotalMirrorPositionsAmount | money | Fact_SnapshotEquity.TotalMirrorPositionsAmount | Sum of position amounts where MirrorID > 0 AND ParentPositionID != 0 (copy-trading positions only). (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 7 | TotalMirrorCash | money | Fact_SnapshotEquity.TotalMirrorCash | Cash available for copy-trading. Formula: TotalCash - Credit. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 8 | TotalStockOrders | money | Fact_SnapshotEquity.TotalStockOrders | Legacy column, hardcoded to 0. Removed 2019-03-03. Kept for schema compatibility. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 9 | TotalMirrorStockOrders | money | Fact_SnapshotEquity.TotalMirrorStockOrders | Legacy column, hardcoded to 0. Removed 2019-03-03. Kept for schema compatibility. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 10 | RealizedEquity | money | Fact_SnapshotEquity.RealizedEquity | Total account value. From History.ActiveCredit.RealizedEquity if non-zero; otherwise TotalCash + TotalPositionsAmount + InProcessCashouts. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 11 | Credit | money | Fact_SnapshotEquity.Credit | Outstanding credit/bonus balance from History.ActiveCredit. Last credit event per CID per day. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 12 | AUM | money | Fact_SnapshotEquity.AUM | Assets Under Management. Formula: TotalMirrorPositionAmount + TotalCash - Credit. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 13 | BonusCredit | money | Fact_SnapshotEquity.BonusCredit | Bonus credit balance from History.ActiveCredit.BonusCredit. ISNULL to 0 in ETL. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 14 | CreditID | bigint | Fact_SnapshotEquity.CreditID | Last CreditID for this CID on this date from History.ActiveCredit. Used for auditing which credit record drives the snapshot. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 15 | UpdateDate | datetime | Fact_SnapshotEquity.UpdateDate | ETL load timestamp (GETDATE() at MERGE/INSERT time). Not the business event time. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 16 | TotalStockPositionAmount | money | Fact_SnapshotEquity.TotalStockPositionAmount | Sum of position amounts where InstrumentTypeID IN (5,6) AND instrument is NOT a future. CFD and real stock positions. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 17 | TotalMirrorStockPositionAmount | money | Fact_SnapshotEquity.TotalMirrorStockPositionAmount | Mirror (copy-trading) subset of TotalStockPositionAmount. MirrorID > 0 AND ParentPositionID != 0. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 18 | TotalCryptoPositionAmount | money | Fact_SnapshotEquity.TotalCryptoPositionAmount | Sum of position amounts where InstrumentTypeID = 10 AND instrument is NOT a future. CFD and real crypto positions. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 19 | TotalMirrorCryptoPositionAmount | money | Fact_SnapshotEquity.TotalMirrorCryptoPositionAmount | Mirror (copy-trading) subset of TotalCryptoPositionAmount. Same conditions plus MirrorID > 0 AND ParentPositionID != 0. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 20 | TotalRealStocks | decimal(16,2) | Fact_SnapshotEquity.TotalRealStocks | Sum of position amounts where IsSettled = 1 AND InstrumentTypeID IN (5,6) AND instrument is NOT a future. "Real" = customer owns underlying asset. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 21 | TotalRealCrypto | decimal(16,2) | Fact_SnapshotEquity.TotalRealCrypto | Sum of position amounts where IsSettled = 1 AND InstrumentTypeID = 10 AND instrument is NOT a future. Real crypto ownership (settled positions). (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 22 | TotalRealCryptoLoan | decimal(16,2) | Fact_SnapshotEquity.TotalRealCryptoLoan | Sum of InitialAmount where IsSettled = 1 AND InstrumentTypeID = 10 AND NOT future AND Leverage = 2. Leveraged real crypto loan portion. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 23 | TotalCashCalculation | money | Fact_SnapshotEquity.TotalCashCalculation | Parallel computation of TotalCash for validation/audit (same formula). Cross-check column. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 24 | TotalCryptoPositionAmount_TRS | decimal(16,2) | Fact_SnapshotEquity.TotalCryptoPositionAmount_TRS | Sum of crypto position amounts where SettlementTypeID = 2 (TRS — Total Return Swap) AND instrument is NOT a future. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 25 | TotalMirrorCryptoPositionAmount_TRS | decimal(16,2) | Fact_SnapshotEquity.TotalMirrorCryptoPositionAmount_TRS | Mirror (copy-trading) subset of TotalCryptoPositionAmount_TRS. TRS crypto in copy relationships. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 26 | Total_TRSCrypto | decimal(16,2) | Fact_SnapshotEquity.Total_TRSCrypto | Sum of crypto position amounts where IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2. CFD-style crypto under TRS settlement. (Tier 1 — inherited from Fact_SnapshotEquity wiki) |
| 27 | PartitionCol | int | Computed: CAST(CID % 10 AS INT) | Replication partition bucket (0–9). Used by the "Import Tables From Synapse To DWH" pipeline to distribute load across 10 buckets. (Tier 2 — view DDL) |

## 5. Known Issues

| Issue | Severity | Details |
|-------|----------|---------|
| Missing futures columns | Info | `TotalFuturesLockedCash` and 3 other futures columns excluded from replication. Legacy DWH may lack these columns. |

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| [DWH View Fact_SnapshotEquity](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/12932808821) | Column-level business meaning for Fact_SnapshotEquity (AUM, mirror amounts, unrealized equity context) |
| [Import Tables From Synapse To DWH](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11895309220) | Synapse → legacy DWH import process for facts/dims used by BI |
| [System Transfer Data From Synapse to DWHRep](https://etoro-jira.atlassian.net/wiki/spaces/DBAC/pages/12604604544) | Daily Synapse → DWHRep pipeline overview |
| [Trading Equity - Balance](https://etoro-jira.atlassian.net/wiki/spaces/~164971827/pages/12916359501) | Example Synapse queries against DWH liabilities/equity views |

---
*Generated: 2026-03-28 | Quality: 8.5/10 (★★★★☆) | Batch: 16 | 27 columns expanded (26 Tier 1 inherited from Fact_SnapshotEquity wiki + 1 computed) | Sources: SSDT DDL, Fact_SnapshotEquity.md*
