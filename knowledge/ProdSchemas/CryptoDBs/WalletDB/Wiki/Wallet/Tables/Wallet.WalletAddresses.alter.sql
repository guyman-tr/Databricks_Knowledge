-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.WalletAddresses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletAddresses.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_walletaddresses
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_walletaddresses (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletaddresses SET TBLPROPERTIES (
    'comment' = 'Links blockchain addresses to their parent wallets, storing the public address, activation status, and provider wallet ID for each address a wallet owns. Supports multiple addresses per wallet with computed normalized address for cross-format matching. Source: WalletDB.Wallet.WalletAddresses on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 120-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletAddresses.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_walletaddresses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'WalletAddresses',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '120'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletaddresses ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletaddresses ALTER COLUMN WalletId COMMENT 'The parent wallet this address belongs to. FK to Wallet.WalletPool.WalletId. Multiple addresses can share the same WalletId (Bitcoin UTXO wallets). (Tier 1 - upstream wiki, WalletDB.Wallet.WalletAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletaddresses ALTER COLUMN Address COMMENT 'The raw blockchain address string as provided by the wallet provider. May include protocol prefixes or query parameters. Unique constraint enforced. NULL only for wallets with deferred address generation. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletaddresses ALTER COLUMN IsMain COMMENT 'Whether this is the wallet''s primary address. 1=main address (used for receiving), NULL/0=secondary address. Most wallets have exactly one main address. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletaddresses ALTER COLUMN BlockchainProviderWalletId COMMENT 'Provider-side wallet identifier (BitGo or CUG wallet ID). Used for API calls to the custody provider. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletaddresses ALTER COLUMN CustomerWalletStatusId COMMENT 'Activation state: 0=Pending (awaiting blockchain confirmation), 1=Active (ready for transactions). See Customer Wallet Status. FK to Dictionary.CustomerWalletStatus. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletaddresses ALTER COLUMN Occurred COMMENT 'Timestamp when this address record was created. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletaddresses ALTER COLUMN BalanceAccountID COMMENT 'External balance account identifier used by the provider for balance tracking. NULL for wallets without provider-side balance accounts. Unique constraint (filtered, non-NULL only). (Tier 1 - upstream wiki, WalletDB.Wallet.WalletAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_walletaddresses ALTER COLUMN NormalizedAddress COMMENT 'Computed PERSISTED column that strips protocol prefixes (before '':'') and query parameters (after ''?'') from the Address. Enables consistent address matching regardless of formatting. Indexed for lookup performance. (Tier 1 - upstream wiki, WalletDB.Wallet.WalletAddresses)';

