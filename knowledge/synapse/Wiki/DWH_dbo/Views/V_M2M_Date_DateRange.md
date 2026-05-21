# DWH_dbo.V_M2M_Date_DateRange

> Many-to-many bridge view that expands date ranges from Dim_Range into individual calendar dates by joining with Dim_Date — enabling Snapshot analytics to associate each DateRangeID with every date within that range without date arithmetic at query time.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Base Tables** | DWH_dbo.Dim_Range, DWH_dbo.Dim_Date |
| **Purpose** | Date range expansion for Snapshot equity, customer, copier, and liability analytics |

---

## 1. Business Meaning

`V_M2M_Date_DateRange` is the many-to-many bridge between date ranges and individual calendar dates. It takes each row in `Dim_Range` (which defines a FromDate–ToDate interval) and JOINs it to `Dim_Date` to produce one row per calendar date within that range. This enables Snapshot queries (e.g., Fact_SnapshotEquity, Fact_SnapshotCustomer, Fact_Guru_Copiers) to efficiently look up "which dates fall within this date range?" without performing range inequality JOINs repeatedly.

For example, a DateRangeID representing January 1–March 19, 2026 would expand to 78 rows — one per calendar date in that interval.

---

## 2. Elements

| # | Column | Type | Source | Description |
|---|--------|------|--------|-------------|
| 1 | DateRangeID | bigint | Dim_Range.DateRangeID | Primary key (NOT ENFORCED). 12-digit composite key encoding FromDate and MMDD(ToDate). Formula: CONCAT(YYYYMMDD(From), MMDD(To)). Example: 200701011231 = From:20070101, To:20071231. (Tier 2 — via Dim_Range) |
| 2 | DateKey | int | Dim_Date.DateKey | Individual calendar date key in YYYYMMDD integer format. Falls within the range defined by Dim_Range.FromDateID and Dim_Range.ToDateID (inclusive). Primary key of Dim_Date. (Tier 2 — DDL + view logic) |
| 3 | FullDate | date | Dim_Date.FullDate | Calendar date corresponding to DateKey in native DATE format. Provides the human-readable date for the YYYYMMDD integer key. (Tier 2 — DDL + view logic) |

---

## 3. Relationships & JOINs

| Related Object | JOIN Condition | Relationship | Direction |
|----------------|----------------|--------------|-----------|
| DWH_dbo.Dim_Range | `R.FromDateID <= D.DateKey AND R.ToDateID >= D.DateKey` | Date range source (fan-out) | Inbound |
| DWH_dbo.Dim_Date | Same range inequality JOIN | Calendar date source (fan-out) | Inbound |
| DWH_dbo.V_Customers | Referenced in view definition | Downstream consumer | Outbound |
| DWH_dbo.V_Liabilities | Referenced in view definition | Downstream consumer | Outbound |
| DWH_dbo.SP_Fact_Guru_Copiers | Date range expansion for copier snapshots | Downstream consumer | Outbound |
| DWH_dbo.SP_Fact_CustomerUnrealized_PnL | PnL snapshot date range handling | Downstream consumer | Outbound |
| DWH_dbo.SP_Fact_CustomerUnrealized_PnL_V0 | Legacy PnL snapshot date range handling | Downstream consumer | Outbound |
| BI_DB_dbo.SP_ASIC_ClientBalanceFinance | ASIC regulatory client balance calculations | Downstream consumer | Outbound |
| BI_DB_dbo.SP_DepositWithdrawFee_Before_2025_05_For_Audit | Audit deposit/withdrawal fee date range expansion | Downstream consumer | Outbound |

---

## 4. ETL & Data Pipeline

No ETL — computed view. The result set grows as Dim_Range accumulates new date range pairs (daily INSERT-only by Snapshot SPs). Both base tables are REPLICATE distributed in Synapse, so the range inequality JOIN runs locally on each compute node.

**Cardinality warning**: This is a fan-out JOIN. With ~1.3M rows in Dim_Range and date ranges spanning up to full years, the view can produce billions of virtual rows. Always filter on DateRangeID or DateKey.

---

## 5. Referenced By

| Object | Schema | Usage |
|--------|--------|-------|
| V_Customers | DWH_dbo | Date range expansion for customer snapshot views |
| V_Liabilities | DWH_dbo | Date range expansion for liability snapshot views |
| SP_Fact_Guru_Copiers | DWH_dbo | Copier snapshot date range expansion |
| SP_Fact_CustomerUnrealized_PnL | DWH_dbo | Unrealized PnL snapshot date range handling |
| SP_Fact_CustomerUnrealized_PnL_V0 | DWH_dbo | Legacy unrealized PnL snapshot date range handling |
| SP_ASIC_ClientBalanceFinance | BI_DB_dbo | ASIC regulatory client balance date range expansion |
| SP_DepositWithdrawFee_Before_2025_05_For_Audit | BI_DB_dbo | Audit-period deposit/withdrawal fee date range expansion |

---

## 6. Business Logic & Patterns

### Range Inequality JOIN

```sql
FROM Dim_Range R
INNER JOIN Dim_Date D
  ON R.FromDateID <= D.DateKey
  AND R.ToDateID >= D.DateKey
```

This is a range inequality JOIN — each Dim_Range row matches all Dim_Date rows where `DateKey` falls between `FromDateID` and `ToDateID` inclusive. The result is a fan-out: one Dim_Range row with a 30-day range produces 30 output rows.

### DateRangeID Encoding

DateRangeID is a deterministic 12-digit BigInt: `CONCAT(YYYYMMDD(FromDate), MMDD(ToDate))`. The year of ToDate always equals the year of FromDate (only MMDD is stored in the last 4 digits). See Dim_Range wiki for full encoding details.

---

## 7. Query Advisory

### Performance Considerations

- **Never SELECT * without a filter** — the unfiltered view can produce billions of rows
- **Always filter on DateRangeID** when joining from Fact_SnapshotCustomer or Fact_SnapshotEquity
- **Alternatively filter on DateKey range** for calendar-bounded queries
- Both Dim_Range and Dim_Date are REPLICATE distributed, so the JOIN runs locally on each distribution — no data movement

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

*Generated: 2026-03-28 | Quality: 8.5/10 (★★★★☆) | Phases: 8/14 | Batch: 16*
*Tiers: 1 T1, 2 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10*
*Object: DWH_dbo.V_M2M_Date_DateRange | Type: View | Base Tables: DWH_dbo.Dim_Range, DWH_dbo.Dim_Date*
