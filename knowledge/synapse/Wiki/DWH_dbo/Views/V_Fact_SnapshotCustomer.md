# DWH_dbo.V_Fact_SnapshotCustomer

## 1. Overview

| Property | Value |
|----------|-------|
| **Full Name** | `[DWH_dbo].[V_Fact_SnapshotCustomer]` |
| **Type** | View |
| **Base Tables** | `Fact_SnapshotCustomer`, `Dim_Range`, `Dim_Date` |
| **Purpose** | Expands Fact_SnapshotCustomer SCD2 date ranges into individual daily rows via `Dim_Range` + `Dim_Date` bridge. Adds `DateKey` for easy daily-grain queries. |

## 2. Business Context

This view converts the range-level SCD2 grain of `Fact_SnapshotCustomer` into a daily grain by joining through `Dim_Range` and `Dim_Date` (same pattern as `V_Fact_SnapshotEquity`). Each date range row is exploded into one row per day within the range, with `DateKey` identifying the specific day.

Unlike `V_Customers` (which applies ISNULL defaults and filters out today), this view exposes all raw columns including NULLs.

## 3. View Definition

```sql
SELECT DateKey, a.*
FROM DWH_dbo.Fact_SnapshotCustomer a WITH(NOLOCK)
JOIN DWH_dbo.Dim_Range b WITH(NOLOCK) ON a.DateRangeID = b.DateRangeID
JOIN DWH_dbo.Dim_Date d ON d.DateKey BETWEEN FromDateID AND ToDateID
```

## 4. Elements

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | `DateKey` | Dim_Date.DateKey | Specific date within the snapshot range (YYYYMMDD integer). One row per day per customer. (Tier 2 — view DDL) |
| 2+ | All Fact_SnapshotCustomer columns | `a.*` | See [Fact_SnapshotCustomer.md](../Tables/Fact_SnapshotCustomer.md). (Tier 2 — inherited) |

## 5. Access Patterns

```sql
-- Daily customer snapshot for a specific CID and date range
SELECT * FROM DWH_dbo.V_Fact_SnapshotCustomer
WHERE CID = @CID AND DateKey BETWEEN @FromDate AND @ToDate;
```

---
*Generated: 2026-03-19 | Quality: 7.5/10 | View delegates to Fact_SnapshotCustomer for column semantics*
