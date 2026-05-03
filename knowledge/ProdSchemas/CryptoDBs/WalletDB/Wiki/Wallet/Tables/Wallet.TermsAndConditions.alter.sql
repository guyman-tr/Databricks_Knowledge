-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.TermsAndConditions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TermsAndConditions.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletdb_wallet_termsandconditions
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletdb_wallet_termsandconditions (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_walletdb_wallet_termsandconditions SET TBLPROPERTIES (
    'comment' = 'Version-controlled registry of Terms and Conditions documents that customers must accept before using the crypto wallet, with associated legal links and configuration per legal entity type. Source: WalletDB.Wallet.TermsAndConditions on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TermsAndConditions.md).'
);

ALTER TABLE main.bi_db.bronze_walletdb_wallet_termsandconditions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'TermsAndConditions',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletdb_wallet_termsandconditions ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. Referenced by Wallet.CustomerTermsAndConditions to record which version a user accepted. (Tier 1 - upstream wiki, WalletDB.Wallet.TermsAndConditions)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_termsandconditions ALTER COLUMN Version COMMENT 'Version identifier string (e.g., "V1", "V2", "V3"). Combined with TypeId forms a unique business key. Sequential versioning allows easy comparison of acceptance currency. (Tier 1 - upstream wiki, WalletDB.Wallet.TermsAndConditions)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_termsandconditions ALTER COLUMN Url COMMENT 'URL to the PDF document containing the full T&C text. Hosted on eToro domains (etorox.com, etoro.com). Used to present the document to users for review before acceptance. (Tier 1 - upstream wiki, WalletDB.Wallet.TermsAndConditions)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_termsandconditions ALTER COLUMN Occured COMMENT 'Timestamp when this T&C version was published/inserted. Note: column name contains a typo ("Occured" instead of "Occurred"). Used to determine the chronological order of T&C versions. (Tier 1 - upstream wiki, WalletDB.Wallet.TermsAndConditions)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_termsandconditions ALTER COLUMN TypeId COMMENT 'Legal entity type identifier that scopes this T&C version. Different eToro entities (eToroX, eToroUS, eToroEU, etc.) may have jurisdiction-specific terms. Part of unique constraint with Version. Implicit reference to the eToro legal entity system. (Tier 1 - upstream wiki, WalletDB.Wallet.TermsAndConditions)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_termsandconditions ALTER COLUMN LinksJson COMMENT 'JSON object containing associated legal links: feesAndLimitsUrl, termsOfUseUrl, sendTransactionWarningLink, customerSupport. These links are displayed in the wallet UI alongside the T&C acceptance prompt. Schema is consistent across versions. (Tier 1 - upstream wiki, WalletDB.Wallet.TermsAndConditions)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_termsandconditions ALTER COLUMN ValidFrom COMMENT 'System-versioned temporal column (HIDDEN). Automatically set by SQL Server when a row is inserted or updated. Marks the start of this row version''s validity period. (Tier 1 - upstream wiki, WalletDB.Wallet.TermsAndConditions)';
ALTER TABLE main.bi_db.bronze_walletdb_wallet_termsandconditions ALTER COLUMN ValidTo COMMENT 'System-versioned temporal column (HIDDEN). Automatically set by SQL Server when a row is superseded by an update. Default value indicates the row is currently active. (Tier 1 - upstream wiki, WalletDB.Wallet.TermsAndConditions)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
