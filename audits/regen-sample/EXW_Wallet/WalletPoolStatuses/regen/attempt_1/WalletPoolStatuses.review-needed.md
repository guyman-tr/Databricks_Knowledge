# Review Needed: EXW_Wallet.WalletPoolStatuses

## 1. No Upstream Wiki Available

All 13 columns are Tier 3 — no upstream wiki was resolvable for `WalletDB.Wallet.WalletPoolStatuses`. Descriptions are grounded in DDL structure, CopyFromLake staging DDL, SP code analysis (SP_EXW_WalletInventory, SP_EXW_Hourly), dictionary lookup values, and live data evidence.

**Action**: If a wiki for WalletDB.Wallet.WalletPoolStatuses is created in CryptoDBs or a similar upstream repo, re-run the pipeline to upgrade columns to Tier 1.

## 2. Processed Column — Always False

The `Processed` column is `bit` and contains only `False` values across all 3.24M rows. This suggests either:
- An event processing mechanism that was never implemented
- Processing is handled externally and the flag is never written back to this table
- The column is deprecated

**Action**: Confirm with the Wallet team whether `Processed` serves any active purpose.

## 3. ETL Partition Columns (etr_y, etr_ym, etr_ymd) — NULL for Recent Data

These columns are populated for older records but NULL for records from 2024 onward. This suggests a change in the Generic Pipeline partitioning strategy.

**Action**: Confirm whether these columns are still part of the active ETL or are legacy artifacts.

## 4. PromotionTagId Semantics

The value `1` appears frequently in samples and is used in SP_EXW_WalletInventory to derive `IsPromotionReady`. The exact meaning of PromotionTagId values beyond 1 is unclear — no dictionary table was found for this column.

**Action**: Identify if a PromotionTag dictionary exists in WalletDB and document the value mappings.

## 5. Id Column — Primary Key Confirmation

`Id` appears to be a surrogate key (bigint, values like 888203, 3428782) but is nullable per DDL. Confirm whether this is the production PK and whether NULLs are possible.

**Action**: Verify uniqueness and NOT NULL constraint in production WalletDB.
