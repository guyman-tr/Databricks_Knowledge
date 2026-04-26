# Review Needed — BI_DB_DailyCommisionReport_ThisYear

**Generated**: 2026-04-22 | **Batch**: 22 | **Reviewer**: TBD

## Tier 4 Items (Needs Confirmation)

1. **CommissionInRisk (ghost column)**: DDL has `[CommissionInRisk] [money] NULL` but the SP INSERT list at lines 1504–1527 does not include it. Consistent with Yesterday, ThisMonth, Last2weeks, and LastYear siblings. Not present in MonthlyData DDL at all. Live data confirms always NULL. Tier 4 assigned. Reviewer should confirm this column has never been populated and is safe to exclude from all analysis.

## Open Questions for Reviewer

1. **RealCID bigint vs int**: `RealCID` is declared as `bigint` in this table's DDL, while all other DailyCommisionReport satellite tables (Yesterday, ThisMonth, MonthlyData, Last2weeks, LastYear) use `int`. Was this intentional (planned for CID space expansion) or a DDL error that was never corrected? Are there known JOIN failures or implicit conversions caused by this mismatch?

2. **No Club or Country columns**: Unlike Yesterday and ThisMonth, ThisYear drops the `Club` and `Country` GROUP BY dimensions. Was this a deliberate decision to reduce cardinality at yearly grain, or an oversight? If a year-level report needs club/country segmentation, analysts must JOIN to MonthlyData or a dimension table — is this expected?

3. **CommissionInRisk intent (cross-sibling)**: Same ghost column pattern across Yesterday, ThisMonth, ThisYear. Was it added speculatively at DDL creation and never activated? Is there any planned future use, or should these columns be formally deprecated in all three tables?

4. **Jan 1 edge case design**: On January 1, @Dateyear is set to the first day of the prior year, causing the table to hold the entire prior calendar year's data for one run cycle. Are downstream reports aware of this behavior? Is there a special handling or flag for Jan 1 executions to prevent stale prior-year data from being served as current-year data?

5. **8.6M row projection**: At 2.65M rows for ~112 YTD days, a full year projects to ~8.6M rows. Has the TRUNCATE + INSERT performance been benchmarked at year-end scale? Is there a monitored execution duration threshold for SP_DailyCommisionReport?

6. **NOLOCK in SP**: The SELECT against parent `BI_DB_DailyCommisionReport` uses `WITH (NOLOCK)` (line 1552). At ~8.6M row scale, is dirty-read risk acceptable, or should this be revisited?

## Auto-Confirmed Items

- All 23 DDL columns documented (22 active + 1 ghost CommissionInRisk)
- SP INSERT covers 22 active columns confirmed at lines 1504–1527
- Live data sampled: 2026-04-22, 2,649,516 rows, Year=2026, 1,371,482 CIDs
- CommissionInRisk confirmed absent from SP INSERT; always NULL in live data
- Year filter: `DATEDIFF(YEAR, FullDate, DATEADD(DAY,-1,GETDATE()))=0` — calendar year scope confirmed
- @Dateyear edge case confirmed: Jan 1 → prior year (lines 1501–1503)
- No Club, Country columns — confirmed absent from both DDL and SP SELECT/GROUP BY
- RealCID bigint confirmed in DDL (line 3); all siblings use int
- No downstream consumers found in SSDT repo
- ROUND_ROBIN distribution, CLUSTERED INDEX on RealCID ASC confirmed
