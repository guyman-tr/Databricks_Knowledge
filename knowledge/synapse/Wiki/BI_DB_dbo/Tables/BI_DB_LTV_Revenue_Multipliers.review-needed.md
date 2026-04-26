# Review Needed: BI_DB_dbo.BI_DB_LTV_Revenue_Multipliers

## Items Requiring Human Review

### 1. NULL Ratio Coverage in Current Snapshot
**What**: Cohort buckets with no qualifying customers produce NULL ratios. The wiki notes this but does not quantify coverage gaps.
**Why**: Sparse (Seniority, MonthsSinceLastActive) combinations (especially at high Seniority × high MSLA) may produce NULL cells, meaning LTV_Predictions defaults to 0 for customers falling in those cells.
**Action**: Run the sample query in Section 7.3 to identify the count of NULL ratio cells in the current snapshot and whether they represent a significant customer population.

### 2. OpsDB Frequency Discrepancy
**What**: OpsDB records FrequencySP = 'Monthly' but ProcessName = 'SB_Daily'. The wiki explains this as the WHILE loop gating execution to EOMONTH dates only.
**Why**: The discrepancy could cause confusion for operations teams monitoring this object.
**Action**: Confirm with the DWH Ops team whether the SP is scheduled in SB_Daily but internally gates to monthly, or if the OpsDB FrequencySP='Monthly' is the authoritative refresh cadence.

## Auto-Passed Items

| Check | Result |
|-------|--------|
| All 10 columns documented | PASS |
| No T1 columns (all SP-computed) — correct | PASS |
| UpdateDate uses Propagation tier | PASS |
| Monthly EOMONTH gate logic documented | PASS |
| Three-cohort construction explained (1Y/3Y/8Y) | PASS |
| Extrapolation chain for Seniority 13-36 RatioTo8Y documented | PASS |
| Accumulating snapshot semantics documented | PASS |
| MAX(Date) consumer pattern noted in Gotchas | PASS |
| Relationship to BI_DB_LTV_Predictions documented | PASS |
