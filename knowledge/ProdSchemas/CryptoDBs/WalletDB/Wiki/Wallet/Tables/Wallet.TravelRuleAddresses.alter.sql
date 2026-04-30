-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.TravelRuleAddresses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_travelruleaddresses
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_travelruleaddresses (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelruleaddresses SET TBLPROPERTIES (
    'comment' = 'Stores whitelisted external addresses for Travel Rule compliance, recording the beneficiary''s address type (private/hosted), hosting company, and personal details with dynamic data masking for PII protection. Source: WalletDB.Wallet.TravelRuleAddresses on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_travelruleaddresses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'TravelRuleAddresses',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelruleaddresses ALTER COLUMN Id COMMENT 'Auto-incrementing PK. FK target for Wallet.TravelRuleSends. (Tier 1 - upstream wiki, WalletDB.Wallet.TravelRuleAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelruleaddresses ALTER COLUMN WalletId COMMENT 'Customer wallet this address belongs to. FK to Wallet.WalletPool.WalletId. (Tier 1 - upstream wiki, WalletDB.Wallet.TravelRuleAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelruleaddresses ALTER COLUMN ToAddress COMMENT 'The whitelisted external blockchain address. (Tier 1 - upstream wiki, WalletDB.Wallet.TravelRuleAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelruleaddresses ALTER COLUMN TravelRuleAddressTypeId COMMENT 'Address type: 1=Private (self-hosted), 2=Hosted (VASP). See Travel Rule Address Type. FK to Dictionary.TravelRuleAddressType. (Tier 1 - upstream wiki, WalletDB.Wallet.TravelRuleAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelruleaddresses ALTER COLUMN SelfAccount COMMENT 'Whether the beneficiary is the same person as the sender: 1=self-transfer, 0=third-party transfer. Affects compliance requirements. (Tier 1 - upstream wiki, WalletDB.Wallet.TravelRuleAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelruleaddresses ALTER COLUMN HostingCompany COMMENT 'Name of the VASP hosting the destination address (from Wallet.HostingCompanies list). NULL for private/self-hosted addresses. (Tier 1 - upstream wiki, WalletDB.Wallet.TravelRuleAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelruleaddresses ALTER COLUMN Name COMMENT 'Beneficiary''s full name. MASKED for PII protection. NULL for self-transfers. (Tier 1 - upstream wiki, WalletDB.Wallet.TravelRuleAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelruleaddresses ALTER COLUMN CountryAlpha3Code COMMENT 'Beneficiary''s country (ISO 3166 alpha-3). MASKED. (Tier 1 - upstream wiki, WalletDB.Wallet.TravelRuleAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelruleaddresses ALTER COLUMN State COMMENT 'Beneficiary''s state/province. MASKED. (Tier 1 - upstream wiki, WalletDB.Wallet.TravelRuleAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelruleaddresses ALTER COLUMN City COMMENT 'Beneficiary''s city. MASKED. (Tier 1 - upstream wiki, WalletDB.Wallet.TravelRuleAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelruleaddresses ALTER COLUMN Address COMMENT 'Beneficiary''s street address. MASKED. (Tier 1 - upstream wiki, WalletDB.Wallet.TravelRuleAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelruleaddresses ALTER COLUMN Zipcode COMMENT 'Beneficiary''s postal code. MASKED. (Tier 1 - upstream wiki, WalletDB.Wallet.TravelRuleAddresses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_travelruleaddresses ALTER COLUMN Created COMMENT 'Timestamp when this address was whitelisted. (Tier 1 - upstream wiki, WalletDB.Wallet.TravelRuleAddresses)';

