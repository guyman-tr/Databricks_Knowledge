# Review Needed: BI_DB_dbo.BI_DB_PI_WeeklyTrades

## 1. Data Freshness

- **Table appears dormant**: Last UpdateDate is 2024-04-15. The parent SP `SP_PI_Dashboard_COPYDATA_RuningSideBySide` has not run since this date. Confirm whether this is intentional or a pipeline failure.

## 2. NewTrades Source Column

- `NewTrades` is mapped to `NewTrades_Total` from `BI_DB_CID_WeeklyPanel_FullData`. The WeeklyPanel wiki documents `NewTrades_Total` as a SUM of daily `NewTrades` across the week. Verify that `NewTrades_Total` includes all trade types (manual + copy, excludes AirDrop) — the WeeklyPanel wiki does not have a dedicated `NewTrades_Total` column entry (it is constructed from daily panel aggregation). A reviewer should confirm the exact composition.

## 3. Row Count

- DMV row count query failed (permission denied). Estimated total rows based on ~3,220 rows/week x 225 weeks = ~724K rows. A reviewer with DMV access should confirm.

## 4. Population Filter Completeness

- The PI population filter matches the pattern used by sibling tables (BI_DB_PI_Positions, BI_DB_PI_GainDaily). No discrepancies found.

---

*Generated: 2026-04-29 | Reviewer: Data Platform team*
