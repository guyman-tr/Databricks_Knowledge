-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_WalletInventory
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory SET TBLPROPERTIES (
    'comment' = 'EXW_WalletInventory is the daily snapshot of every blockchain wallet in the eToro Wallet system, combining the pre-provisioned pool wallets (not yet assigned to users) with the wallet-to-customer assignments. Each row represents one wallet for one blockchain - either a pool slot awaiting assignment (`Occupied=0`, `GCID` NULL, `PublicAddress` NULL) or a live customer wallet (`Occupied=1`, `GCID` set, `PublicAddress` populated). The table answers the question "Which wallets does customer X have?" and "How many wallets are available for coin Y in the pool?" The pool architecture exists because creating on-chain wallets takes time - eToro pre-generates wallets in bulk so new customers can be assigned a wallet instantly. As of last refresh: 1,771,467 occupied wallets (64%) belong to 702,412 distinct customers; 976,952 wallets (36%) are in the free pool. Top cryptos by wallet count: BTC (742K), ETH (353K), LTC (326K), XLM (298K), BCH (261K), XRP (137K). Coverage from 2018-04-23 to 2026-04-09 (Created); actively ...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'EXW_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(GCID)',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `WalletID` COMMENT 'Internal wallet identifier (GUID). The primary business key used across the wallet system. Unique constraint. FK target for Wallet.WalletAddresses, Wallet.ReceivedTransactions, and Wallet.AmlValidations. Also referenced by Wallet.Wallets (logical link, not FK). Stored as nvarchar(max) in Synapse (source is uniqueidentifier). (Tier 1 - WalletDB.Wallet.WalletPool)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `CryptoID` COMMENT 'Platform cryptocurrency identifier for this wallet. Equals BlockchainCryptoId for all rows due to SP WHERE filter (ERC-20 token wallets are excluded). FK to EXW_Wallet.CryptoTypes.CryptoID. (Tier 2 - SP_EXW_WalletInventory)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `ProviderWalletID` COMMENT 'Wallet identifier assigned by the external custody provider (BitGo or CUG). Used for all API interactions with the provider. Format varies by provider. NULL for unoccupied pool wallets. (Tier 1 - WalletDB.Wallet.WalletPool)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `PublicAddress` COMMENT 'Blockchain address associated with this wallet. Users send crypto to this address. NULL during initial creation before address generation completes. Format depends on blockchain (e.g., bc1... for BTC, 0x... for ETH). NULL for unoccupied pool wallets. (Tier 1 - WalletDB.Wallet.WalletPool)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `Created` COMMENT 'Timestamp when this pool wallet was created. Used for pool age monitoring and FIFO assignment ordering. DWH note: CAST from datetime2 source. (Tier 1 - WalletDB.Wallet.WalletPool)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `Occupied` COMMENT 'Whether this wallet has been assigned to a customer: 1=occupied (GCID is set), 0=available in the pool. Computed by SP: CASE WHEN GCID IS NOT NULL THEN 1 ELSE 0 END. (Tier 2 - SP_EXW_WalletInventory)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `GCID` COMMENT 'Global Customer ID of the wallet owner. For customer wallets (type 5), this is the real user. For system wallets (types 1-4, 6-7), this is a service account. Gcid=0 conventionally indicates omnibus/system wallets. From Wallet.Wallets.Gcid. NULL for unoccupied pool wallets. HASH distribution key for this table. (Tier 1 - WalletDB.Wallet.CustomerWalletsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of the last ETL data load. Set to GETDATE() at SP execution - reflects the daily refresh date, not the wallet creation or assignment date. (Tier 2 - SP_EXW_WalletInventory)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `WalletPoolID` COMMENT 'Duplicate of WalletID. Both WalletID and WalletPoolID are set to WalletPool.WalletId in the SP. Loading artifact - carries no additional information. Do not use for filtering or grouping. (Tier 4 - data observation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `CryptoName` COMMENT 'Human-readable name of the cryptocurrency for this wallet (e.g., BTC, ETH, SOL). Denormalized from EXW_Wallet.CryptoTypes. Mirrors the CryptoID selection logic: ERC-20 name takes precedence if available, else blockchain native name. (Tier 2 - EXW_Wallet.CryptoTypes)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `LastWalletPoolStatus` COMMENT 'The lifecycle status: 1=Pending, 2=Verified, 3=Failed, 4=FundingInitiated, 5=FundingSent, 6=FundingVerified, 7=FundingFailed, 10=Timeout, 11=VerifiedForAssign. FK to Dictionary.WalletPoolStatuses. DWH note: derived as the latest status event per wallet via ROW_NUMBER() OVER (PARTITION BY WalletPoolId ORDER BY Occurred DESC) in SP. (Tier 1 - WalletDB.Wallet.WalletPoolStatuses)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `WalletStatus` COMMENT 'Denormalized string name for LastWalletPoolStatus. Values: Pending, Verified, Failed, FundingInitiated, FundingSent, FundingVerified, FundingFailed, Timeout, VerifiedForAssign. Joined from CopyFromLake.WalletDB_Dictionary_WalletPoolStatuses. (Tier 2 - WalletDB_Dictionary_WalletPoolStatuses)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `PromotionTagID` COMMENT 'Links to a promotional campaign if this wallet is part of a promotion. NULL for standard wallets. FK to Wallet.PromotionTags.Id. (Tier 1 - WalletDB.Wallet.WalletPoolStatuses)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `IsPromotionReady` COMMENT 'Whether this wallet is eligible to be distributed as a promotion: 1=ready (PromotionTagId=1 AND CryptoID is a supported blockchain crypto), 0=not ready. Computed by SP CASE expression. (Tier 2 - SP_EXW_WalletInventory)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `Allocated` COMMENT 'Timestamp when this crypto asset was first added to the wallet (when the user first acquired this crypto). From Wallet.WalletAssets.Occurred. Used for portfolio age tracking and ordering. DWH note: CAST to DATE type; NULL for unoccupied pool wallets. (Tier 1 - WalletDB.Wallet.CustomerWalletsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `BlockchainCryptoId` COMMENT 'The blockchain this pool wallet was created for. FK to Wallet.BlockchainCryptos.Id. Determines which blockchain network the PublicAddress belongs to. Always equals CryptoID due to SP WHERE filter. (Tier 1 - WalletDB.Wallet.WalletPool)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `BlockchainCryptoName` COMMENT 'Blockchain network name for this wallet (e.g., BTC, ETH, SOL). Denormalized from EXW_Wallet.BlockchainCryptos by joining on BlockchainCryptoId. Always equals CryptoName due to the native-coin-only filter. (Tier 2 - EXW_Wallet.BlockchainCryptos)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `CreatedDateID` COMMENT 'Date integer derived from Created in YYYYMMDD format. Computed by SP: CAST(CONVERT(VARCHAR(8), Created, 112) AS INT). Useful for date-based partitioning and joining to calendar dimension tables. (Tier 2 - SP_EXW_WalletInventory)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `NormalizedAddress` COMMENT 'Computed PERSISTED column that strips protocol prefixes (before '':'') and query parameters (after ''?'') from the Address. Enables consistent address matching regardless of formatting. Indexed for lookup performance. Passthrough from Wallet.WalletAddresses (IsMain=1). NULL for unoccupied pool wallets. (Tier 1 - WalletDB.Wallet.WalletAddresses)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `WalletID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `CryptoID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `ProviderWalletID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `PublicAddress` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `Created` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `Occupied` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `WalletPoolID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `CryptoName` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `LastWalletPoolStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `WalletStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `PromotionTagID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `IsPromotionReady` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `Allocated` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `BlockchainCryptoId` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `BlockchainCryptoName` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `CreatedDateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory ALTER COLUMN `NormalizedAddress` SET TAGS ('pii' = 'direct');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-05 13:20:34 UTC
-- Batch deploy resume: EXW_dbo deploy batch 2
-- Statements: 40/40 succeeded
-- ====================
