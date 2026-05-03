# Review Needed: eMoney_Tribe.SettlementsTransactions_SecurityChecks-426253

## Summary

All 19 columns are Tier 3 — no upstream wiki was resolvable for this table. The `_no_upstream_found.txt` marker confirms this. Descriptions are grounded in DDL structure, SP code analysis (SP_eMoney_Reconciliation_ETLs), and live data sampling.

## Items for Review

### 1. No Upstream Wiki Available

- **Issue**: No production-side wiki exists for `FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253`. All column descriptions are derived from column names, DDL types, SP usage patterns, and sampled data.
- **Impact**: 0 Tier 1 columns. If a Tribe/FiatDwhDB wiki is created in the future, all CVM flag columns should be upgraded to Tier 1.
- **Action**: Confirm with eMoney & Wallet Data Analytics Team (Ofir Ovadia / Eitan Lipovetsky) whether formal field definitions exist in Tribe platform documentation.

### 2. Boolean Flags Stored as VARCHAR(MAX)

- **Issue**: All 10 security check boolean columns (CardExpirationDatePresent, OnlinePIN, OfflinePIN, ThreeDomainSecure, Cvv2, MagneticStripe, ChipData, AVS, PhoneNumber, Signature) are stored as `varchar(max)` with values "0"/"1".
- **Impact**: Storage inefficiency and potential query confusion (string vs. numeric comparison). This is inherited from the Tribe XML export format and cannot be changed in the raw landing table.
- **Action**: No action needed for raw table; downstream ETL (ETL_SettlementsTransactions) inherits the same types.

### 3. AccountNames Column Appears Unused

- **Issue**: In all sampled rows, `AccountNames` is empty. This column is not consumed by SP_eMoney_Reconciliation_ETLs.
- **Impact**: May be a deprecated or optional field from the Tribe platform.
- **Action**: Confirm with eMoney team whether this column is populated for specific card programs or transaction types.

### 4. Duplicate Index on @Id

- **Issue**: Two NCIs exist on `@Id`: `ClusteredIndex_ST_426253` and `idx_426253_Id`. These are functionally identical.
- **Impact**: Minor storage overhead. No functional impact.
- **Action**: Consider dropping one of the duplicate indexes.

### 5. OfflinePIN and Signature Not Consumed by SP

- **Issue**: `SP_eMoney_Reconciliation_ETLs` selects CardExpirationDatePresent, OnlinePIN, ThreeDomainSecure, Cvv2, MagneticStripe, ChipData, AVS, PhoneNumber, and Signature into ETL_SettlementsTransactions, but does NOT select `OfflinePIN`. Verify whether this omission is intentional.
- **Action**: Check with eMoney team whether OfflinePIN should be included in the reconciliation ETL.
