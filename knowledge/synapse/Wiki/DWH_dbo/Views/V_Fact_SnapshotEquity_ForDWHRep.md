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

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1–26 | Fact_SnapshotEquity columns | Direct SELECT | See [Fact_SnapshotEquity.md](../Tables/Fact_SnapshotEquity.md). (Tier 2 — inherited) |
| 27 | `PartitionCol` | Computed | `CAST(CID % 10 AS INT)` — replication partition bucket (0–9). Used by DWH import pipeline to distribute load. (Tier 3 — DDL inference) |

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
*Generated: 2026-03-19 | Quality: 7.6/10 | View delegates to Fact_SnapshotEquity for column semantics | Sources: 8/10*
