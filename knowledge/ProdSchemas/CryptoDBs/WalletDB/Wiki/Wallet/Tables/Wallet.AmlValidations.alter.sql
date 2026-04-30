-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.AmlValidations
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_amlvalidations
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_amlvalidations (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlvalidations SET TBLPROPERTIES (
    'comment' = 'Records every AML (Anti-Money Laundering) screening result for blockchain transactions, capturing the provider''s risk assessment, address analysis, and compliance decision for both sent and received transactions. Source: WalletDB.Wallet.AmlValidations on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_amlvalidations SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'AmlValidations',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlvalidations ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, WalletDB.Wallet.AmlValidations)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlvalidations ALTER COLUMN AmlProviderId COMMENT 'Which AML provider performed this screening: 1=Chainalysis, 2=BlackList, 3=Unsupported, 4=ChainalysisCDN. See AML Provider. FK to Dictionary.AmlProviders. (Tier 1 - upstream wiki, WalletDB.Wallet.AmlValidations)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlvalidations ALTER COLUMN IsSend COMMENT 'Direction of the transaction: 1=outbound (screening destination before sending), 0=inbound (screening sender after receiving). (Tier 1 - upstream wiki, WalletDB.Wallet.AmlValidations)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlvalidations ALTER COLUMN Address COMMENT 'The blockchain address being screened. For sends, this is the destination address. For receives, this is the sender address. NULL when screening is provider-level (not address-specific). (Tier 1 - upstream wiki, WalletDB.Wallet.AmlValidations)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlvalidations ALTER COLUMN WalletId COMMENT 'The eToro wallet involved in the transaction. FK to Wallet.WalletPool.WalletId. For sends, the source wallet. For receives, the receiving wallet. (Tier 1 - upstream wiki, WalletDB.Wallet.AmlValidations)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlvalidations ALTER COLUMN Amount COMMENT 'Transaction amount in the crypto''s native units. Used for risk scoring (higher amounts may trigger additional scrutiny). (Tier 1 - upstream wiki, WalletDB.Wallet.AmlValidations)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlvalidations ALTER COLUMN ProviderStatus COMMENT 'Raw status string returned by the AML provider. Provider-specific format (e.g., Chainalysis risk score). (Tier 1 - upstream wiki, WalletDB.Wallet.AmlValidations)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlvalidations ALTER COLUMN IsPositiveDecision COMMENT 'Final compliance decision: 1=approved (transaction can proceed), 0=rejected (transaction blocked). This is the field that gates transaction execution. (Tier 1 - upstream wiki, WalletDB.Wallet.AmlValidations)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlvalidations ALTER COLUMN CorrelationId COMMENT 'Links this screening to the parent request in Wallet.Requests via CorrelationId. Enables end-to-end tracing of the AML check within the request lifecycle. (Tier 1 - upstream wiki, WalletDB.Wallet.AmlValidations)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlvalidations ALTER COLUMN Created COMMENT 'Timestamp when this screening was performed. (Tier 1 - upstream wiki, WalletDB.Wallet.AmlValidations)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlvalidations ALTER COLUMN BlockchainTransactionId COMMENT 'For receive screenings, the blockchain transaction hash being evaluated. NULL for pre-send screenings (transaction not yet broadcast). (Tier 1 - upstream wiki, WalletDB.Wallet.AmlValidations)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlvalidations ALTER COLUMN DetailsJson COMMENT 'Full JSON response from the AML provider. Contains detailed risk scores, alerts, cluster information, and screening metadata. Used for audit and investigation purposes. (Tier 1 - upstream wiki, WalletDB.Wallet.AmlValidations)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlvalidations ALTER COLUMN CryptoId COMMENT 'The cryptocurrency being transacted. FK to Wallet.CryptoTypes.CryptoID. Determines which AML provider contract is used (via Wallet.AmlProviderContracts). (Tier 1 - upstream wiki, WalletDB.Wallet.AmlValidations)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlvalidations ALTER COLUMN CategoryId COMMENT 'Chainalysis risk category if a risk factor was identified. NULL for clean transactions. Implicit reference to Dictionary.ChainalysisCategoryId. See Chainalysis Category. (Tier 1 - upstream wiki, WalletDB.Wallet.AmlValidations)';

