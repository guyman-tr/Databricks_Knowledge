-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.AmlProviderUsers
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlProviderUsers.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_amlproviderusers
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_amlproviderusers (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlproviderusers SET TBLPROPERTIES (
    'comment' = 'Maps customers to their user identity on AML screening providers (Chainalysis), enabling per-user AML screening and risk profile tracking across blockchain analytics services. Source: WalletDB.Wallet.AmlProviderUsers on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlProviderUsers.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_amlproviderusers SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'AmlProviderUsers',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlproviderusers ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, WalletDB.Wallet.AmlProviderUsers)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlproviderusers ALTER COLUMN AmlProviderId COMMENT 'The AML screening provider this registration is for: 1=Chainalysis, 4=ChainalysisCDN. See AML Provider. FK to Dictionary.AmlProviders. (Tier 1 - upstream wiki, WalletDB.Wallet.AmlProviderUsers)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlproviderusers ALTER COLUMN Gcid COMMENT 'Global Customer ID. The eToro customer this AML provider registration belongs to. Part of unique constraint with AmlProviderId. (Tier 1 - upstream wiki, WalletDB.Wallet.AmlProviderUsers)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlproviderusers ALTER COLUMN ProviderUserId COMMENT 'The customer''s user identifier on the AML provider''s system. Base64-encoded representation of the Gcid (e.g., Gcid 46870594 -> "NDY4NzA1OTQ="). Used in all API calls to the provider. (Tier 1 - upstream wiki, WalletDB.Wallet.AmlProviderUsers)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_amlproviderusers ALTER COLUMN Occurred COMMENT 'Timestamp when this customer was first registered with the AML provider. (Tier 1 - upstream wiki, WalletDB.Wallet.AmlProviderUsers)';

