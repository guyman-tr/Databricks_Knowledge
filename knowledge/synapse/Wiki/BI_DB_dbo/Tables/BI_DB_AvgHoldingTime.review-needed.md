# BI_DB_AvgHoldingTime — Review Notes

**Object**: BI_DB_dbo.BI_DB_AvgHoldingTime
**Batch**: 15 | **Date**: 2026-04-21 | **Reviewer Needed**: Trading Analytics / Product team

## Tier 4 Items / Reviewer Questions

1. **Equity filter asymmetry (open vs. closed)**: Open positions require equity > $50 (Liabilities + ActualNWA from V_Liabilities), but closed positions have no equity filter. This means the average holding time can shift based on the proportion of open vs. closed positions in the 3-month window — customers with near-zero equity are excluded from open-position calculations but included in closed-position calculations. Reviewer: is this intentional? Is V_Liabilities equity state at @EndDate the right snapshot point for open positions?

2. **Day-2-only execution via daily scheduler**: SP is called daily by SB_Daily but contains a hard gate `IF DATEPART(DAY,@date)=2` that makes it a no-op on all other days. The SP comment says "due to data delays from the source." Reviewer: what is the specific source delay that requires day-2 rather than day-1? Is there a risk that day-2 data is still incomplete for fast-updating sources?

3. **"ETF,Indices" contains a literal comma**: The Groups value "ETF,Indices" contains a comma character. Any downstream system that tokenizes on comma delimiters (CSV exports, comma-split logic) will split this into two values. Reviewer: is this documented for downstream BI consumers? Is there a data contract specifying that consumers must not split on comma?

4. **AvgHoldingTime is integer days (floor, not round)**: The SP computes `AVG(DATEDIFF(minutes,...) / 60 / 24)` where the inner division truncates to integer before averaging. A position held 23.9 hours counts as 0 days. Reviewer: is truncation-before-average the intended calculation? Rounding after averaging would give a materially different result for groups with many short-duration positions. Does the ASIC or internal reporting methodology specify floor vs. round?

5. **3-month trailing window includes positions still open >3 months**: The lookback window captures positions opened in the prior 3 months OR still open at @EndDate (regardless of open date). This means a Crypto position opened 2 years ago but still open today is included, counted from its OpenOccurred to @EndDate. Reviewer: confirm this is the intended "average holding time" definition — particularly whether very long-running positions (>1 year) skew the average for Crypto (current value: 855 days).

6. **No downstream consumers identified**: No SP or view in the SSDT repo references this table. Confirm it is consumed exclusively by BI dashboards (Power BI / Tableau) via direct Synapse queries. If it is also exported to any regulatory report, this should be documented.

## No Issues

- All 5 columns documented with Tier 2 suffixes (no upstream wiki inheritance — all computed/aggregated)
- Row count (300), date range (Apr 2021–Mar 2026), 5 Groups confirmed from live data
- Day-2-only execution gate and 3-month trailing window clearly documented in §2.1
- CloseDateID = last day of previous month gotcha documented in §3.4
- ETF,Indices comma-in-name gotcha documented
