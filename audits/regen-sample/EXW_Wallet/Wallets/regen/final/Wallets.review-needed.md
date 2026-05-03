# EXW_Wallet.Wallets — Review Needed

## Summary

All 10 business columns are Tier 3 (no upstream wiki available). The `_no_upstream_found.txt` marker is present, confirming no resolvable upstream documentation exists for WalletDB.Wallet.Wallets. Descriptions are grounded in DDL structure, live data evidence, and downstream view usage.

## Tier 3 Items Requiring Human Review

| # | Column | Tier | Review Reason |
|---|---|---|---|
| 1 | Id | Tier 3 | No upstream wiki for WalletDB.Wallet.Wallets. Description inferred from column name (bigint surrogate) and data pattern (sequential values). Confirm whether Id is auto-generated or application-assigned. |
| 2 | WalletId | Tier 3 | No upstream wiki. Identified as business key from HASH distribution and FK usage in views. Confirm uniqueness semantics (one WalletId per customer-crypto pair or globally unique). |
| 3 | Gcid | Tier 3 | No upstream wiki. Identified as Global Customer ID from downstream view usage (EXW_CustomerWalletsView, EXW_TransactionsView). Confirm FK target (DWH_dbo.Dim_Customer or similar). |
| 4 | BlockchainCryptoId | Tier 3 | No upstream wiki. FK resolved to EXW_Wallet.BlockchainCryptos (12 crypto types). Description includes inline values from live data. |
| 5 | WalletTypeId | Tier 3 | No upstream wiki. FK resolved to EXW_Dictionary.WalletTypes (7 types). 99.99% are Customer. Confirm whether non-Customer types represent internal/system wallets. |
| 6 | IsActive | Tier 3 | No upstream wiki. Only 4 inactive records. Confirm business meaning — does IsActive=0 mean soft-deleted or temporarily suspended? |
| 7 | Occurred | Tier 3 | No upstream wiki. Described as event timestamp based on data range. Confirm whether this is creation time, last-modified time, or event time. |
| 8 | BeginDate | Tier 3 | No upstream wiki. SCD pattern inferred from BeginDate/EndDate pair. Many early records share identical BeginDate (2019-04-14), suggesting backfill. Confirm SCD semantics. |
| 9 | EndDate | Tier 3 | No upstream wiki. Sentinel value 9999-12-31 confirmed from data. Confirm SCD Type 2 semantics. |
| 10 | IsActivated | Tier 3 | No upstream wiki. 7,319 unactivated wallets observed. Confirm activation lifecycle — what triggers activation? |

## Questions for SME

1. **WalletDB documentation**: Is there any internal documentation (Confluence, README, or code comments) for the WalletDB.Wallet.Wallets production table that could upgrade these columns to Tier 1?
2. **IsActive vs IsActivated**: What is the precise distinction between these two flags? When can a wallet be active but not activated, and vice versa?
3. **SCD semantics**: Is the BeginDate/EndDate pattern a formal SCD Type 2, or is it a simpler validity window? The bulk backfill date (2019-04-14) suggests a migration event.
4. **Gcid linkage**: Does Gcid map to DWH_dbo.Dim_Customer.RealCID or to a different customer identifier?

## Missing Upstream Wiki

- `_no_upstream_found.txt` is present — no wiki exists for WalletDB.Wallet.Wallets in any scanned upstream repo.
- To upgrade Tier 3 columns to Tier 1, create a wiki for WalletDB.Wallet.Wallets in the CryptoDBs or equivalent upstream repo.
