# DWH_dbo.V_M2M_Date_DateRange

> Many-to-many bridge view that expands date ranges from Dim_Range into individual dates by joining with Dim_Date — enabling Snapshot analytics to efficiently associate each DateRangeID with every calendar date within that range.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Base Tables** | DWH_dbo.Dim_Range, DWH_dbo.Dim_Date |
| **Purpose** | Date range expansion for Snapshot equity and customer analytics |

---

## 1. Business Meaning

`V_M2M_Date_DateRange` is the many-to-many bridge between date ranges and individual calendar dates. It takes each row in `Dim_Range` (which defines a FromDate–ToDate interval) and JOINs it to `Dim_Date` to produce one row per calendar date within that range. This enables Snapshot queries (e.g., Fact_SnapshotEquity, Fact_SnapshotCustomer) to efficiently look up "which dates fall within this date range?" without performing date arithmetic at query time.

For example, a DateRangeID representing January 1–March 19, 2026 would expand to 78 rows — one per calendar date in that interval. The view is used extensively by `SP_Fact_Guru_Copiers` and the `V_Customers` view family.

---

## 2. Elements

| # | Column | Type | Source | Description |
|---|--------|------|--------|-------------|
| 1 | DateRangeID | bigint | Dim_Range.DateRangeID | Composite key encoding (FromDate, MMDD(ToDate)) — identifies the date range. See Dim_Range wiki for encoding details. (Tier 1 — Dim_Range wiki) |
| 2 | DateKey | int | Dim_Date.DateKey | Individual calendar date key in YYYYMMDD format falling within the range. (Tier 2 — view DDL) |
| 3 | FullDate | date | Dim_Date.FullDate | Calendar date corresponding to DateKey. (Tier 2 — view DDL) |

---

## 3. Relationships & JOINs

| Related Object | JOIN Condition | Relationship | Direction |
|----------------|----------------|--------------|-----------|
| DWH_dbo.Dim_Range | `R.FromDateID <= D.DateKey AND R.ToDateID >= D.DateKey` | Date range source (fan-out) | Inbound |
| DWH_dbo.Dim_Date | Same JOIN as above | Calendar date source (fan-out) | Inbound |
| DWH_dbo.Fact_SnapshotCustomer | Joined via DateRangeID | Downstream consumer | Outbound |
| DWH_dbo.Fact_SnapshotEquity | Joined via DateRangeID | Downstream consumer | Outbound |
| DWH_dbo.Fact_Guru_Copiers | Referenced in SP_Fact_Guru_Copiers | Downstream consumer | Outbound |
| DWH_dbo.V_Customers | Referenced in view definition | Downstream consumer | Outbound |

---

## 4. ETL & Data Pipeline

No ETL — computed view. The result set grows as Dim_Range accumulates new date range pairs (daily INSERT-only by Snapshot SPs).

**Cardinality warning**: This is a fan-out JOIN. With ~1.3M rows in Dim_Range and date ranges spanning up to full years, the view can produce billions of virtual rows. Always filter on DateRangeID or DateKey.

---

## 5. Referenced By

| Object | Usage |
|--------|-------|
| SP_Fact_Guru_Copiers | Date range expansion for copier snapshots |
| V_Customers | Date range expansion for customer snapshots |
| SP_Fact_CustomerUnrealized_PnL | PnL snapshot date range handling |
| V_Liabilities | Liability snapshot date ranges |

---

## 6. Business Logic & Patterns

### JOIN Logic

```sql
FROM Dim_Range R
INNER JOIN Dim_Date D
  ON R.FromDateID <= D.DateKey
  AND R.ToDateID >= D.DateKey
```

This is a range inequality JOIN — each Dim_Range row matches all Dim_Date rows where `DateKey` falls between `FromDateID` and `ToDateID` inclusive. The result is a fan-out: one Dim_Range row with a 30-day range produces 30 output rows.

---

## 7. Query Advisory

### Performance Considerations

- **Never SELECT * without a filter** — the unfiltered view can produce billions of rows
- **Always filter on DateRangeID** when joining from Fact_SnapshotCustomer or Fact_SnapshotEquity
- **Alternatively filter on DateKey range** for calendar-bounded queries
- The underlying Dim_Range is REPLICATE distributed and Dim_Date is also REPLICATE, so the JOIN runs locally on each distribution

### Recommended Patterns

```sql
-- Expand a specific date range
SELECT DateKey, FullDate
FROM [DWH_dbo].[V_M2M_Date_DateRange]
WHERE DateRangeID = 202601010319;

-- Get all DateRangeIDs that include a specific date
SELECT DateRangeID
FROM [DWH_dbo].[V_M2M_Date_DateRange]
WHERE DateKey = 20260319;
```

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| [DWH Dim_Date, Dim_Range and View V_M2M_Date_DateRange](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/12952666154) | Dedicated Confluence page documenting this view alongside its base tables |

---

*Generated: 2026-03-19 | Quality: 8.0/10 (★★★★☆) | Phases: 8/14*
*Tiers: 1 T1, 2 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10*
*Object: DWH_dbo.V_M2M_Date_DateRange | Type: View | Base Tables: DWH_dbo.Dim_Range, DWH_dbo.Dim_Date*
