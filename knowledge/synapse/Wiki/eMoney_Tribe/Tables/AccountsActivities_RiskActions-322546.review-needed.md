# Review Needed: eMoney_Tribe.AccountsActivities_RiskActions-322546

## Summary

All 15 columns are Tier 3 — grounded in DDL, SP code (`SP_eMoney_Reconciliation_ETLs`), and live data sampling, but no upstream production wiki exists for the eMoney (Modulr) platform source.

## Items for Human Review

### 1. Production Source Confirmation

- **Issue**: The eMoney (Modulr) platform is identified as the source based on the `eMoney_Tribe` schema naming convention and the SP header comment. No formal documentation or wiki exists for this external platform's data model.
- **Action**: Confirm with the eMoney & Wallet Data Analytics Team (Ofir Ovadia / Eitan Lipovetsky) that the risk action flags originate from Modulr's risk engine API.

### 2. ChangeAccountStatusToReceiveOnly / ChangeAccountStatusToSpendOnly — Schema Addition

- **Issue**: These two columns were added after the initial table deployment. They are NOT consumed by `SP_eMoney_Reconciliation_ETLs` (the SP only selects the original 5 risk flag columns). They are empty strings in older rows and `'0'` in newer rows.
- **Action**: Confirm whether these columns should be added to the SP's SELECT list for reconciliation. If intentionally excluded, document why.

### 3. Duplicate Index on [@Id]

- **Issue**: Two NCIs exist on `[@Id]`: `ClusteredIndex_AA_322546_Id` and `idx_322546_Id`. Both serve the same purpose.
- **Action**: Consider dropping one of the duplicate indexes to reduce storage and maintenance overhead.

### 4. Boolean Columns Stored as varchar(max)

- **Issue**: All 7 risk action flag columns are boolean in nature (values `0` or `1`) but stored as `varchar(max)`. This is consistent with the raw eMoney Tribe ingestion pattern (XML/JSON source → all-varchar schema) but is suboptimal for storage and query performance.
- **Action**: No immediate action needed — this is a known pattern for eMoney Tribe raw tables. If migrated to UC, consider casting to boolean or tinyint.

### 5. etr_* Columns Partially Populated

- **Issue**: The `etr_y`, `etr_ym`, `etr_ymd` extraction partition keys are NULL/empty for a subset of records (observed in 2024+ data). The `partition_date` column is always populated.
- **Action**: Investigate whether the missing `etr_*` values indicate a change in the data lake extraction pipeline configuration.
