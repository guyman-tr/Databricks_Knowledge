# Review Needed: BI_DB_dbo.BI_DB_CMR_Phase2_ClientBalance

**Batch**: 58 | **Object**: #2 | **Date**: 2026-04-23
**Confidence**: High (SP code read in full; live data sampled)

---

## Items Requiring Business Validation

### 1. Metric Typos in Stored Data (Confirm Intentional)
The SP hardcodes `Opening Balace` (ExcelOrder 1) and `Closing Balace` (ExcelOrder 32) -- both missing the second n in Balance. These typos are stored in the Metric column in production. Any downstream tool querying by exact Metric string must use the misspelled values. Confirm whether this is known/intentional and whether any consumers depend on it.

### 2. Club Aggregation (Confirm Intended Design)
The SP groups by Club in the intermediate temp table (#cb inner branches) but the outer GROUP BY drops Club entirely. The CMR table stores balance totals across all club tiers combined. Confirm this is by design -- if Club-level breakdown is needed, CBCAN must be queried directly.

### 3. ExcelOrder 33 (Cycle Calculation) Formula Completeness
The Cycle Calculation sums 26 CBCAN columns. If CBCAN adds new balance component columns in the future, the Cycle Calculation would not automatically include them. Business owner should confirm the formula is complete and up-to-date with current CBCAN structure.

### 4. Gap = 0 on Sample Date (2026-04-12)
On the sampled date, Gap (ExcelOrder 34) sums to 0 across all dimension groups, confirming a clean reconciliation. Confirm whether there are dates with non-zero gaps and what the exception handling process is.

### 5. PlayerStatus Scope
All 9 PlayerStatuses are included without filtering. Confirm whether any downstream reports filter on specific PlayerStatuses or whether the table is always consumed with all statuses summed.

---

## Tier Coverage Summary

| Tier | Count | Source |
|------|-------|--------|
| Tier 2 | 10 | All columns from BI_DB_Client_Balance_Aggregate_Level_New (CBCAN) |
| Propagation | 1 | UpdateDate (GETDATE() on insert) |

No Tier 1 assignments -- this is an aggregate-level table with no direct passthrough from upstream production sources. No CID column.
