-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Date
-- Generated: 2026-05-07 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date SET TBLPROPERTIES (
    'comment' = 'DWH_dbo.Dim_Date > 10,227-row calendar dimension covering 2007-01-01 -> 2034-12-31 (one row per day, no duplicates). Pre-computed grain for every date-keyed table in the DWH and BI_DB layers - week/month/quarter/year hierarchies, fiscal calendar, ISO and Sunday-Start week numbering, retail 4-4-5 patterns, US holiday/weekend/workday flags, and string-format date variants. Populated by `SP_PopulateDimDate(@starting_dt, @ending_dt)` (Boris Slutski, 2018-02-08). | Property | Value | |----------|-------| | **Schema** | DWH_dbo | | **Object Type** | Table | | **Production Source** | Computed in-warehouse - no upstream production system | | **Refresh** | On-demand / annual extension (`SP_PopulateDimDate ''20070101'',''20341231''`) - table is essentially static, only re-run when the calendar runway is extended | | **Row Count** | 10,227 (one row per date) | | **Date Range** | 2007-01-01 -> 2034-12-31 '
);

-- ---- Table Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date SET TAGS (
    'source_schema' = 'DWH_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN DateKey COMMENT 'Primary key. Date encoded as integer YYYYMMDD (e.g. 20260101 for 2026-01-01). The join target for every date-keyed fact in the warehouse. (Tier 1 - DDL + SP_PopulateDimDate)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN FullDate COMMENT 'Native SQL date (e.g. 2026-01-01). 1:1 with DateKey. Use this when a date-typed comparison is needed; use DateKey for integer joins. (Tier 1 - DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN MonthNumberOfYear COMMENT 'Month number 1-12 (1=January). (Tier 1 - DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN MonthNumberOfQuarter COMMENT 'Position of the month inside its quarter: 1, 2, or 3. (Tier 3 - name-inferred)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN ISOYearAndWeekNumber COMMENT 'ISO-8601 year+week label, format `YYYYWnn` (e.g. `2026W16` for week 16 of 2026). ISO weeks start Monday and the year boundary follows ISO rules. (Tier 2 - live sample)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN ISOWeekNumberOfYear COMMENT 'ISO-8601 week number of year (1-53). Week starts Monday. (Tier 1 - DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN SSWeekNumberOfYear COMMENT 'Sunday-Start week number of year (1-53). Week starts Sunday - US retail convention. (Tier 1 - DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN ISOWeekNumberOfQuarter_454_Pattern COMMENT 'Position of the ISO week inside its quarter under the 4-4-5 retail calendar (13-week quarter split as 4+4+5 weeks). 1-13. (Tier 3 - name-inferred from retail-cal pattern)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN SSWeekNumberOfQuarter_454_Pattern COMMENT 'Position of the Sunday-Start week inside its quarter under the 4-4-5 retail calendar. 1-13. (Tier 3 - name-inferred)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN SSWeekNumberOfMonth COMMENT 'Sunday-Start week number within the month (typically 1-6). (Tier 3 - name-inferred)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN DayNumberOfYear COMMENT 'Day-of-year 1-366. Jan 1 = 1, Dec 31 = 365 (or 366 in leap year). (Tier 1 - DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN DaysSince1900 COMMENT 'Numeric days elapsed since 1900-01-01 - useful for delta/age calculations and for compatibility with legacy serial-date systems. (Tier 1 - DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN DayNumberOfFiscalYear COMMENT 'Day-of-year within the fiscal year (1-366). Currently equal to DayNumberOfYear because @FiscalYearMonthsOffset=0. (Tier 1 - SP)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN DayNumberOfQuarter COMMENT 'Day-of-quarter 1-92. (Tier 3 - name-inferred)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN DayNumberOfMonth COMMENT 'Day-of-month 1-31. (Tier 1 - DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN DayNumberOfWeek_Sun_Start COMMENT 'Day-of-week with Sunday=1, Saturday=7 (US convention; SET DATEFIRST 7 in SP). (Tier 1 - SP)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN MonthName COMMENT 'Full English month name (`''January''`, `''February''`, ..., `''December''`). (Tier 2 - live sample)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN MonthNameAbbreviation COMMENT '3-letter month abbreviation (`''Jan''`, `''Feb''`, ..., `''Dec''`). (Tier 1 - DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN DayName COMMENT 'Full English weekday name (`''Sunday''`, `''Monday''`, ..., `''Saturday''`). (Tier 1 - DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN DayNameAbbreviation COMMENT '3-letter weekday abbreviation (`''Sun''`, `''Mon''`, ..., `''Sat''`). (Tier 1 - DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN CalendarYear COMMENT 'Calendar year (e.g. 2026). (Tier 1 - DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN CalendarYearMonth COMMENT 'Calendar year-month label, format `YYYY-MM` (e.g. `''2026-04''`). Most common GROUP BY key for monthly rollups. (Tier 2 - live sample)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN CalendarYearQtr COMMENT 'Calendar year-quarter label, format `YYYY-Qn` (e.g. `''2026-Q2''`). (Tier 3 - name-inferred)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN CalendarSemester COMMENT 'Semester (half-year) of the calendar year: 1 (Jan-Jun) or 2 (Jul-Dec). (Tier 3 - name-inferred)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN CalendarQuarter COMMENT 'Calendar quarter 1-4. (Tier 1 - DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN FiscalYear COMMENT 'Fiscal year. With current `@FiscalYearMonthsOffset=0`, equals CalendarYear. (Tier 1 - SP)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN FiscalMonth COMMENT 'Fiscal month 1-12 (= CalendarMonth at offset=0). (Tier 1 - SP)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN FiscalQuarter COMMENT 'Fiscal quarter 1-4 (= CalendarQuarter at offset=0). (Tier 2 - live sample)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN FiscalYearMonth COMMENT 'Fiscal year-month label `YYYY-MM`. (Tier 3 - name-inferred)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN FiscalYearQtr COMMENT 'Fiscal year-quarter label `YYYY-Qn`. (Tier 3 - name-inferred)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN QuarterNumber COMMENT 'Absolute quarter sequence since some epoch (e.g. continuous count across years). Use for quarter-over-quarter ordering when years are mixed. (Tier 3 - inferred [UNVERIFIED])';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN YYYYMMDD COMMENT 'String form of DateKey, format `''YYYYMMDD''` (e.g. `''20260101''`). (Tier 2 - live sample)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN `MM/DD/YYYY` COMMENT 'Date string in US display format `MM/DD/YYYY` (e.g. `''01/01/2026''`). Backtick the column name in UC. (Tier 1 - DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN `YYYY/MM/DD` COMMENT 'Date string in slash-separated ISO order `YYYY/MM/DD`. Backtick required. (Tier 1 - DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN `YYYY-MM-DD` COMMENT 'Date string in ISO-8601 dashed order `YYYY-MM-DD`. Same content as FullDate as text. Backtick required. (Tier 1 - DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN MonDDYYYY COMMENT 'Long-form display `MonDDYYYY` (e.g. `''Jan012026''` or `''Jan 01 2026''`). (Tier 3 - name-inferred)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN IsLastDayOfMonth COMMENT '`''Y''` if FullDate is the last day of its calendar month, else `''N''`. (Tier 2 - live sample)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN IsWeekday COMMENT '`''Y''` if day is Mon-Fri (calendar-only, ignores holidays), else `''N''`. (Tier 2 - live sample)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN IsWeekend COMMENT '`''Y''` if day is Sat-Sun, else `''N''`. (Tier 1 - DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN IsWorkday COMMENT '`''Y''` if day is Mon-Fri AND NOT a US federal/bank holiday - i.e. business day under US calendar. Use this (not IsWeekday) for trading-day / business-day filters. (Tier 1 - SP_PopulateDimDate)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN IsFederalHoliday COMMENT '`''Y''` if day is a US Federal holiday (New Year''s, MLK, Presidents, Memorial, Independence, Labor, Columbus, Veterans, Thanksgiving, Christmas) per the hard-coded calendar in SP_PopulateDimDate. US-only - do not use for EU/APAC business-day logic. (Tier 1 - SP)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN IsBankHoliday COMMENT '`''Y''` if day is a US bank holiday (Federal holidays + day-after-Thanksgiving). (Tier 1 - SP)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN IsCompanyHoliday COMMENT '`''Y''` if day is a US corporate holiday (Bank holidays + Christmas Eve). (Tier 1 - SP)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN PartitionID COMMENT 'Internal partition identifier. Often = DateKey or a coarser bucket; used by the legacy partition strategy in some downstream rollups. (Tier 3 - inferred [UNVERIFIED])';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. NULL on rows pre-existing the introduction of this column; populated with `GETDATE()` by SP_PopulateDimDate runs from 2018+. (Tier 1 - DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN IsFirstDayOfMonth COMMENT '`''Y''` if FullDate is the 1st of its calendar month, else `''N''`. Added 2020-11-16 (Boris Slutski) - older rows may have NULL until the SP is re-run. (Tier 1 - SP change history)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN DateKey SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN FullDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN MonthNumberOfYear SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN MonthNumberOfQuarter SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN ISOYearAndWeekNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN ISOWeekNumberOfYear SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN SSWeekNumberOfYear SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN ISOWeekNumberOfQuarter_454_Pattern SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN SSWeekNumberOfQuarter_454_Pattern SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN SSWeekNumberOfMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN DayNumberOfYear SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN DaysSince1900 SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN DayNumberOfFiscalYear SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN DayNumberOfQuarter SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN DayNumberOfMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN DayNumberOfWeek_Sun_Start SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN MonthName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN MonthNameAbbreviation SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN DayName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN DayNameAbbreviation SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN CalendarYear SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN CalendarYearMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN CalendarYearQtr SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN CalendarSemester SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN CalendarQuarter SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN FiscalYear SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN FiscalMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN FiscalQuarter SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN FiscalYearMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN FiscalYearQtr SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN QuarterNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN YYYYMMDD SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN `MM/DD/YYYY` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN `YYYY/MM/DD` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN `YYYY-MM-DD` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN MonDDYYYY SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN IsLastDayOfMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN IsWeekday SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN IsWeekend SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN IsWorkday SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN IsFederalHoliday SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN IsBankHoliday SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN IsCompanyHoliday SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN PartitionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date ALTER COLUMN IsFirstDayOfMonth SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-07 10:42:53 UTC
-- Batch deploy resume: DWH_dbo deploy batch 11
-- Statements: 94/94 succeeded
-- ====================
