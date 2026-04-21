-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_InternalWallet
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- EXW_dbo.EXW_InternalWallet is eToro''s own internal blockchain wallet inventory — the company''s system-owned crypto addresses across all supported assets. While the broader wallet platform manages millions of customer wallets, this table holds only the internal/operational wallets that eToro uses to run its crypto business. **What Gcid ≤ 0 means**: In WalletDB, customer accounts have positive GCIDs. Gcid=0 conventionally indicates omnibus/system wallets (eToro''s pooled holdings), and negative Gcid values represent other internal service accounts. The `WHERE Gcid <= 0` filter in SP_EXW_InternalWallet isolates these non-customer wallets. **Wallet types present**: Since Gcid ≤ 0 excludes standard customer wallets (type 5), all rows in this table have InternalWalletTypeId in {1, 2, 3, 4, 6, 7}: - 1=Redeem: wallets used for redemption/withdrawal operations - 2=Conversion: wallets used for c

