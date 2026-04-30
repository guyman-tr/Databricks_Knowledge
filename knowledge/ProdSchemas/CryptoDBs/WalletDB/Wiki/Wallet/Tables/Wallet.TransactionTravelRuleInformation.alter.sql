-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.TransactionTravelRuleInformation
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation SET TBLPROPERTIES (
    'comment' = 'Stores Travel Rule compliance information for cross-VASP crypto transactions, recording the counterparty address, fiat equivalent amounts, beneficiary address type, and provider message linkage. Source: WalletDB.Wallet.TransactionTravelRuleInformation on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md).'
);

ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'TransactionTravelRuleInformation',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation ALTER COLUMN Id COMMENT 'Auto-incrementing PK. FK target for TransactionTravelRuleStatuses and TransactionTravelRuleBeneficiaryDetails. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionTravelRuleInformation)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation ALTER COLUMN RequestId COMMENT 'Parent request. FK to Wallet.Requests.Id. Links Travel Rule data to the transaction request. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionTravelRuleInformation)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation ALTER COLUMN RequestCorrelationId COMMENT 'Parent request''s CorrelationId for cross-service lookups. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionTravelRuleInformation)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation ALTER COLUMN FiatSymbol COMMENT 'Fiat currency used for threshold calculation (e.g., "USD", "EUR"). (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionTravelRuleInformation)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation ALTER COLUMN FiatAmount COMMENT 'Transaction value in fiat for threshold comparison. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionTravelRuleInformation)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation ALTER COLUMN Occurred COMMENT 'Record creation timestamp. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionTravelRuleInformation)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation ALTER COLUMN FiatRateCalculationTime COMMENT 'When the fiat conversion rate was fetched. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionTravelRuleInformation)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation ALTER COLUMN CounterpartyAddress COMMENT 'Blockchain address of the counterparty (recipient for sends, sender for receives). (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionTravelRuleInformation)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation ALTER COLUMN FiatConversionTime COMMENT 'When the fiat conversion was performed. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionTravelRuleInformation)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation ALTER COLUMN FiatRate COMMENT 'Crypto-to-fiat conversion rate used. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionTravelRuleInformation)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation ALTER COLUMN BeneficiaryAddressType COMMENT 'Whether the counterparty address is "Private" (self-hosted wallet) or "Hosted" (VASP-custodied). Determines compliance requirements. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionTravelRuleInformation)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation ALTER COLUMN ProviderMessageId COMMENT 'Message ID from the Travel Rule provider (e.g., Notabene) for inter-VASP information sharing. (Tier 1 - upstream wiki, WalletDB.Wallet.TransactionTravelRuleInformation)';

