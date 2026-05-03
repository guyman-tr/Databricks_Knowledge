# EXW_Wallet.Redemptions — Review Needed

## 1. Missing Upstream Wiki

- **Issue**: No upstream wiki exists for WalletDB.Wallet.Redemptions. All 17 production columns are Tier 3 (grounded in DDL, data sampling, and downstream SP usage but lacking authoritative production documentation).
- **Action**: If a wiki for WalletDB.Wallet.Redemptions is created in the CryptoDBs repo, re-run the pipeline to upgrade columns to Tier 1.

## 2. RedemptionStatus Values — Meaning Unconfirmed

- **Issue**: RedemptionStatus has 3 observed values (2, 3, 4) but no dictionary or enum mapping was found. The downstream SP does not use RedemptionStatus directly — it derives FinalRedeemStatus from RequestStatuses instead.
- **Action**: Confirm the meaning of status codes 2, 3, and 4 with the Wallet team. Status 3 dominates (99.997% of rows).

## 3. SourceWalletId — Appears Unpopulated

- **Issue**: SourceWalletId is NULL in all 10 sampled rows. This may be a deprecated column or conditionally populated.
- **Action**: Verify with the Wallet team whether this column is still in use or can be deprecated.

## 4. partition_date — NULL Despite Index

- **Issue**: partition_date has a nonclustered index (XI_partition_date) but is NULL in all sampled rows. This suggests the column was added for future use or is populated only for specific subsets of data not captured in the sample.
- **Action**: Check if partition_date is populated for newer rows or if the index should be removed.

## 5. TransactionTypeId — Sparse Population

- **Issue**: TransactionTypeId is 0 for 90.3% of rows and NULL for 9.7%. The EXW_TransactionsView filters on TransactionTypeId IN (0, 8) for Redeem type, but no rows with value 8 were observed.
- **Action**: Confirm whether TransactionTypeId = 8 is a valid redeem subtype or legacy value.

## 6. CryptoId Mapping — No Inline Values

- **Issue**: 57 distinct CryptoId values exist but no inline mapping is provided (exceeds the 15-value threshold). The top values (4, 1, 2, 18, 21) should be mapped to crypto names via EXW_Wallet.CryptoTypes for business context.
- **Action**: Consider adding a cross-reference note once CryptoTypes is documented.

## 7. EndDate Sentinel

- **Issue**: All sampled rows show EndDate = 9999-12-31 23:59:59.999999. It is unclear whether any rows ever get a real EndDate or if this field is always the sentinel.
- **Action**: Query for rows where EndDate < '9999-01-01' to confirm whether EndDate is ever populated with real values.
