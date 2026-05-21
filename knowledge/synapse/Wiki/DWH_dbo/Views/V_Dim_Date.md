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
| 1 | DateKey | int | Dim_Date.DateKey | Date as YYYYMMDD integer. Logical key of the view. (Tier 3 — DDL inference) |
| 2 | FullDate | date | Dim_Date.FullDate | Calendar date value. Reference date for all computed flags. (Tier 3 — DDL inference) |
| 3 | MonthNumberOfYear | tinyint | Dim_Date.MonthNumberOfYear | Month number (1–12). (Tier 3 — DDL inference) |
| 4 | MonthNumberOfQuarter | tinyint | Dim_Date.MonthNumberOfQuarter | Month position within the quarter (1–3). (Tier 3 — DDL inference) |
| 5 | ISOYearAndWeekNumber | char(7) | Dim_Date.ISOYearAndWeekNumber | ISO year + week (e.g., '2026W13'). (Tier 3 — DDL inference) |
| 6 | ISOWeekNumberOfYear | tinyint | Dim_Date.ISOWeekNumberOfYear | ISO week number (1–53). (Tier 3 — DDL inference) |
| 7 | SSWeekNumberOfYear | tinyint | Dim_Date.SSWeekNumberOfYear | SQL Server week number (DATEPART WEEK). (Tier 3 — DDL inference) |
| 8 | ISOWeekNumberOfQuarter_454_Pattern | tinyint | Dim_Date.ISOWeekNumberOfQuarter_454_Pattern | ISO week within quarter using 4-5-4 retail calendar pattern. (Tier 3 — DDL inference) |
| 9 | SSWeekNumberOfQuarter_454_Pattern | tinyint | Dim_Date.SSWeekNumberOfQuarter_454_Pattern | SQL Server week within quarter using 4-5-4 retail pattern. (Tier 3 — DDL inference) |
| 10 | SSWeekNumberOfMonth | tinyint | Dim_Date.SSWeekNumberOfMonth | Week number within the month (SQL Server). (Tier 3 — DDL inference) |
| 11 | DayNumberOfYear | smallint | Dim_Date.DayNumberOfYear | Day of year (1–366). (Tier 3 — DDL inference) |
| 12 | DaysSince1900 | int | Dim_Date.DaysSince1900 | Days elapsed since 1900-01-01. Useful for date arithmetic. (Tier 3 — DDL inference) |
| 13 | DayNumberOfFiscalYear | smallint | Dim_Date.DayNumberOfFiscalYear | Day of fiscal year (1–366). Fiscal year starts July 1. (Tier 3 — DDL inference) |
| 14 | DayNumberOfQuarter | smallint | Dim_Date.DayNumberOfQuarter | Day position within the quarter (1–92). (Tier 3 — DDL inference) |
| 15 | DayNumberOfMonth | tinyint | Dim_Date.DayNumberOfMonth | Day of month (1–31). (Tier 3 — DDL inference) |
| 16 | DayNumberOfWeek_Sun_Start | tinyint | Dim_Date.DayNumberOfWeek_Sun_Start | Day of week (1=Sunday, 7=Saturday). (Tier 3 — DDL inference) |
| 17 | MonthName | varchar(10) | Dim_Date.MonthName | Full month name (e.g., 'January'). (Tier 3 — DDL inference) |
| 18 | MonthNameAbbreviation | char(3) | Dim_Date.MonthNameAbbreviation | 3-letter month abbreviation (e.g., 'Jan'). (Tier 3 — DDL inference) |
| 19 | DayName | varchar(10) | Dim_Date.DayName | Full day name (e.g., 'Monday'). (Tier 3 — DDL inference) |
| 20 | DayNameAbbreviation | char(3) | Dim_Date.DayNameAbbreviation | 3-letter day abbreviation (e.g., 'Mon'). (Tier 3 — DDL inference) |
| 21 | CalendarYear | smallint | Dim_Date.CalendarYear | Calendar year (e.g., 2026). (Tier 3 — DDL inference) |
| 22 | CalendarYearMonth | char(7) | Dim_Date.CalendarYearMonth | Year-month string (e.g., '2026-03'). (Tier 3 — DDL inference) |
| 23 | CalendarYearQtr | char(7) | Dim_Date.CalendarYearQtr | Year-quarter string (e.g., '2026-Q1'). (Tier 3 — DDL inference) |
| 24 | CalendarSemester | tinyint | Dim_Date.CalendarSemester | Half-year (1 or 2). (Tier 3 — DDL inference) |
| 25 | CalendarQuarter | tinyint | Dim_Date.CalendarQuarter | Calendar quarter (1–4). (Tier 3 — DDL inference) |
| 26 | FiscalYear | smallint | Dim_Date.FiscalYear | Fiscal year. Starts July 1. (Tier 3 — DDL inference) |
| 27 | FiscalMonth | tinyint | Dim_Date.FiscalMonth | Fiscal month (1–12, starting from fiscal year start). (Tier 3 — DDL inference) |
| 28 | FiscalQuarter | tinyint | Dim_Date.FiscalQuarter | Fiscal quarter (1–4). (Tier 3 — DDL inference) |
| 29 | FiscalYearMonth | char(7) | Dim_Date.FiscalYearMonth | Fiscal year-month string. (Tier 3 — DDL inference) |
| 30 | FiscalYearQtr | char(8) | Dim_Date.FiscalYearQtr | Fiscal year-quarter string. (Tier 3 — DDL inference) |
| 31 | QuarterNumber | int | Dim_Date.QuarterNumber | Absolute quarter number (monotonically increasing across years). (Tier 3 — DDL inference) |
| 32 | YYYYMMDD | char(8) | Dim_Date.YYYYMMDD | Date formatted as 'YYYYMMDD' string. (Tier 3 — DDL inference) |
| 33 | MM/DD/YYYY | char(10) | Dim_Date.MM/DD/YYYY | Date formatted as 'MM/DD/YYYY'. US format. (Tier 3 — DDL inference) |
| 34 | YYYY/MM/DD | char(10) | Dim_Date.YYYY/MM/DD | Date formatted as 'YYYY/MM/DD'. (Tier 3 — DDL inference) |
| 35 | YYYY-MM-DD | char(10) | Dim_Date.YYYY-MM-DD | Date formatted as 'YYYY-MM-DD'. ISO 8601. (Tier 3 — DDL inference) |
| 36 | MonDDYYYY | char(11) | Dim_Date.MonDDYYYY | Date formatted as 'Mon DD YYYY' (e.g., 'Mar 28 2026'). (Tier 3 — DDL inference) |
| 37 | IsLastDayOfMonth | char(1) | Dim_Date.IsLastDayOfMonth | 'Y' if date is the last day of its month, 'N' otherwise. (Tier 3 — DDL inference) |
| 38 | IsWeekday | char(1) | Dim_Date.IsWeekday | 'Y' if Monday–Friday, 'N' otherwise. (Tier 3 — DDL inference) |
| 39 | IsWeekend | char(1) | Dim_Date.IsWeekend | 'Y' if Saturday–Sunday, 'N' otherwise. (Tier 3 — DDL inference) |
| 40 | IsWorkday | char(1) | Dim_Date.IsWorkday | 'Y' if working day (weekday and not holiday). DEFAULT 'N'. (Tier 3 — DDL inference) |
| 41 | IsFederalHoliday | char(1) | Dim_Date.IsFederalHoliday | 'Y' if federal holiday. DEFAULT 'N'. (Tier 3 — DDL inference) |
| 42 | IsBankHoliday | char(1) | Dim_Date.IsBankHoliday | 'Y' if bank holiday. DEFAULT 'N'. (Tier 3 — DDL inference) |
| 43 | IsCompanyHoliday | char(1) | Dim_Date.IsCompanyHoliday | 'Y' if company holiday. DEFAULT 'N'. (Tier 3 — DDL inference) |
| 44 | CalculatedWeekNumber | int | Computed | `DATEDIFF(dd, '2000-01-02', FullDate) / 7` — sequential week number since 2000-01-02 (Monday-aligned). (Tier 2 — view DDL) |
| 45 | IsCurrentDay | varchar | Computed | `'Yes'` when FullDate equals yesterday (T-1). (Tier 2 — view DDL) |
| 46 | IsCurrentMonth | varchar | Computed | `'Yes'` when FullDate falls in yesterday's calendar month. (Tier 2 — view DDL) |
| 47 | IsCurrentQuarter | varchar | Computed | `'Yes'` when FullDate falls in yesterday's calendar quarter. (Tier 2 — view DDL) |
| 48 | IsCurrentYear | varchar | Computed | `'Yes'` when FullDate falls in yesterday's calendar year. (Tier 2 — view DDL) |
| 49 | IsPreviousYearClosingDate | varchar | Computed | `'Yes'` for Dec 31 of the year before yesterday's year. (Tier 2 — view DDL) |
| 50 | IsPreviousQuarterClosingDate | varchar | Computed | `'Yes'` for the last day of the quarter before yesterday's quarter. (Tier 2 — view DDL) |
| 51 | IsPreviousMonthClosingDate | varchar | Computed | `'Yes'` for the last day of the month before yesterday's month. (Tier 2 — view DDL) |
| 52 | IsPreviousYearOpeningDate | varchar | Computed | `'Yes'` for Jan 1 of the year before yesterday's year. (Tier 2 — view DDL) |
| 53 | IsPreviousQuarterOpeningDate | varchar | Computed | `'Yes'` for the first day of the quarter before yesterday's quarter. (Tier 2 — view DDL) |
| 54 | IsPreviousMonthOpeningDate | varchar | Computed | `'Yes'` for the first day of the month before yesterday's month. (Tier 2 — view DDL) |
| 55 | SSYearAndWeekNumber | varchar | Computed | SQL Server-style year+week string, e.g. `2026W12`. Zero-padded week number. (Tier 2 — view DDL) |
| 56 | IsCurrentWeek | varchar | Computed | `'Yes'` when FullDate falls in yesterday's ISO-style week (Sunday to Saturday). (Tier 2 — view DDL) |
| 57 | IsPreviousWeekClosingDate | varchar | Computed | `'Yes'` for the last day of the week before yesterday's week. (Tier 2 — view DDL) |
| 58 | IsPreviousWeekOpeningDate | varchar | Computed | `'Yes'` for the first day of the week before yesterday's week. (Tier 2 — view DDL) |
| 59 | IscURRENTWeekClosingDate | varchar | Computed | `'Yes'` for the last day of yesterday's current week. Note: column name has mixed-case typo in source DDL. (Tier 2 — view DDL) |
| 60 | IsCurrentWeekOpeningDate | varchar | Computed | `'Yes'` for the first day of yesterday's current week. (Tier 2 — view DDL) |
| 61 | Is8wBenchmark | varchar | Computed | `'Yes'` for same-weekday dates within the last 8 weeks before yesterday — used for week-over-week benchmarking. (Tier 2 — view DDL) |
| 62 | IsCurrentYearOpeningDate | varchar | Computed | `'Yes'` for Jan 1 of yesterday's year. (Tier 2 — view DDL) |
| 63 | IsCurrentQuarterOpeningDate | varchar | Computed | `'Yes'` for the first day of yesterday's current quarter. (Tier 2 — view DDL) |
| 64 | IsCurrentMonthOpeningDate | varchar | Computed | `'Yes'` for the first day of yesterday's current month. (Tier 2 — view DDL) |
| 65 | IsCurrentYearClosingDate | varchar | Computed | `'Yes'` for Dec 31 of yesterday's year. (Tier 2 — view DDL) |
| 66 | IsCurrentQuarterClosingDate | varchar | Computed | `'Yes'` for the last day of yesterday's current quarter. (Tier 2 — view DDL) |
| 67 | IsCurrentMonthClosingDate | varchar | Computed | `'Yes'` for the last day of yesterday's current month. (Tier 2 — view DDL) |

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

*Generated: 2026-03-28 | Quality: 8.5/10 (★★★★☆) | Phases: 8/14 | Column expansion: 67 cols documented individually (43 static + 24 computed)*
*Tiers: 0 T1, 24 T2, 43 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 8/10*
*Object: DWH_dbo.V_Dim_Date | Type: View | Base Table: DWH_dbo.Dim_Date (no upstream wiki — static cols Tier 3 DDL inference)*
