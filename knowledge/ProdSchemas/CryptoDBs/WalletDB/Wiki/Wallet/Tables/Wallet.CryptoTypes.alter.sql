-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.CryptoTypes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_cryptotypes
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_cryptotypes (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes SET TBLPROPERTIES (
    'comment' = 'Master registry of all supported cryptocurrency assets (native coins and ERC-20 tokens) defining each asset''s configuration, display properties, blockchain mapping, fee parameters, and trading instrument linkage. Source: WalletDB.Wallet.CryptoTypes on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'CryptoTypes',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN CryptoID COMMENT 'Unique identifier for this crypto asset. Manually assigned (not IDENTITY). Referenced as FK by Wallet.SentTransactions, Wallet.ReceivedTransactions, Wallet.WalletBalances, Wallet.WalletAssets, Wallet.Conversions, Wallet.Payments, Wallet.AmlProviderContracts, Wallet.CryptoMarketRatesMappings, Wallet.PromotionTags, and many stored procedures. The most widely-referenced PK in the schema. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN Name COMMENT 'Ticker symbol (e.g., BTC, ETH, USDT, LINK). Used for API parameter matching and internal identification. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN MinReqAccounts COMMENT 'Minimum number of accounts/signers required for wallet operations on this crypto. Related to multi-signature wallet configuration. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN MinUnit COMMENT 'Minimum transferable unit (satoshi-equivalent) for this crypto. Defines the smallest amount that can be sent. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN Status COMMENT 'Legacy status field. Superseded by CryptoActivityStatus for business logic. Maintained for backward compatibility. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN MinReqVerifications COMMENT 'Minimum number of blockchain confirmations required before a received transaction is considered confirmed. Varies by blockchain (e.g., BTC needs more confirmations than ETH). (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN MaxVerificationTimeMinutes COMMENT 'Maximum time in minutes to wait for blockchain confirmations before timing out a transaction. Used for monitoring stuck transactions. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN Occurred COMMENT 'Timestamp when this crypto asset was added to the system. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN IsActive COMMENT 'Secondary activation toggle. 1=active, 0=disabled. Works alongside CryptoActivityStatus to control asset availability. Most active assets have IsActive=1. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN CryptoActivityStatus COMMENT 'Availability level for wallet operations: 0=NotActive, 1=ComingSoon, 2=Available (173 assets), 3=AvailableRedeemOnly (XRP only). See Crypto Activity Status. FK to Dictionary.CryptoActivityStatuses. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN BalanceAssetName COMMENT 'Asset name as known by the balance/custody provider (e.g., BitGo''s internal asset identifier). May differ from the display name. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN WebHookVerifications COMMENT 'Number of webhook-based verification callbacks required from the blockchain provider before confirming a transaction. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN StartMonitoringDelaySeconds COMMENT 'Delay in seconds before starting to monitor a newly submitted transaction. Default 120s allows the blockchain network to propagate the transaction. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN BalanceThreshold COMMENT 'Minimum balance threshold below which a wallet is considered effectively empty. Used for balance checks and dust amount detection. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN InitialFeeUnits COMMENT 'Base fee units charged per transaction for this crypto. 0 means no initial fee (blockchain fee only). (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN BlockchainExplorerFormat COMMENT 'URL format string for generating blockchain explorer links (e.g., "https://blockchain.com/btc/tx/{txId}"). Used in UI to link transactions to explorer pages. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN IsEtoroHandlingFee COMMENT 'Whether eToro charges an additional handling fee on top of blockchain network fees for this crypto. 1=yes, 0/NULL=no. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN BlockchainCryptoId COMMENT 'The blockchain network this crypto asset runs on. For native coins, maps 1:1 (BTC->1, ETH->2). For ERC-20 tokens, all point to 2 (Ethereum). FK to Wallet.BlockchainCryptos.Id. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN AssetTypeId COMMENT 'Asset classification: 1=Coin (12 native blockchain coins), 2=ERC20 (162 Ethereum tokens). See Asset Type. FK to Dictionary.AssetTypes. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN SymbolFull COMMENT 'Full ticker symbol used in API responses and market data integration. Usually identical to Name. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN DisplayName COMMENT 'Human-readable asset name shown in the UI (e.g., "Bitcoin", "Ethereum", "Cardano"). More descriptive than the ticker symbol. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN AvatarUrl COMMENT 'URL to the crypto asset''s logo/icon image. Used in the wallet UI for visual identification. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN Precision COMMENT 'Number of decimal places used when displaying amounts of this crypto. BTC/ETH=6, XLM=7, EOS=4. Controls UI formatting. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN TagName COMMENT 'Name of the secondary address field required by some blockchains (e.g., "Destination Tag" for XRP, "Memo" for XLM). NULL for blockchains that don''t require a tag. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN InstrumentId COMMENT 'Links to the eToro trading platform''s instrument for this crypto (e.g., BTC=100000, ETH=100001). Used for market rate lookups and position valuation. Implicit reference to Wallet.Instruments.InstrumentId. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN AssetBlockchainAddress COMMENT 'Smart contract address for ERC-20 tokens on the Ethereum blockchain. NULL for native coins. Used to identify the token when interacting with the Ethereum network. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN OrderIndex COMMENT 'Controls display order in the wallet UI. Lower values appear first. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN CryptoCategoryName COMMENT 'Category classification for the crypto asset (e.g., "DeFi", "Payment", "Meme"). Used for UI grouping and filtering. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN StakingDisplayName COMMENT 'Display name specifically for staking context (e.g., "Cardano Staking"). NULL for non-stakeable assets. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN StakingAvatarUrl COMMENT 'Logo URL for the staking variant. May differ from the regular avatar. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptotypes ALTER COLUMN StakingSymbolFull COMMENT 'Ticker symbol for staking context. NULL for non-stakeable assets. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoTypes)';

