# Review Needed: Dealing_dbo.Dealing_Apex_PnL

## Summary

| Metric | Value |
|--------|-------|
| Tier 1 columns | 2 |
| Tier 2 columns | 19 |
| Tier 3 columns | 0 |
| Tier 4 columns | 0 |
| Total columns | 21 |

## Items for Human Review

### 1. Low Tier 1 Coverage (Expected)

Only 2 of 21 columns (InstrumentID, InstrumentDisplayName) have Tier 1 coverage. This is expected because the table's primary data sources are Apex Clearing Corporation staging files (LP_APEX_EXT982_3EU, LP_APEX_EXT872_3EU_217314, LP_APEX_EXT869_3EU) which have no upstream wikis. The only columns with a documented upstream are InstrumentID and InstrumentDisplayName via the DWH_dbo.Dim_Instrument wiki (which itself inherits from Trade.Instrument / Trade.InstrumentMetaData).

### 2. Hardcoded Account-to-HedgeServer Mapping

The SP contains a hardcoded mapping of 5 Apex accounts to HedgeServerIDs (3EU05026=9, 3EU05025=112, 3EU05027=102, 3EU00101=223, 3EU05028=3). If new accounts are added to Apex, this mapping must be manually updated in the SP. Reviewer should confirm whether this mapping is still current and complete.

### 3. Data Freshness

The data ranges from 2021-02-10 to 2024-06-07. The last load date is over a year old. Reviewer should confirm whether this table is still actively maintained or if the Apex clearing relationship/SP execution has been discontinued.

### 4. Zero Column Semantics

The `Zero` column from `Dealing_DailyZeroPnL_Stocks` is present in the output but is NOT included in the PnL/PnL_DBPrice formula. It is present as a separate reference for reconciliation comparison. Reviewer should confirm whether this is intentional (informational reference for comparison) or if it should be factored into the reconciliation formula.

### 5. No UC Migration Target

This table is not in the Generic Pipeline mapping and has no Unity Catalog target. Reviewer should confirm whether this is expected for Dealing_dbo Middle Office tables or if migration is planned.

### 6. Easter 2022 Manual Fix

The SP contains a hardcoded fix: `WHEN @FridayBefore = '2022-04-15' THEN 20220414` with comment "manual fix, in our DB this day (easter) is wrongly considered as a workday." This fix is permanent but only affects historical data for that specific date. Consider whether the underlying Dim_Date bank holiday data has been corrected.

### 7. Jira Search Skipped

Phase 10 (Atlassian search) was skipped in regen harness mode. A production run should search for related Jira tickets or Confluence pages about Apex clearing reconciliation.

### 8. NULL InstrumentID Rows

135,419 rows (4.5%) have NULL InstrumentID where Apex symbol could not be matched to Dim_Instrument. Reviewer should assess whether these are delisted instruments, OTC securities, or matching failures that need SP correction.
