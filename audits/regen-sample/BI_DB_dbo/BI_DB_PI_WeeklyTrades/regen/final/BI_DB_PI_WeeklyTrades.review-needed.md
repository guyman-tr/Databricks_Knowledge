# Review Needed: BI_DB_dbo.BI_DB_PI_WeeklyTrades

## 1. Data Freshness

- **Table appears dormant**: Last UpdateDate is 2024-04-15. The parent SP `SP_PI_Dashboard_COPYDATA_RuningSideBySide` has not run since this date. Confirm whether this is intentional or a pipeline failure.

## 2. Row Count Estimates

- DMV row count query failed (permission denied). Distinct CID count (4,419) and distinct week count (225) are confirmed via live aggregation queries. Total row count is estimated at ~724K rows (3,220 rows/week × 225 weeks). A reviewer with DMV access should confirm the exact total.

## 3. NewTrades Source Column

- `NewTrades` is mapped to `NewTrades_Total` from `BI_DB_CID_WeeklyPanel_FullData` (renamed: NewTrades_Total → NewTrades). The WeeklyPanel wiki documents `NewTrades_Total` as "Total positions opened across all instrument types during the week. SUM." A reviewer should confirm the exact composition of NewTrades_Total in the DailyPanel aggregation if granular instrument-type breakdown is needed.

## 4. Population Filter Completeness

- The PI population filter matches the pattern used by sibling tables (BI_DB_PI_Positions, BI_DB_PI_GainDaily). No discrepancies found.

---

*Generated: 2026-04-29 | Reviewer: Data Platform team*
