# Review Needed: eMoney_Tribe.CardsSnapshots_Accounts-350640

## Summary

All 8 columns are Tier 3 (no upstream wiki available, `_no_upstream_found.txt` present). Descriptions are grounded in DDL structure, SP JOIN usage in `SP_eMoney_Reconciliation_ETLs`, Generic Pipeline mapping, and live data sampling.

## Items for Review

### 1. No Upstream Wiki Available

- **Issue**: No production-side wiki exists for `FiatDwhDB.Tribe.CardsSnapshots_Accounts-350640`. All column descriptions are Tier 3, inferred from DDL, SP code, and data sampling.
- **Action**: If the eMoney/Tribe team has internal documentation for the card snapshot data model, column descriptions could be upgraded to Tier 1.

### 2. @CardsSnapshots_CardSnapshot@Id-140457 — 1:1 Relationship Assumption

- **Issue**: In sampled data, `@CardsSnapshots_CardSnapshot@Id-140457` always equals `@Id`. This suggests a 1:1 mapping, but the Tribe data model may allow many-to-one relationships (multiple account records per card snapshot).
- **Action**: Confirm with the eMoney data team whether this is always a 1:1 relationship or if the table can hold multiple account linkages per card snapshot.

### 3. Empty ETL Partition Fields

- **Issue**: Some rows (observed in 2024-06 and 2024-08 data) have empty strings in `etr_y`, `etr_ym`, `etr_ymd` while `partition_date` and `Created` are populated. This may indicate a Generic Pipeline configuration change or records with missing WorkDate metadata.
- **Action**: Verify whether empty partition strings are expected or indicate an ingestion issue.

### 4. Table Purpose — Pure Bridge vs. Historical

- **Issue**: This table contains 86.2M rows but carries no business payload columns. It may be accumulating historical bridge records that are no longer needed after the card snapshot reconciliation ETL runs.
- **Action**: Confirm with the eMoney team whether historical bridge records serve a purpose beyond the daily ETL run, or if a retention policy should be applied.

---

*Generated: 2026-04-30*
