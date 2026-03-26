# BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status — Column Lineage

> Source-to-target column mapping from `SP_DDR_Customer_Periodic_Status`.

## Sources

| Source | Type | Role |
|--------|------|------|
| BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status | Table (BI_DB) | Sole source — daily customer status |

## Column Pattern

The table has **130 columns** following a repeating pattern across four time periods:
- `_ThisWeek` — from Sunday of current week to @date
- `_ThisMonth` — from 1st of current month to @date
- `_ThisQuarter` — from 1st of current quarter to @date
- `_ThisYear` — from 1st of current year to @date

Each period contains 25+ columns from the daily table, aggregated as:
- **Snapshot attrs** (RegulationID, CountryID, etc.): MAX WHERE rn=1 (latest day's value)
- **Activity flags** (ActiveTraded, GlobalDeposited, etc.): MAX across period (ever-happened)
- **Event counts** (FirstTimeFunded, TPFirstDeposited, etc.): SUM across period (count of days)

Plus 8 period boundary columns (WeekStart, MonthStart, etc.) and UpdateDate.
