# DWH_dbo.V_Dim_Date_For_DWHRep

> Simplified date dimension view for DWH replication — exposes the base Dim_Date columns plus PartitionID, UpdateDate, and IsFirstDayOfMonth without any dynamic temporal computations.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Base Table** | DWH_dbo.Dim_Date |
| **Purpose** | DWH replication/import interface (ImportFromSynapse pipeline) |

---

## 1. Business Meaning

`V_Dim_Date_For_DWHRep` is a streamlined version of the date dimension used specifically by the DWH replication pipeline that copies tables from Synapse back to the legacy DWH-01 SQL Server (see Confluence: "Import Tables From Synapse To DWH"). Unlike `V_Dim_Date` which adds ~20 dynamic CASE expressions, this view passes through the raw Dim_Date columns with no computed logic — making it cheaper to replicate and ensuring deterministic results across servers.

The view includes three columns that `V_Dim_Date` excludes:
- **PartitionID** — needed for partition-aligned replication
- **UpdateDate** — tracks when Dim_Date rows were last modified
- **IsFirstDayOfMonth** — a static Dim_Date flag (not dynamically computed)

---

## 2. Elements

| # | Column | Type | Source | Description |
|---|--------|------|--------|-------------|
| 1 | DateKey | int | Dim_Date.DateKey | Date as YYYYMMDD integer. Sourced from the underlying Dim_Date table. |
| 2 | FullDate | date | Dim_Date.FullDate | Calendar date value. (Tier 3 — DDL inference) |
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
| 44 | PartitionID | int | Dim_Date.PartitionID | Partition identifier. Included here but excluded from V_Dim_Date. Used for partition-aligned replication. (Tier 3 — DDL inference) |
| 45 | UpdateDate | datetime | Dim_Date.UpdateDate | Timestamp when the Dim_Date row was last modified. (Tier 3 — DDL inference) |
| 46 | IsFirstDayOfMonth | char(1) | Dim_Date.IsFirstDayOfMonth | 'Y' if date is the first day of its month, NULL otherwise. (Tier 3 — DDL inference) |

---

## 3. Relationships & JOINs

| Related Object | JOIN Condition | Relationship | Direction |
|----------------|----------------|--------------|-----------|
| DWH_dbo.Dim_Date | Base table (1:1) | Source | Inbound |

---

## 4. ETL & Data Pipeline

No ETL — pass-through view. Used as the source for the ImportFromSynapse pipeline that copies date dimension data from Synapse to the legacy DWH-01 server.

---

## 5. Referenced By

| Object | Usage |
|--------|-------|
| ImportFromSynapse pipeline | Copies Dim_Date from Synapse to legacy DWH-01 |

---

## 6. Business Logic & Patterns

This is a pure pass-through view with no computed columns. Its existence is architectural — it provides a stable interface for the replication pipeline, decoupled from the dynamic temporal logic in V_Dim_Date.

---

## 7. Query Advisory

Straightforward SELECT — no performance concerns. The view returns the same number of rows as Dim_Date.

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| [Import Tables From Synapse To DWH](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11895309220) | Documents the replication pipeline that uses this view |
| [DWH Dim_Date, Dim_Range and View V_M2M_Date_DateRange](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/12952666154) | Date dimension family documentation |
| [System Transfer Data From Synapse to DWHRep](https://etoro-jira.atlassian.net/wiki/spaces/DBAC/pages/12604604544) | Daily Synapse → DWHRep transfer design (ETL on azr-we-bi-01 / ETL DB) |
| [DataWareHouseChecker: ValidateDWHreadiness](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/12952633410) | Mentions Dim_Date date-window checks alongside DWH replication task validation |

---

*Generated: 2026-03-28 | Quality: 8.0/10 (★★★★☆) | Phases: 7/14 | Column expansion: 46 cols documented individually*
*Tiers: 0 T1, 0 T2, 46 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 7/10, Relationships: 6/10, Sources: 8/10*
*Object: DWH_dbo.V_Dim_Date_For_DWHRep | Type: View | Base Table: DWH_dbo.Dim_Date (no upstream wiki — all Tier 3 DDL inference)*
