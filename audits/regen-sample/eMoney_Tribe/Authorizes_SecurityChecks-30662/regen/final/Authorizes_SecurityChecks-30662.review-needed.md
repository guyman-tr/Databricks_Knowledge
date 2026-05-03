# Review Needed: eMoney_Tribe.Authorizes_SecurityChecks-30662

## Summary

All 19 columns are Tier 3 — no upstream wiki exists for this Tribe XML-shredded raw table. Descriptions are grounded in DDL structure, SP code (`SP_eMoney_Reconciliation_ETLs`), and live data sampling.

## Items for Review

### 1. AccountNames Column Purpose

- **Column**: `AccountNames`
- **Issue**: Sample data shows values of `0` or empty string. The column name suggests account name(s) but observed data does not contain text names. May be a deprecated or placeholder field from the Tribe XML export.
- **Action**: Confirm with eMoney & Wallet Data Analytics Team (Ofir Ovadia / Eitan Lipovetsky) whether this column carries meaningful data or can be ignored.

### 2. etr_* Column Population Gap

- **Columns**: `etr_y`, `etr_ym`, `etr_ymd`
- **Issue**: Older records (2023-12) have these populated; newer records (2024+) sometimes have empty strings instead. This suggests a Generic Pipeline configuration change.
- **Action**: Confirm whether the etr_* columns are intentionally deprecated or if the population gap is a bug.

### 3. Boolean Columns Stored as varchar(max)

- **Columns**: CardExpirationDatePresent, OnlinePIN, OfflinePIN, ThreeDomainSecure, Cvv2, MagneticStripe, ChipData, AVS, PhoneNumber, Signature
- **Issue**: These are boolean flags (0/1) stored as `varchar(max)`, which is storage-inefficient. This is likely inherited from Tribe XML shredding and cannot be changed without pipeline modification.
- **Action**: No action needed — this is a known pattern for eMoney_Tribe raw tables.

### 4. Redundant Indexes on @Id

- **Issue**: Two NCIs exist on `@Id` (`ClusteredIndex_Authorizes_30662` and `idx_30662_Id`). One is redundant.
- **Action**: Consider dropping one of the duplicate indexes to reduce storage and maintenance overhead.

### 5. No Upstream Wiki Available

- **Issue**: No production-side wiki exists for `FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662`. All column descriptions are Tier 3 (grounded in DDL + SP code + data sampling). If a Tribe data dictionary becomes available, descriptions should be promoted to Tier 1.
- **Action**: Check with the Tribe/GPS integration team if API documentation or data dictionaries exist for the Authorizes SecurityChecks entity.
