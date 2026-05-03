-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.New_UsersAndWallets_Inventory
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- New_UsersAndWallets_Inventory is the canonical source of wallet inception dates in the eToro Wallet system. It answers two related but distinct questions per customer: 1. **When did this user first get any wallet?** -> `UserJoinDate` (MIN(Allocated) across all cryptos for this GCID) 2. **When did this user first get a Bitcoin / ETH / [crypto X] wallet?** -> `WalletJoinDate` (MIN(Allocated) for this GCID × CryptoID combination) These two dates are identical for a user''s first-ever wallet acquisition (e.g., getting BTC for the first time), but diverge when an existing user opens a wallet for a new cryptocurrency. For example, a user who joined in 2020 (UserJoinDate=2020-03-15) but first acquired SOL in 2022 (WalletJoinDate=2022-08-10) would have both dates populated correctly. The table covers 699,694 distinct GCIDs - matching the EXW_DimUser scope - and 174 crypto types. The WHERE GCID>0 f

