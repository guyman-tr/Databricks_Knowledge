-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.LimitationsDefinitions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_limitationsdefinitions
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_limitationsdefinitions (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_limitationsdefinitions SET TBLPROPERTIES (
    'comment' = 'Configuration table defining transaction amount limits per cryptocurrency, transaction type, and scope - controlling minimum/maximum thresholds that trigger enforcement or alerting for wallet operations. Source: WalletDB.Wallet.LimitationsDefinitions on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_limitationsdefinitions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'LimitationsDefinitions',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_limitationsdefinitions ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. Referenced by LimitExceeds when recording which rule was breached. (Tier 1 - upstream wiki, WalletDB.Wallet.LimitationsDefinitions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_limitationsdefinitions ALTER COLUMN DefinitionJson COMMENT 'Full structured definition of the limit rule consumed by the evaluation service. Contains threshold values, period windows, and any additional rule parameters not captured in scalar columns. (Tier 1 - upstream wiki, WalletDB.Wallet.LimitationsDefinitions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_limitationsdefinitions ALTER COLUMN LastChanged COMMENT 'UTC timestamp of the most recent modification to this limit definition. Tracks when operations last adjusted this rule. (Tier 1 - upstream wiki, WalletDB.Wallet.LimitationsDefinitions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_limitationsdefinitions ALTER COLUMN LastChangedBy COMMENT 'Identity (username or service account) that last modified this row. Provides an audit trail for limit configuration changes. (Tier 1 - upstream wiki, WalletDB.Wallet.LimitationsDefinitions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_limitationsdefinitions ALTER COLUMN IsActive COMMENT '1=limit rule is currently evaluated; 0=retired/deactivated. Only active rules are applied during transaction validation. (Tier 1 - upstream wiki, WalletDB.Wallet.LimitationsDefinitions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_limitationsdefinitions ALTER COLUMN LimitClassificationId COMMENT 'Enforcement mode: 1=Soft (alert only), 2=Hard (block transaction). FK to Dict.LimitClassifications. (Tier 1 - upstream wiki, WalletDB.Wallet.LimitationsDefinitions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_limitationsdefinitions ALTER COLUMN LimitTypeId COMMENT 'Threshold direction: 1=Min (amount must be >= threshold), 2=Max (amount must be <= threshold). FK to Dict.LimitTypes. (Tier 1 - upstream wiki, WalletDB.Wallet.LimitationsDefinitions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_limitationsdefinitions ALTER COLUMN LimitTargetId COMMENT 'Evaluation scope target: 1=User (per customer), 2=Global (platform-wide). FK to Dict.LimitTargets. (Tier 1 - upstream wiki, WalletDB.Wallet.LimitationsDefinitions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_limitationsdefinitions ALTER COLUMN TransactionTypeId COMMENT 'The transaction type this limit governs. FK to Dict.TransactionTypes (e.g., Send, Receive, Buy). (Tier 1 - upstream wiki, WalletDB.Wallet.LimitationsDefinitions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_limitationsdefinitions ALTER COLUMN CryptoId COMMENT 'Specific cryptocurrency this rule applies to. NULL when rule is defined at category level (see CryptoCategoryName). FK to Wallet.CryptoTypes. (Tier 1 - upstream wiki, WalletDB.Wallet.LimitationsDefinitions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_limitationsdefinitions ALTER COLUMN CryptoCategoryName COMMENT 'Named category of cryptocurrencies this rule applies to (e.g., "Stablecoins"). Used when the rule covers a group rather than a single asset. Mutually exclusive with CryptoId per convention. (Tier 1 - upstream wiki, WalletDB.Wallet.LimitationsDefinitions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_limitationsdefinitions ALTER COLUMN LimitScopeId COMMENT 'Aggregation scope: 1=Single (applies to individual transaction), 2=Periodic (applies to rolling sum over a time window). FK to Dict.LimitScopes. (Tier 1 - upstream wiki, WalletDB.Wallet.LimitationsDefinitions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_limitationsdefinitions ALTER COLUMN LimitActionId COMMENT 'Action taken on breach: 1=Enforce (apply the limit), 2=Alert (notify only). FK to Dict.LimitActions. (Tier 1 - upstream wiki, WalletDB.Wallet.LimitationsDefinitions)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
