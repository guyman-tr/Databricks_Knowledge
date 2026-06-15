# Column Lineage: main.bi_output.bi_output_vg_date

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_date` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_vg_date.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_vg_date.json` (rows: 10, mismatches: 4) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Date.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date   ←── primary upstream
        │
        ▼
main.bi_output.bi_output_vg_date   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `DateKey` | `rename` | (Tier 1 — DDL + SP_PopulateDimDate) | DateKey AS DateID |
| 2 | `Date` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `FullDate` | `rename` | (Tier 1 — DDL) | FullDate AS Date |
| 3 | `WeekNumberYear` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `SSWeekNumberOfYear` | `rename` | (Tier 1 — DDL) | SSWeekNumberOfYear AS WeekNumberYear |
| 4 | `CalendarYearMonth` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `CalendarYearMonth` | `passthrough` | (Tier 2 — live sample) | CalendarYearMonth |
| 5 | `CalendarQuarter` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `CalendarQuarter` | `passthrough` | (Tier 1 — DDL) | CalendarQuarter |
| 6 | `CalendarYear` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `CalendarYear` | `passthrough` | (Tier 1 — DDL) | CalendarYear |
| 7 | `IsLastDayWeek` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `—` | `case` | — | CASE WHEN DateKey = MAX(DateKey) OVER (PARTITION BY CalendarYear, SSWeekNumberOfYear ORDER BY DateKey DESC) THEN 1 ELSE 0 END AS IsLastDayWe |
| 8 | `IsLastDayQuarter` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `—` | `case` | — | CASE WHEN DateKey = MAX(DateKey) OVER (PARTITION BY CalendarYear, CalendarQuarter ORDER BY DateKey DESC) THEN 1 ELSE 0 END AS IsLastDayQuart |
| 9 | `IsLastDayMonth` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `—` | `case` | — | CASE WHEN DateKey = MAX(DateKey) OVER (PARTITION BY CalendarYearMonth ORDER BY DateKey DESC) THEN 1 ELSE 0 END AS IsLastDayMonth |
| 10 | `IsLastDayYear` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `—` | `case` | — | CASE WHEN DateKey = MAX(DateKey) OVER (PARTITION BY CalendarYear ORDER BY DateKey DESC) THEN 1 ELSE 0 END AS IsLastDayYear |

## Cross-check vs system.access.column_lineage

- Total target columns: **10**
- OK: **6**, WARN: **0**, ERROR: **4**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `IsLastDayWeek` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date.calendaryear`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date.datekey`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date.ssweeknumberofyear` | ERROR |
| `IsLastDayQuarter` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date.calendarquarter`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date.calendaryear`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date.datekey` | ERROR |
| `IsLastDayMonth` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date.calendaryearmonth`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date.datekey` | ERROR |
| `IsLastDayYear` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date.calendaryear`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date.datekey` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **4**
