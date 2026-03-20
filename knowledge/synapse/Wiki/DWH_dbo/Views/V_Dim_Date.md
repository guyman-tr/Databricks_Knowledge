# DWH_dbo.V_Dim_Date

> Enriched date dimension view that adds ~20 dynamic temporal flags to the base Dim_Date table — IsCurrentDay, IsCurrentMonth, IsCurrentWeek, opening/closing dates, and benchmarks — all computed relative to yesterday's date.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Base Table** | DWH_dbo.Dim_Date |
| **Computed Columns** | ~20 dynamic CASE expressions + CalculatedWeekNumber |
| **Reference Date** | `DATEADD(DD, -1, GETDATE())` — all flags are relative to yesterday |

---

## 1. Business Meaning

`V_Dim_Date` is the primary date dimension view used by BI reports and dashboards. It wraps `Dim_Date` and adds dynamic temporal classification columns — answering questions like "Is this row's date the current day? Current month? Current quarter?" — all relative to yesterday (T-1), which is the DWH's reporting anchor date.

The view provides:
- **Period membership flags**: IsCurrentDay, IsCurrentMonth, IsCurrentQuarter, IsCurrentYear, IsCurrentWeek
- **Period boundary flags**: Opening/closing dates for previous/current year, quarter, month, and week
- **Benchmark flags**: Is8wBenchmark (same weekday within the last 8 weeks, for week-over-week comparison)
- **Week numbering**: CalculatedWeekNumber (week number since 2000-01-02), SSYearAndWeekNumber (SQL Server week format)

All computed flags return `'Yes'` or `'No'` strings. The `PartitionID` column from Dim_Date is excluded (commented out).

---

## 2. Elements

| # | Column | Type | Source | Description |
|---|--------|------|--------|-------------|
| 1-42 | *(All Dim_Date columns)* | *(inherited)* | Dim_Date | All base date dimension columns except PartitionID — DateKey, FullDate, calendar/fiscal hierarchies, day/month/week names, format variants, holiday/weekend flags. See Dim_Date documentation. (Tier 2 — Dim_Date DDL) |
| 43 | CalculatedWeekNumber | int | Computed | `DATEDIFF(dd, '2000-01-02', FullDate) / 7` — sequential week number since 2000-01-02 (Monday-aligned). (Tier 2 — view DDL) |
| 44 | IsCurrentDay | varchar | Computed | `'Yes'` when FullDate equals yesterday (T-1). (Tier 2 — view DDL) |
| 45 | IsCurrentMonth | varchar | Computed | `'Yes'` when FullDate falls in yesterday's calendar month. (Tier 2 — view DDL) |
| 46 | IsCurrentQuarter | varchar | Computed | `'Yes'` when FullDate falls in yesterday's calendar quarter. (Tier 2 — view DDL) |
| 47 | IsCurrentYear | varchar | Computed | `'Yes'` when FullDate falls in yesterday's calendar year. (Tier 2 — view DDL) |
| 48 | IsPreviousYearClosingDate | varchar | Computed | `'Yes'` for Dec 31 of the year before yesterday's year. (Tier 2 — view DDL) |
| 49 | IsPreviousQuarterClosingDate | varchar | Computed | `'Yes'` for the last day of the quarter before yesterday's quarter. (Tier 2 — view DDL) |
| 50 | IsPreviousMonthClosingDate | varchar | Computed | `'Yes'` for the last day of the month before yesterday's month. (Tier 2 — view DDL) |
| 51 | IsPreviousYearOpeningDate | varchar | Computed | `'Yes'` for Jan 1 of the year before yesterday's year. (Tier 2 — view DDL) |
| 52 | IsPreviousQuarterOpeningDate | varchar | Computed | `'Yes'` for the first day of the quarter before yesterday's quarter. (Tier 2 — view DDL) |
| 53 | IsPreviousMonthOpeningDate | varchar | Computed | `'Yes'` for the first day of the month before yesterday's month. (Tier 2 — view DDL) |
| 54 | SSYearAndWeekNumber | varchar | Computed | SQL Server-style year+week string, e.g. `2026W12`. Zero-padded week number. (Tier 2 — view DDL) |
| 55 | IsCurrentWeek | varchar | Computed | `'Yes'` when FullDate falls in yesterday's ISO-style week (Sunday to Saturday). (Tier 2 — view DDL) |
| 56 | IsPreviousWeekClosingDate | varchar | Computed | `'Yes'` for the last day of the week before yesterday's week. (Tier 2 — view DDL) |
| 57 | IsPreviousWeekOpeningDate | varchar | Computed | `'Yes'` for the first day of the week before yesterday's week. (Tier 2 — view DDL) |
| 58 | IsCurrentWeekClosingDate | varchar | Computed | `'Yes'` for the last day of yesterday's current week. Note: column name has typo `IscURRENTWeekClosingDate` in source DDL. (Tier 2 — view DDL) |
| 59 | IsCurrentWeekOpeningDate | varchar | Computed | `'Yes'` for the first day of yesterday's current week. (Tier 2 — view DDL) |
| 60 | Is8wBenchmark | varchar | Computed | `'Yes'` for same-weekday dates within the last 8 weeks before yesterday — used for week-over-week benchmarking. (Tier 2 — view DDL) |
| 61 | IsCurrentYearOpeningDate | varchar | Computed | `'Yes'` for Jan 1 of yesterday's year. (Tier 2 — view DDL) |
| 62 | IsCurrentQuarterOpeningDate | varchar | Computed | `'Yes'` for the first day of yesterday's current quarter. (Tier 2 — view DDL) |
| 63 | IsCurrentMonthOpeningDate | varchar | Computed | `'Yes'` for the first day of yesterday's current month. (Tier 2 — view DDL) |
| 64 | IsCurrentYearClosingDate | varchar | Computed | `'Yes'` for Dec 31 of yesterday's year. (Tier 2 — view DDL) |
| 65 | IsCurrentQuarterClosingDate | varchar | Computed | `'Yes'` for the last day of yesterday's current quarter. (Tier 2 — view DDL) |
| 66 | IsCurrentMonthClosingDate | varchar | Computed | `'Yes'` for the last day of yesterday's current month. (Tier 2 — view DDL) |

