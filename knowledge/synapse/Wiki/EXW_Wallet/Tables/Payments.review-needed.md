# Review Needed: EXW_Wallet.Payments

## 1. No Upstream Wiki Available

- **Issue**: No upstream wiki exists for WalletDB.Wallet.Payments. The `_no_upstream_found.txt` marker is present. All 8 business columns are Tier 3 (grounded in DDL, sample data, and downstream usage context).
- **Action**: If a wiki for WalletDB.Wallet.Payments is created in the future (e.g., in CryptoDBs/WalletDB/Wiki/), re-run documentation to upgrade columns to Tier 1.

## 2. Frozen Table — Confirm Decommission Status

- **Issue**: No new data since 2022-09-20. The downstream EXW_dbo.EXW_FactPayments wiki states Simplex was decommissioned in September 2022. Confirm whether the Generic Pipeline ingestion has been officially disabled or is still running (appending empty batches).
- **Action**: Check the Generic Pipeline configuration (generic_id=711) to confirm whether the pipeline is disabled or still active.

## 3. WalletId Column Width

- **Issue**: WalletId is defined as varchar(4000) but contains GUID values (~36 characters). This is an unusually wide column for a GUID.
- **Action**: Verify whether this matches the production source schema or is an artifact of Generic Pipeline type mapping.

## 4. Amount Semantics — Fiat vs Crypto

- **Issue**: The Amount column stores the fiat payment amount (e.g., EUR/GBP), not the crypto amount received. The crypto amount is in EXW_Wallet.PaymentTransactions.Amount. This distinction is critical for analysts.
- **Action**: Confirm this interpretation by cross-referencing with the downstream EXW_FactPayments documentation which confirms the same semantics.

## 5. No Stored Procedure Writer

- **Issue**: No stored procedure was found that writes to EXW_Wallet.Payments. The table is populated entirely by the Generic Pipeline. This is consistent with a bronze landing table pattern but means there is no SP logic to trace column transformations.
- **Action**: No action needed — this is expected for Generic Pipeline tables.

## 6. UC Target Verification

- **Issue**: The UC target `wallet.bronze_walletdb_wallet_payments` was derived from the Generic Pipeline mapping (generic_id=711). Verify this table exists in Unity Catalog and is receiving data.
- **Action**: Check UC catalog for the bronze table existence and freshness.
