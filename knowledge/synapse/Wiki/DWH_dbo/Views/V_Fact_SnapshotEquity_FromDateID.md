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

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | `FromDateID` | Dim_Range.FromDateID | Start date of the equity snapshot range (YYYYMMDD integer). (Tier 2 — view DDL) |
| 2 | `ToDateID` | Dim_Range.ToDateID | End date of the equity snapshot range (YYYYMMDD integer). Active rows have ToDateID = YYYY1231. (Tier 2 — view DDL) |
| 3–34 | All Fact_SnapshotEquity columns | `SE.*` | See [Fact_SnapshotEquity.md](../Tables/Fact_SnapshotEquity.md) for full column documentation. (Tier 2 — inherited) |

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
*Generated: 2026-03-19 | Quality: 7.5/10 | Phases: P1-DDL | View delegates to Fact_SnapshotEquity for column semantics*
