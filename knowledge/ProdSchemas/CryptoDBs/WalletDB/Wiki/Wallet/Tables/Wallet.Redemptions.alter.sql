-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.Redemptions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_redemptions
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_redemptions (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions SET TBLPROPERTIES (
    'comment' = 'Records every redemption operation where a customer converts a crypto trading position into actual cryptocurrency deposited into their wallet, tracking the position, amounts, fees, and processing status. Source: WalletDB.Wallet.Redemptions on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Redemptions.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'Redemptions',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions ALTER COLUMN OriginalRequestGuid COMMENT 'GUID of the original redemption request from the trading platform. Used for idempotency and cross-system correlation. (Tier 1 - upstream wiki, WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions ALTER COLUMN SendRequestCorrelationId COMMENT 'Links to the send transaction request in Wallet.Requests.CorrelationId created when the blockchain transfer is initiated. NULL until the redemption reaches the execution stage. (Tier 1 - upstream wiki, WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions ALTER COLUMN PositionId COMMENT 'Trading platform position being redeemed. Unique constraint - each position can only be redeemed once. NULL only for legacy records. (Tier 1 - upstream wiki, WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions ALTER COLUMN RequestingGcid COMMENT 'Global Customer ID of the customer requesting the redemption. (Tier 1 - upstream wiki, WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions ALTER COLUMN CryptoId COMMENT 'The cryptocurrency being redeemed. Implicit reference to Wallet.CryptoTypes.CryptoID. (Tier 1 - upstream wiki, WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions ALTER COLUMN RequestedAmount COMMENT 'Gross amount of crypto requested for redemption. In native units of CryptoId. (Tier 1 - upstream wiki, WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions ALTER COLUMN eToroFeeAmount COMMENT 'eToro''s service fee deducted from the redemption. Typically ~2% of RequestedAmount. (Tier 1 - upstream wiki, WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions ALTER COLUMN RedemptionStatus COMMENT 'Lifecycle status: 0=Persisted, 1=Retrieved, 2=SentToExecuter, 3=SuccessReported, 4=FailureReported. See Redemption Status. FK to Dictionary.RedemptionStatus. (Tier 1 - upstream wiki, WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions ALTER COLUMN BillingTransId COMMENT 'Transaction ID in the billing/accounting system for the fee charge. (Tier 1 - upstream wiki, WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions ALTER COLUMN BillingRedeemId COMMENT 'Redemption ID in the billing/accounting system. (Tier 1 - upstream wiki, WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions ALTER COLUMN BeginDate COMMENT 'System-versioned temporal column (ROW START). (Tier 1 - upstream wiki, WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions ALTER COLUMN EndDate COMMENT 'System-versioned temporal column (ROW END). (Tier 1 - upstream wiki, WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions ALTER COLUMN EstimatedBlockchainFee COMMENT 'Estimated network fee for the blockchain transfer. Calculated before execution based on current network conditions. (Tier 1 - upstream wiki, WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions ALTER COLUMN InitialFeeAmount COMMENT 'Fixed base fee charged regardless of amount. Defaults to 0 for most cryptos. (Tier 1 - upstream wiki, WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions ALTER COLUMN SourceWalletId COMMENT 'The omnibus/system wallet from which the crypto is sent to the customer. FK to Wallet.Wallets.WalletId. NULL for legacy records. (Tier 1 - upstream wiki, WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_redemptions ALTER COLUMN TransactionTypeId COMMENT 'Type of sent transaction created: typically 0 (Redeem) or 8 (RedeemAsic). FK to Dictionary.TransactionTypes. See Transaction Type. (Tier 1 - upstream wiki, WalletDB.Wallet.Redemptions)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
