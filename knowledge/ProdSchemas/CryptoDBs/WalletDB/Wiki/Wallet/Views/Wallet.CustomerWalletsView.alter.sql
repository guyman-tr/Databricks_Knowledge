-- =============================================================================
-- Databricks ALTER Script: main.wallet.bronze_walletdb_wallet_customerwalletsview  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN Id COMMENT 'The wallet''s universal business key (aliased from Wallets.WalletId). Used as the primary identifier across the entire wallet system - referenced by SentTransactions, ReceivedTransactions, Conversions, Payments, Redemptions, and all balance/transaction lookups. From Wallet.Wallets.WalletId.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN Gcid COMMENT 'Global Customer ID of the wallet owner. For customer wallets (type 5, 99.99% of rows), this is the real user. For system wallets (types 1-4, 6-7), this is a service account. Gcid=0 conventionally indicates omnibus/system wallets. From Wallet.Wallets.Gcid.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN CryptoId COMMENT 'The cryptocurrency asset visible in this wallet. FK to Wallet.CryptoTypes.CryptoID. Combined with Gcid for the standard wallet lookup pattern: `WHERE Gcid = @gcid AND CryptoId = @cryptoId`. From Wallet.WalletAssets.CryptoId.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN Address COMMENT 'Blockchain public address associated with this wallet. Users send/receive crypto at this address. Format varies by blockchain: BTC starts with 1/3/bc1, ETH starts with 0x, SOL is base58. Aliased from Wallet.WalletPool.PublicAddress. May be NULL during initial creation before address generation completes.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN BlockchainProviderWalletId COMMENT 'External wallet identifier assigned by the custody provider (BitGo or CUG). Used for all API interactions with the provider. Aliased from Wallet.WalletPool.ProviderWalletId. Format is provider-specific (typically a hex hash for BitGo).';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN Occurred COMMENT 'Timestamp when this crypto asset was first added to the wallet (when the user first acquired this crypto). From Wallet.WalletAssets.Occurred. Used for portfolio age tracking and ordering.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN WalletTypeId COMMENT 'Operational purpose of the wallet: 1=Redeem, 2=Conversion, 3=Funding, 4=Payment, 5=Customer (99.99%), 6=C2F, 7=StakingRefund. See [Wallet Type](../../_glossary.md#wallet-type). FK to Dictionary.WalletTypes. From Wallet.Wallets.WalletTypeId.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN IsActive COMMENT 'Whether this wallet is currently operational. Always 1 in this view (WHERE filter), but included for schema compatibility. 1=active, 0=deactivated (excluded by view). From Wallet.Wallets.IsActive.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN Status COMMENT 'Computed activation status: 0=Created/Active (wallet fully operational, IsActivated=1), 5=Pending activation (awaiting blockchain confirmation, IsActivated=0). Computed in view: `CASE WHEN w.IsActivated = 1 THEN 0 ELSE 5 END`. 99.6% of rows are Status=0.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN WalletRecordId COMMENT 'Auto-incrementing surrogate key from the base Wallets table. Aliased from Wallet.Wallets.Id. Useful for ordering by creation sequence.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN BlockchainCryptoId COMMENT 'The blockchain network this wallet operates on. FK to Wallet.BlockchainCryptos.Id. Determines which blockchain the Address belongs to. May differ from CryptoId for multi-token blockchains (e.g., ERC-20 tokens share the ETH blockchain). From Wallet.Wallets.BlockchainCryptoId.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN WalletProviderId COMMENT 'Custody provider: 1=BitGo (97.5% of wallets, multi-sig), 2=CUG (2.5%, MPC-based, newer blockchains like SOL). See [Wallet Provider](../../_glossary.md#wallet-provider). FK to Dictionary.WalletProvider. From Wallet.WalletPool.WalletProviderId.';
ALTER TABLE main.wallet.bronze_walletdb_wallet_customerwalletsview ALTER COLUMN IsActivated COMMENT 'Whether the wallet has completed initial blockchain activation. 1=activated (fully operational), 0=pending activation. The Status column is derived from this value. From Wallet.Wallets.IsActivated.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:25:43 UTC
-- Statements: 13/13 succeeded
-- ====================
