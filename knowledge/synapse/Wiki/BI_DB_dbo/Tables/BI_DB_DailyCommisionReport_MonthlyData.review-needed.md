# Review Needed — BI_DB_DailyCommisionReport_MonthlyData

**Generated**: 2026-04-22 | **Batch**: 22 | **Reviewer**: TBD

## Tier 4 Items (Needs Confirmation)

- None — all columns are Tier 2, derived from BI_DB_DailyCommisionReport with confirmed SP code lineage.

## Open Questions for Reviewer

1. **Business intent of weeknum granularity**: Is the week-level breakdown in MonthlyData actively used by BI consumers, or is it a legacy artifact? The sister tables (ThisMonth, ThisYear) omit weeknum. Clarifying whether analysts query by week within month would help assess if this table is preferred over ThisMonth for in-month reporting.

2. **UpdateDate NOT NULL constraint**: MonthlyData has `UpdateDate NOT NULL` in DDL while sibling satellites (Yesterday, ThisMonth, ThisYear) allow NULL. Is this intentional (the column has never been NULL since the first run)? Is there historical data before a certain date where UpdateDate was NULL?

3. **Backup table**: `BI_DB_DailyCommisionReport_MonthlyData_Backup_20241216` exists in the SSDT repo. This suggests a structural migration occurred around December 2024 that required a backup copy. What changed?

4. **331M vs 321M rows**: The row count (321,587,915 as of 2026-04-13) is among the largest in BI_DB_dbo. Is the table size monitored? The ROUND_ROBIN distribution with CLUSTERED INDEX on RealCID means multi-month full scans will be slow — has any query optimization been applied?

5. **TradingFees and RollOverFee_SDRT**: These columns appear only in MonthlyData. Are they intentionally absent from Yesterday/ThisMonth/ThisYear? If so, why? If not, this is an inconsistency worth flagging to the SP owner (Guy M).

## Auto-Confirmed Items

- All 29 columns documented
- SP logic confirmed (lines 1715–1802 of SP_DailyCommisionReport.sql)
- Live data sampled: Month 201712–202604, weeknum 14–16 for April 2026
- No downstream consumers in SSDT repo (terminal output)
- CommissionInRisk correctly noted as ABSENT from this table's DDL (unlike other satellites)
