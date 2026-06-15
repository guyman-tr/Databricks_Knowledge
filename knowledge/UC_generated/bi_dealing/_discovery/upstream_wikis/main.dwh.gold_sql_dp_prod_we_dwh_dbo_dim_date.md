# DWH_dbo.Dim_Date

> 10,227-row calendar dimension covering 2007-01-01 → 2034-12-31 (one row per day, no duplicates). Pre-computed grain for every date-keyed table in the DWH and BI_DB layers — week/month/quarter/year hierarchies, fiscal calendar, ISO and Sunday-Start week numbering, retail 4-4-5 patterns, US holiday/weekend/workday flags, and string-format date variants. Populated by `SP_PopulateDimDate(@starting_dt, @ending_dt)` (Boris Slutski, 2018-02-08).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Computed in-warehouse — no upstream production system |
| **Refresh** | On-demand / annual extension (`SP_PopulateDimDate '20070101','20341231'`) — table is essentially static, only re-run when the calendar runway is extended |
| **Row Count** | 10,227 (one row per date) |
| **Date Range** | 2007-01-01 → 2034-12-31 |
| **Grain** | One row per calendar date |
| | |
| **Synapse Distribution** | (Inherited; small dim — typically REPLICATE) |
| **Synapse Index** | CLUSTERED on DateKey |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (generic pipeline) |

---

## 1. Business Meaning

`Dim_Date` is the canonical calendar dimension for the eToro DWH. Every fact and aggregate that reports along a date axis joins to it for week/month/quarter/year rollups, fiscal-year reporting, and weekday/holiday filters. Two week-numbering schemes are pre-computed so that BI consumers can pick whichever convention they need:

- **ISO** — week starts Monday, follows ISO-8601 (`ISOWeekNumberOfYear`, `ISOYearAndWeekNumber` like `'2026W16'`)
- **SS (Sunday-Start)** — week starts Sunday, US retail convention (`SSWeekNumberOfYear`, `SSWeekNumberOfMonth`)

Two retail-pattern columns (`ISOWeekNumberOfQuarter_454_Pattern`, `SSWeekNumberOfQuarter_454_Pattern`) precompute the **4-4-5 retail calendar** (a 13-week quarter split as 4+4+5 weeks) commonly used in finance reporting.

