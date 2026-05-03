# Review Needed: eMoney_Tribe.AccountsActivities_SecurityChecks-471048

## Summary

- **Tier Distribution**: 2 Tier 1, 0 Tier 2, 17 Tier 3, 0 Tier 4
- **Production Wiki**: FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048 — exists but only documents 4 system columns (@Created, @Id, @AccountsActivities@Id-862157, Created). The 10 security check columns and 5 ETL metadata columns have no upstream documentation.
- **Bundle Note**: The upstream bundle marked `_no_upstream_found.txt`, but a production wiki WAS found at `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.AccountsActivities_SecurityChecks-471048.md`. The bundle resolution missed this path.

## Items for Human Review

### 1. AccountNames Column — Purpose Unclear

The `AccountNames` column (varchar(max)) contains values `"0"` or empty string in all sampled rows. Its name suggests it should contain account name information, but observed data does not support this. Possible explanations:
- Column was added but never populated with meaningful data
- Contains account name data only for specific transaction types not captured in the sample
- **Action**: Verify with eMoney team (Ofir Ovadia / Eitan Lipovetsky) whether this column carries business data

### 2. FK Column Name Mismatch Between Production and Synapse

- **Production**: `@AccountsActivities@Id-862157` (FK to parent 862157 envelope)
- **Synapse**: `@AccountsActivities_AccountActivity@Id-833937` (FK to child 833937 AccountActivity)
- These point to different parent tables, suggesting the XML hierarchy may have been restructured between the production database and Synapse ingestion
- **Action**: Confirm the intended parent relationship in Synapse

### 3. ChipData Excluded from Account Activities Reconciliation

SP_eMoney_Reconciliation_ETLs selects 9 of the 10 security check columns from this table into ETL_AccountsActivities. `ChipData` is the one omitted. It IS selected from the Settlements SecurityChecks table (426253). This may be intentional (different ChipData semantics for settlements vs account activities) or an oversight.
- **Action**: Confirm with eMoney team whether ChipData exclusion is intentional

### 4. Redundant Indexes

Two NCIs both index `[@Id] ASC`:
- `ClusteredIndex_AA_471048_Id`
- `idx_471048_Id`
- **Action**: Consider dropping one to reduce storage and maintenance overhead

### 5. Production Wiki Coverage Gap

The production wiki (FiatDwhDB.Tribe) only documents 4 of the table's columns. The 10 security check boolean columns (CardExpirationDatePresent, OnlinePIN, OfflinePIN, ThreeDomainSecure, Cvv2, MagneticStripe, ChipData, AVS, PhoneNumber, Signature) have no upstream documentation. Descriptions are grounded in DDL + live data + SP context (Tier 3).
- **Action**: Consider enriching the production wiki with security check column documentation

### 6. etr Partition Key Population

The etr_y, etr_ym, etr_ymd columns may have low population rates (as observed on sibling table AccountsActivities_862157 where ~99.8% are NULL). These columns are not used by the downstream SP.
- **Action**: Confirm whether these partition keys are functionally useful or candidates for deprecation
