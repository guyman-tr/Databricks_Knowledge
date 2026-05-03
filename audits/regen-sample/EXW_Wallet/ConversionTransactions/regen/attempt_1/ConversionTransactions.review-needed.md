# EXW_Wallet.ConversionTransactions — Review Needed

> Generated: 2026-04-30 | Reviewer: Please verify the items below before promoting to the main wiki tree.

## 1. Tier Coverage

All 13 columns are Tier 3 (no upstream wiki available). The `_no_upstream_found.txt` marker confirms no production wiki exists for WalletDB.Wallet.ConversionTransactions in any upstream repo.

**Action needed**: If a WalletDB/CryptoDBs wiki becomes available in the future, re-run the pipeline to upgrade columns to Tier 1.

## 2. Dormant Status

- Last recorded Occurred timestamp: 2023-06-14
- Generic Pipeline #656 is configured for daily Append but no new data has arrived since mid-2023
- **Action needed**: Confirm whether the conversion feature was deprecated, moved to a different system, or simply paused. Update the Refresh property accordingly.

## 3. CryptoId Lookup

- CryptoId has 25 distinct values but no formal dictionary exists in EXW_Dictionary
- EXW_Wallet.CryptoTypes is referenced in the EXW_TransactionsView and EXW_FactConversions but no wiki exists for it
- **Action needed**: Document EXW_Wallet.CryptoTypes to enable CryptoId value mapping (e.g., 1=BTC, 2=ETH, etc.)

## 4. Row Count Discrepancy with Parent Table

- EXW_Wallet.Conversions has 50,268 rows (documented)
- EXW_Wallet.ConversionTransactions has 98,713 rows (~1.96 per conversion)
- Expected: exactly 2 rows per conversion (FROM + TO legs)
- The slight deviation (98,713 vs 100,536 expected) suggests some conversions may have only 1 leg or >2 legs
- **Action needed**: Investigate whether some ConversionIds appear only once or more than twice

## 5. EtoroFeePercentage Outliers

- 18 rows have EtoroFeePercentage = 1.00 (vs normal 0.10)
- 6 rows have EtoroFeePercentage = 0.50
- **Action needed**: Determine whether these are special fee tiers, errors, or promotional rates

## 6. No FK Constraints

- No foreign key constraints defined in DDL
- Referential integrity to EXW_Wallet.Conversions is application-enforced
- **Action needed**: Verify that orphaned ConversionTransaction rows (with no matching Conversion) do not exist

---

*Items: 6 | Tier 3: 13 | Tier 4: 0 | Blocking: None*
