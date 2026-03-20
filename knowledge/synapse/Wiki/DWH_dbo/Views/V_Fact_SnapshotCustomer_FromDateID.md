# DWH_dbo.V_Fact_SnapshotCustomer_FromDateID

## 1. Overview

| Property | Value |
|----------|-------|
| **Full Name** | `[DWH_dbo].[V_Fact_SnapshotCustomer_FromDateID]` |
| **Type** | View |
| **Base Tables** | `Fact_SnapshotCustomer`, `Dim_Range` |
| **Purpose** | Exposes Fact_SnapshotCustomer with explicit `FromDateID` and `ToDateID` columns from `Dim_Range`, enabling date-range boundary filtering without expanding to daily rows. |

## 2. Business Context

Structurally identical pattern to `V_Fact_SnapshotEquity_FromDateID`. Denormalizes the SCD Type 2 `DateRangeID` by joining `Dim_Range` to expose date boundaries alongside all `Fact_SnapshotCustomer` columns. Preserves the range-level grain (one row per customer per date range).

## 3. View Definition

```sql
SELECT R.FromDateID, R.ToDateID, SC.*
FROM DWH_dbo.Fact_SnapshotCustomer SC WITH(NOLOCK)
JOIN DWH_dbo.Dim_Range R WITH(NOLOCK)
  ON SC.DateRangeID = R.DateRangeID
```

## 4. Elements

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | `FromDateID` | Dim_Range.FromDateID | Start date of the customer snapshot range (YYYYMMDD integer). (Tier 2 — view DDL) |
| 2 | `ToDateID` | Dim_Range.ToDateID | End date of the customer snapshot range (YYYYMMDD integer). Active rows have ToDateID = YYYY1231. (Tier 2 — view DDL) |
| 3+ | All Fact_SnapshotCustomer columns | `SC.*` | See [Fact_SnapshotCustomer.md](../Tables/Fact_SnapshotCustomer.md) for full column documentation. (Tier 2 — inherited) |

---
*Generated: 2026-03-19 | Quality: 7.5/10 | Thin view delegates to Fact_SnapshotCustomer*
