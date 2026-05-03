# Review Needed: eMoney_Tribe.CardsSnapshots_BankAccount-341626

## Summary

All 19 columns are Tier 3 — no upstream wiki exists for this raw Tribe ingestion table. The `_no_upstream_found.txt` marker confirms this object is dormant or has no resolvable upstream wiki.

## Items for Human Review

### 1. Production Source Confirmation

- **Issue**: The table is ingested from the Tribe Cards API via Generic Pipeline. The exact Tribe API endpoint and data contract are not documented in any accessible wiki or repo.
- **Action**: Confirm with the eMoney & Wallet Data Analytics Team (Ofir Ovadia, Eitan Lipovetsky) whether Tribe API documentation exists that could elevate columns to Tier 1.

### 2. Payment Capability Flags — Data Change

- **Issue**: `BankAccountDirectDebitsIn`, `BankAccountDirectDebitsOut`, `BankAccountInstantPaymentsIn`, `BankAccountInstantPaymentsOut` were "Yes" in 2023-12 data but are empty strings in 2024+ data.
- **Action**: Confirm whether this is an intentional Tribe API schema change or a pipeline bug. If intentional, document the deprecation date.

### 3. ETR Columns Inconsistency

- **Issue**: `etr_y`, `etr_ym`, `etr_ymd` are populated for 2023-12 records but empty for later data.
- **Action**: Confirm whether the Generic Pipeline stopped populating these fields and whether they can be deprecated.

### 4. PII Classification

- **Issue**: `BankAccountNumber`, `BankAccountSortCode`, `BankAccountIban`, `BankAccountBic` contain sensitive banking identifiers.
- **Action**: Verify PII tagging and access controls are in place. These fields should be masked or restricted in downstream reporting.

### 5. BankAccountBankStateBranch and BankAccountBankBranchCode — Always Empty

- **Issue**: Both columns are empty in all sampled data across the full date range.
- **Action**: Confirm whether these columns were ever populated or if they are vestigial schema elements from the Tribe API.

### 6. UC Migration Status

- **Issue**: Table is marked as `_Not_Migrated` to Unity Catalog.
- **Action**: Determine if this raw Tribe table needs UC migration or if only the downstream `ETL_CardSnapshot` is targeted.

## Tier Distribution

| Tier | Count | Percentage |
|------|-------|------------|
| Tier 1 | 0 | 0% |
| Tier 2 | 0 | 0% |
| Tier 3 | 19 | 100% |
| Tier 4 | 0 | 0% |