---

## 3. Relationships & JOINs

| Related Object | JOIN Condition | Relationship | Direction |
|----------------|----------------|--------------|-----------|
| DWH_dbo.Dim_Date | Base table (1:1) | Source | Inbound |

---

## 4. ETL & Data Pipeline

No ETL — this is a computed view. All temporal flags are recalculated dynamically at query time relative to `GETDATE()`.

---

## 5. Referenced By

| Object | Usage |
|--------|-------|
| BI reports and dashboards | Primary date dimension interface — filters on IsCurrentDay, IsCurrentMonth, etc. |
| SP_Fact_Guru_Copiers | Uses V_Dim_Date / V_M2M_Date_DateRange for date range handling |
| SP_Fact_CustomerUnrealized_PnL | Date dimension access |

---

## 6. Business Logic & Patterns

### Key Design Decisions

- **T-1 anchor**: All "current" flags are relative to yesterday (`DATEADD(DD, -1, GETDATE())`), not today. This aligns with DWH convention: the DWH processes yesterday's data overnight, so "current" means "the most recently processed business day."
- **String flags**: All computed columns return `'Yes'`/`'No'` strings (not BIT). This is likely for Tableau/SSRS compatibility.
- **PartitionID excluded**: The base Dim_Date.PartitionID column is commented out in this view.
- **Column name typo**: `IscURRENTWeekClosingDate` has mixed casing — a known cosmetic issue in the DDL.

---

## 7. Query Advisory

### Recommended Patterns

```sql
-- Get yesterday's row with all temporal context
SELECT * FROM [DWH_dbo].[V_Dim_Date] WHERE IsCurrentDay = 'Yes';

-- Get all dates in the current month
SELECT DateKey, FullDate FROM [DWH_dbo].[V_Dim_Date] WHERE IsCurrentMonth = 'Yes';

-- Week-over-week benchmark dates
SELECT DateKey, FullDate, DayName FROM [DWH_dbo].[V_Dim_Date] WHERE Is8wBenchmark = 'Yes';
```

### Performance Notes

- View is computed at query time — every query re-evaluates all 20+ CASE expressions
- For large JOINs, consider filtering on `Dim_Date.DateKey` directly and computing temporal flags in your query

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| [DWH Dim_Date, Dim_Range and View V_M2M_Date_DateRange](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/12952666154) | Confluence documentation covering the date dimension family |
| [BI Dictionary](https://etoro-jira.atlassian.net/wiki/spaces/BI/pages/13060931862) | References Dim_Date as part of the core DWH table catalog |
| [DWH Usage](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/12788367785) | Service-level join patterns using Dim_Date with facts (e.g. Fact_SnapshotEquity, V_M2M_Date_DateRange, DateKey) |
| [DWH User Guide](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11604167900) | Daily snapshot / partition behavior for DWH reporting |

---

*Generated: 2026-03-19 | Quality: 8.0/10 (★★★★☆) | Phases: 8/14*
*Tiers: 0 T1, 24 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 8/10, Relationships: 6/10, Sources: 8/10*
*Object: DWH_dbo.V_Dim_Date | Type: View | Base Table: DWH_dbo.Dim_Date*
