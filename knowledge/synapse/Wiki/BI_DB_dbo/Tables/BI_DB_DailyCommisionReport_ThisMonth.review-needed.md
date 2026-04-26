# Review Needed — BI_DB_DailyCommisionReport_ThisMonth

**Generated**: 2026-04-22 | **Batch**: 22 | **Reviewer**: TBD

## Tier 4 Items (Needs Confirmation)

1. **CommissionInRisk (ghost column)**: DDL has `[CommissionInRisk] [money] NULL` but the SP INSERT list at lines 1424–1449 does not include it. Consistent with Yesterday and ThisYear sibling tables. Always NULL from live data (April 2026 MTD: no CommissionInRisk values observed). Tier 4 assigned. Reviewer should confirm this column has never been populated and is safe to ignore in analysis.

## Open Questions for Reviewer

1. **CommissionInRisk intent**: Same ghost column pattern found in Yesterday, ThisMonth, ThisYear DDLs but excluded from all three SP INSERT lists. Was this column added speculatively (as in Last2weeks/LastYear pattern from Batch 21) and never activated? Is there a future plan to populate it, or should it be formally deprecated?

2. **Month-start edge case intent**: When `SP_DailyCommisionReport` runs on day 1 of a new month, `@DateMonth` is set to the first day of the *prior* month, meaning the table holds the entire previous month's data rather than the first day of the new month. Is this by design to avoid an empty table state? Is there a separate process that handles the first day's data for the current month?

3. **Backup table**: `BI_DB_DailyCommisionReport_ThisMonth_Backup_20241114` exists in the SSDT DDL repo. What triggered this snapshot (November 2024)? Is it still referenced anywhere or can it be decommissioned?

4. **ThisMonth vs MonthlyData overlap**: Both tables aggregate by month. ThisMonth holds current-month MTD data via TRUNCATE+INSERT; MonthlyData holds full historical months via DELETE+INSERT. Is there a seam period where the same month is active in both tables simultaneously? Are downstream reports expected to blend these two tables?

5. **InstrumentType distribution**: Stocks was 42% of rows on the April 2026 MTD sample. Is this representative for this table, or does the InstrumentType mix shift significantly toward month-end as more trades settle?

6. **Row count ceiling**: 877,614 rows for ~21 days of April 2026. At ~42K rows/day, a full month would yield ~1.3M rows. Is there a monitored threshold for table size, and does TRUNCATE+INSERT remain performant at peak month-end volume?

## Auto-Confirmed Items

- All 25 DDL columns documented (24 active + 1 ghost CommissionInRisk)
- SP INSERT covers 24 active columns confirmed at lines 1424–1449
- Live data sampled: April 2026 MTD, 877,614 rows, 563,770 CIDs
- CommissionInRisk confirmed NULL in live sample
- Month encoding: `MONTH(FullDate) + YEAR(FullDate)*100` (e.g., April 2026 = 202604)
- Month-start edge case confirmed in SP (lines ~1420-1426): `CASE WHEN DAY(GETDATE())=1 THEN DATEADD(MONTH,-1,DATEADD(DAY,1-DAY(GETDATE()),GETDATE())) ELSE DATEADD(DAY,1-DAY(GETDATE()),GETDATE()) END`
- No Club or Country columns (unlike Yesterday sibling) — confirmed absent from DDL
- No downstream consumers in SSDT repo
- Mifid distribution consistent with Yesterday sibling: Retail dominant
