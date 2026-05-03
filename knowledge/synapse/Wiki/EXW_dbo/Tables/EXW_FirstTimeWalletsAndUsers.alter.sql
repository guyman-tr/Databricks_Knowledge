-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_FirstTimeWalletsAndUsers
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- EXW_FirstTimeWalletsAndUsers is the canonical daily summary of new user and wallet adoption in eToro''s Crypto Wallet product. It answers: "How many new wallet users (NewUsers) and new wallets (NewWallets) were created on a given day, broken down by country, regulation, crypto type, user segment, and geography?" **NewUsers** counts GCIDs whose first wallet join date (UserJoinDate from New_UsersAndWallets_Inventory) equals FullDate - these are brand-new wallet participants on that day. ROW_NUMBER() deduplication ensures each GCID is counted only once even if they opened multiple wallets on the same day. **NewWallets** counts all new wallets (WalletJoinDate = FullDate) regardless of whether the user is new or an existing user opening a wallet for a new crypto type. A single user opening ETH, BTC, and ADA wallets on the same day contributes 3 to NewWallets but 1 to NewUsers. The distinction

