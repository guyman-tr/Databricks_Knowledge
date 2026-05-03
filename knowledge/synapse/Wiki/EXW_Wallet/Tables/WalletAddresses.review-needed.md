# EXW_Wallet.WalletAddresses — Review Needed

## 1. Tier 3 Columns — No Upstream Wiki

All 9 production-sourced columns are Tier 3 because no upstream wiki exists for `WalletDB.Wallet.WalletAddresses`. Descriptions are grounded in DDL structure, sample data analysis, and downstream SP usage patterns (SP_EXW_WalletInventory, EXW_TransactionsView, SP_EXW_FactBalance).

**Action**: If a wiki for `WalletDB.Wallet.WalletAddresses` is created in CryptoDBs or a similar upstream repo, these columns should be upgraded to Tier 1 with verbatim descriptions.

## 2. CustomerWalletStatusId — Unknown Dictionary

- All 2,465,354 rows have `CustomerWalletStatusId = 1`
- No dictionary table was identified in the EXW_Wallet or EXW_Dictionary schemas for this status
- **Action**: Confirm what status value 1 means (likely "Active") and whether other values are possible in production

## 3. BalanceAccountID — Sparse Population

- Many rows (especially newer ones from ~2021 onward) have NULL BalanceAccountID
- Older rows (2018-2020 era) tend to have populated values (e.g., numeric IDs like 933827)
- **Action**: Confirm whether BalanceAccountID was deprecated in production or is only populated for certain wallet types

## 4. etr_* NULL Pattern

- 814,946 rows have NULL etr_y, suggesting these were loaded before the ETL partition columns were added
- **Action**: Confirm whether a backfill is planned or whether these historical rows will remain without partition metadata

## 5. IsMain Distribution Anomaly

- Only 50 out of 2.47M rows have IsMain = False
- **Action**: Confirm whether secondary addresses are still being created in production or if this is a legacy pattern

## 6. Production Source Confirmation

- Generic Pipeline mapping (id=717) maps to `WalletDB.Wallet.WalletAddresses` with Append strategy
- No writer SP exists for this table — CopyFromLake is the sole ETL mechanism
- **Action**: No action needed unless the pipeline configuration changes

---

*Generated: 2026-04-30*