Holiday flags (`IsFederalHoliday`, `IsBankHoliday`, `IsCompanyHoliday`) are populated from a hard-coded US holiday calendar inside `SP_PopulateDimDate` (New Year's Day, MLK Day, Presidents Day, Memorial Day, Independence Day, Labor Day, Columbus Day, Veterans Day, Thanksgiving + day after, Christmas Eve + Christmas Day). Weekend-falling holidays roll forward/backward per US Federal observance rules.

The fiscal calendar uses `@FiscalYearMonthsOffset = 0` (i.e. fiscal year = calendar year). FiscalYear/Month/Quarter columns are present for forward compatibility if eToro switches to a non-calendar fiscal year.

---

## 2. Business Logic

### 2.1 Holiday Population (US calendar)

**What**: `IsFederalHoliday`, `IsBankHoliday`, `IsCompanyHoliday` flags are set per US Federal/bank holiday observance rules.
**Columns Involved**: `FullDate`, `IsFederalHoliday`, `IsBankHoliday`, `IsCompanyHoliday`
**Rules** (from `SP_PopulateDimDate`):
- New Year's Day: Jan 1 — observed on Monday if Jan 1 falls Sun, Friday before if Sat
- MLK Day: 3rd Monday of January
- Presidents Day: 3rd Monday of February
- Memorial Day: Last Monday of May
- Independence Day: Jul 4 — Mon-after if Sun, Fri-before if Sat
- Labor Day: 1st Monday of September
- Columbus Day: 2nd Monday of October
- Veterans Day: Nov 11
- Thanksgiving: 4th Thursday of November
- Day after Thanksgiving: bank/corp holiday only (not Federal)
- Christmas Eve: Dec 24 — corporate holiday only
- Christmas Day: Dec 25

eToro is global but the holiday calendar is US-only — analysts running EU/APAC reports should NOT rely on these flags as a generic "off day" indicator.

### 2.2 Workday vs Weekday vs Weekend

**What**: Three orthogonal day-class flags.
**Columns Involved**: `IsWeekday`, `IsWeekend`, `IsWorkday`
**Rules**:
- `IsWeekday = 'Y'` when day is Mon-Fri (regardless of holiday)
- `IsWeekend = 'Y'` when day is Sat-Sun
- `IsWorkday = 'Y'` when day is Mon-Fri AND NOT a federal/bank holiday

So `IsWorkday` is the right filter for "trading day" / "business day" analysis; `IsWeekday` is purely calendar-based.

### 2.3 4-4-5 Retail Quarter Pattern

**What**: `ISOWeekNumberOfQuarter_454_Pattern` and `SSWeekNumberOfQuarter_454_Pattern` express the week's position inside its quarter under the 4-4-5 retail calendar (13 weeks per quarter, split as 4+4+5).
**Use case**: Comparing week-over-week sales/revenue with anchored alignment to retail reporting periods.

### 2.4 String-Format Variants

**What**: Pre-computed string columns for joins / display formats: `YYYYMMDD`, `MM/DD/YYYY`, `YYYY/MM/DD`, `YYYY-MM-DD`, `MonDDYYYY`.
**Caveat**: The slash columns (`MM/DD/YYYY`, `YYYY/MM/DD`, `YYYY-MM-DD`) carry special characters in their identifier — backtick-quoting is required in Databricks SQL.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Small dimension; CLUSTERED on `DateKey`. Most date joins are on `DateKey` (int YYYYMMDD) or `FullDate`. Replicated to all distributions in practice.

### 3.1b UC (Databricks) Storage & Partitioning

10,227 rows — broadcast join automatic. No partitioning needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Filter to trading days | `JOIN Dim_Date d ON f.DateID = d.DateKey WHERE d.IsWorkday = 'Y'` |
| Roll up by ISO week | `JOIN Dim_Date d ON f.DateID = d.DateKey GROUP BY d.ISOYearAndWeekNumber` |
| Roll up by calendar month | `GROUP BY d.CalendarYearMonth` (`'2026-04'` form) |
| Filter to weekends only | `WHERE d.IsWeekend = 'Y'` |
| Filter to month-end | `WHERE d.IsLastDayOfMonth = 'Y'` |
| Convert int DateID to date | `JOIN Dim_Date d ON your_int_dateid = d.DateKey` (no CAST) |

### 3.3 Common JOINs

Dim_Date is the join target for every date-keyed fact in the warehouse. There are 100+ downstream tables that reference `DateKey`; most use `... ON fact.DateID = Dim_Date.DateKey`.

### 3.4 Gotchas

- **Y/N strings, not bits**: `IsWeekday`, `IsWeekend`, `IsWorkday`, `IsLastDayOfMonth`, `IsFirstDayOfMonth`, `IsFederalHoliday`, `IsBankHoliday`, `IsCompanyHoliday` are all `char(1)` containing `'Y'`/`'N'`, not bit/int. Always quote them.
- **Holiday calendar is US**: do not use `IsFederalHoliday` for European or APAC business-day filtering.
- **DateKey is int, not string**: `DateKey = 20260101` (int), not `'20260101'`. The string variant lives in the `YYYYMMDD` column.
- **Range cap 2034-12-31**: SP must be re-run before then to extend the runway.
- **`UpdateDate` is the only nullable column**: most other columns are NOT NULL by design — if a join introduces NULLs in date-derived columns, suspect a missing date row.
- **Slash-named columns require backticks in UC**: `` `MM/DD/YYYY` ``, `` `YYYY/MM/DD` ``, `` `YYYY-MM-DD` ``.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| *** | Tier 1 | DDL + writer SP (`SP_PopulateDimDate`) |
| ** | Tier 2 | Live data sample 2026-01-01 / 2026-04-15 / 2026-12-31 |
| * | Tier 3 | Inferred from name/standard calendar-dim semantics [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateKey | int | NO | Primary key. Date encoded as integer YYYYMMDD (e.g. 20260101 for 2026-01-01). The join target for every date-keyed fact in the warehouse. (Tier 1 — DDL + SP_PopulateDimDate) |
| 2 | FullDate | date | NO | Native SQL date (e.g. 2026-01-01). 1:1 with DateKey. Use this when a date-typed comparison is needed; use DateKey for integer joins. (Tier 1 — DDL) |
| 3 | MonthNumberOfYear | tinyint | NO | Month number 1-12 (1=January). (Tier 1 — DDL) |
| 4 | MonthNumberOfQuarter | tinyint | NO | Position of the month inside its quarter: 1, 2, or 3. (Tier 3 — name-inferred) |
| 5 | ISOYearAndWeekNumber | char(7) | NO | ISO-8601 year+week label, format `YYYYWnn` (e.g. `2026W16` for week 16 of 2026). ISO weeks start Monday and the year boundary follows ISO rules. (Tier 2 — live sample) |
| 6 | ISOWeekNumberOfYear | tinyint | NO | ISO-8601 week number of year (1-53). Week starts Monday. (Tier 1 — DDL) |
| 7 | SSWeekNumberOfYear | tinyint | NO | Sunday-Start week number of year (1-53). Week starts Sunday — US retail convention. (Tier 1 — DDL) |
| 8 | ISOWeekNumberOfQuarter_454_Pattern | tinyint | NO | Position of the ISO week inside its quarter under the 4-4-5 retail calendar (13-week quarter split as 4+4+5 weeks). 1-13. (Tier 3 — name-inferred from retail-cal pattern) |
| 9 | SSWeekNumberOfQuarter_454_Pattern | tinyint | NO | Position of the Sunday-Start week inside its quarter under the 4-4-5 retail calendar. 1-13. (Tier 3 — name-inferred) |
| 10 | SSWeekNumberOfMonth | tinyint | NO | Sunday-Start week number within the month (typically 1-6). (Tier 3 — name-inferred) |
| 11 | DayNumberOfYear | smallint | NO | Day-of-year 1-366. Jan 1 = 1, Dec 31 = 365 (or 366 in leap year). (Tier 1 — DDL) |
| 12 | DaysSince1900 | int | NO | Numeric days elapsed since 1900-01-01 — useful for delta/age calculations and for compatibility with legacy serial-date systems. (Tier 1 — DDL) |
| 13 | DayNumberOfFiscalYear | smallint | NO | Day-of-year within the fiscal year (1-366). Currently equal to DayNumberOfYear because @FiscalYearMonthsOffset=0. (Tier 1 — SP) |
| 14 | DayNumberOfQuarter | smallint | NO | Day-of-quarter 1-92. (Tier 3 — name-inferred) |
| 15 | DayNumberOfMonth | tinyint | NO | Day-of-month 1-31. (Tier 1 — DDL) |
| 16 | DayNumberOfWeek_Sun_Start | tinyint | NO | Day-of-week with Sunday=1, Saturday=7 (US convention; SET DATEFIRST 7 in SP). (Tier 1 — SP) |
| 17 | MonthName | varchar(10) | NO | Full English month name (`'January'`, `'February'`, ..., `'December'`). (Tier 2 — live sample) |
| 18 | MonthNameAbbreviation | char(3) | NO | 3-letter month abbreviation (`'Jan'`, `'Feb'`, ..., `'Dec'`). (Tier 1 — DDL) |
| 19 | DayName | varchar(10) | NO | Full English weekday name (`'Sunday'`, `'Monday'`, ..., `'Saturday'`). (Tier 1 — DDL) |
| 20 | DayNameAbbreviation | char(3) | NO | 3-letter weekday abbreviation (`'Sun'`, `'Mon'`, ..., `'Sat'`). (Tier 1 — DDL) |
| 21 | CalendarYear | smallint | NO | Calendar year (e.g. 2026). (Tier 1 — DDL) |
| 22 | CalendarYearMonth | char(7) | NO | Calendar year-month label, format `YYYY-MM` (e.g. `'2026-04'`). Most common GROUP BY key for monthly rollups. (Tier 2 — live sample) |
| 23 | CalendarYearQtr | char(7) | NO | Calendar year-quarter label, format `YYYY-Qn` (e.g. `'2026-Q2'`). (Tier 3 — name-inferred) |
| 24 | CalendarSemester | tinyint | NO | Semester (half-year) of the calendar year: 1 (Jan-Jun) or 2 (Jul-Dec). (Tier 3 — name-inferred) |
| 25 | CalendarQuarter | tinyint | NO | Calendar quarter 1-4. (Tier 1 — DDL) |
| 26 | FiscalYear | smallint | NO | Fiscal year. With current `@FiscalYearMonthsOffset=0`, equals CalendarYear. (Tier 1 — SP) |
| 27 | FiscalMonth | tinyint | NO | Fiscal month 1-12 (= CalendarMonth at offset=0). (Tier 1 — SP) |
| 28 | FiscalQuarter | tinyint | NO | Fiscal quarter 1-4 (= CalendarQuarter at offset=0). (Tier 2 — live sample) |
| 29 | FiscalYearMonth | char(7) | NO | Fiscal year-month label `YYYY-MM`. (Tier 3 — name-inferred) |
| 30 | FiscalYearQtr | char(8) | NO | Fiscal year-quarter label `YYYY-Qn`. (Tier 3 — name-inferred) |
| 31 | QuarterNumber | int | NO | Absolute quarter sequence since some epoch (e.g. continuous count across years). Use for quarter-over-quarter ordering when years are mixed. (Tier 3 — inferred [UNVERIFIED]) |
| 32 | YYYYMMDD | char(8) | NO | String form of DateKey, format `'YYYYMMDD'` (e.g. `'20260101'`). (Tier 2 — live sample) |
| 33 | MM/DD/YYYY | char(10) | NO | Date string in US display format `MM/DD/YYYY` (e.g. `'01/01/2026'`). Backtick the column name in UC. (Tier 1 — DDL) |
| 34 | YYYY/MM/DD | char(10) | NO | Date string in slash-separated ISO order `YYYY/MM/DD`. Backtick required. (Tier 1 — DDL) |
| 35 | YYYY-MM-DD | char(10) | NO | Date string in ISO-8601 dashed order `YYYY-MM-DD`. Same content as FullDate as text. Backtick required. (Tier 1 — DDL) |
| 36 | MonDDYYYY | char(11) | NO | Long-form display `MonDDYYYY` (e.g. `'Jan012026'` or `'Jan 01 2026'`). (Tier 3 — name-inferred) |
| 37 | IsLastDayOfMonth | char(1) | NO | `'Y'` if FullDate is the last day of its calendar month, else `'N'`. (Tier 2 — live sample) |
| 38 | IsWeekday | char(1) | NO | `'Y'` if day is Mon-Fri (calendar-only, ignores holidays), else `'N'`. (Tier 2 — live sample) |
| 39 | IsWeekend | char(1) | NO | `'Y'` if day is Sat-Sun, else `'N'`. (Tier 1 — DDL) |
| 40 | IsWorkday | char(1) | NO | `'Y'` if day is Mon-Fri AND NOT a US federal/bank holiday — i.e. business day under US calendar. Use this (not IsWeekday) for trading-day / business-day filters. (Tier 1 — SP_PopulateDimDate) |
| 41 | IsFederalHoliday | char(1) | NO | `'Y'` if day is a US Federal holiday (New Year's, MLK, Presidents, Memorial, Independence, Labor, Columbus, Veterans, Thanksgiving, Christmas) per the hard-coded calendar in SP_PopulateDimDate. US-only — do not use for EU/APAC business-day logic. (Tier 1 — SP) |
| 42 | IsBankHoliday | char(1) | NO | `'Y'` if day is a US bank holiday (Federal holidays + day-after-Thanksgiving). (Tier 1 — SP) |
| 43 | IsCompanyHoliday | char(1) | NO | `'Y'` if day is a US corporate holiday (Bank holidays + Christmas Eve). (Tier 1 — SP) |
| 44 | PartitionID | int | NO | Internal partition identifier. Often = DateKey or a coarser bucket; used by the legacy partition strategy in some downstream rollups. (Tier 3 — inferred [UNVERIFIED]) |
| 45 | UpdateDate | datetime | YES | ETL load timestamp. NULL on rows pre-existing the introduction of this column; populated with `GETDATE()` by SP_PopulateDimDate runs from 2018+. (Tier 1 — DDL) |
| 46 | IsFirstDayOfMonth | char(1) | YES | `'Y'` if FullDate is the 1st of its calendar month, else `'N'`. Added 2020-11-16 (Boris Slutski) — older rows may have NULL until the SP is re-run. (Tier 1 — SP change history) |

---

## 5. Lineage

### 5.1 Production Sources

`Dim_Date` is computed in-warehouse — no upstream production system. Generated by `SP_PopulateDimDate` from a hard-coded US holiday calendar and standard date arithmetic.

### 5.2 ETL Pipeline

```
SP_PopulateDimDate(@starting_dt, @ending_dt) → DELETE WHERE CalendarYear = @Yr → INSERT computed rows → DWH_dbo.Dim_Date
                                              ↓ Generic Pipeline (gold export)
                            main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date
```

| Step | Object | Description |
|------|--------|-------------|
| Generator | `DWH_dbo.SP_PopulateDimDate` | Year-by-year DELETE-and-reinsert. Computes all 46 columns from FullDate using SET DATEFIRST 7 (Sunday-start) and the hard-coded US holiday list. Author: Boris Slutski (2018-02-08). Last documented change: 2020-11-16 — added IsFirstDayOfMonth. |
| Source-of-truth | `DWH_dbo.Dim_Date` | 10,227-row Synapse calendar dimension |
| Gold export | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | Generic-pipeline mirror in Unity Catalog |

### 5.3 Refresh

Effectively static. Re-run `SP_PopulateDimDate '20070101','20341231'` (or extend the end year) when the runway needs to grow past 2034.

---

## 6. Relationships

### 6.1 References To

`Dim_Date` has no foreign keys — it's a leaf dimension.

### 6.2 Referenced By

100+ downstream tables/views in DWH_dbo, BI_DB_dbo, and Dealing_dbo join to `Dim_Date.DateKey` for date roll-ups. There is no central FK; each consumer joins on its own integer date column (e.g. `DateID`, `SnapshotDateID`, `OpenDateID`, `CloseDateID`).

---

## 7. Sample Queries

### 7.1 Workdays in a quarter

```sql
SELECT COUNT(*) AS workdays
FROM DWH_dbo.Dim_Date
WHERE FiscalYear = 2026 AND FiscalQuarter = 2
  AND IsWorkday = 'Y'
```

### 7.2 Month-end snapshot dates for the year

```sql
SELECT DateKey, FullDate, CalendarYearMonth
FROM DWH_dbo.Dim_Date
WHERE CalendarYear = 2026 AND IsLastDayOfMonth = 'Y'
ORDER BY DateKey
```

### 7.3 Join pattern (UC, with backticks for slash columns)

```sql
SELECT f.CID, d.CalendarYearMonth, d.`YYYY-MM-DD` AS report_date, SUM(f.Amount)
FROM   main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_xyz f
JOIN   main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date d ON f.DateID = d.DateKey
WHERE  d.IsWorkday = 'Y'
GROUP  BY f.CID, d.CalendarYearMonth, d.`YYYY-MM-DD`
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources surfaced for this object.

---

*Generated: 2026-05-07 | Pilot for systematic NO_WIKI fill-in (Wave 2)*
*Source: SP_PopulateDimDate (Boris Slutski, 2018-02-08) + DDL + UC sample 2026-01-01 / 2026-04-15 / 2026-12-31*
*Object: DWH_dbo.Dim_Date | Type: Table | Production Source: in-warehouse (computed)*
