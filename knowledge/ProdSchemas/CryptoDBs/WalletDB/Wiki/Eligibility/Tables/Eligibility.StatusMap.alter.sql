-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Eligibility.StatusMap
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.StatusMap.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletdb_eligibility_statusmap
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletdb_eligibility_statusmap (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_walletdb_eligibility_statusmap SET TBLPROPERTIES (
    'comment' = 'Configuration table that resolves a customer''s effective crypto eligibility status by combining the group-level status (country/tier) with the customer-level override status. Source: WalletDB.Eligibility.StatusMap on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.StatusMap.md).'
);

ALTER TABLE main.bi_db.bronze_walletdb_eligibility_statusmap SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Eligibility',
    'source_table' = 'StatusMap',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletdb_eligibility_statusmap ALTER COLUMN Id COMMENT 'Surrogate primary key identifying each unique combination in the resolution matrix. 20 rows total (4 group values x 5 customer values including NULL). Referenced by Eligibility.AllowedUpdateStatusMap via StatusMapId FK. (Tier 1 - upstream wiki, WalletDB.Eligibility.StatusMap)';
ALTER TABLE main.bi_db.bronze_walletdb_eligibility_statusmap ALTER COLUMN GroupValue COMMENT 'Group-level eligibility status derived from the customer''s country, account tier, or other group attributes. FK to Dictionary.EligibilityStatuses: 0=BlockedFromAccess, 1=ReadOnly, 2=AllOperations, 3=AllOperationsForExistingUsersOnly. This is the "AllowedUsingWalletStatus" from InfraSetting, per HLD. See Eligibility Statuses. (Tier 1 - upstream wiki, WalletDB.Eligibility.StatusMap)';
ALTER TABLE main.bi_db.bronze_walletdb_eligibility_statusmap ALTER COLUMN CustomerValue COMMENT 'Customer-level eligibility override, set individually via BackOffice or API. FK to Dictionary.EligibilityStatuses: 0=BlockedFromAccess, 1=ReadOnly, 2=AllOperations, 3=AllOperationsForExistingUsersOnly. NULL means no customer-level override exists - the group status applies directly. Per HLD: "AllowedUsingWalletStatusCustomerLevel." (Tier 1 - upstream wiki, WalletDB.Eligibility.StatusMap)';
ALTER TABLE main.bi_db.bronze_walletdb_eligibility_statusmap ALTER COLUMN Status COMMENT 'Resolved effective eligibility status after applying conflict resolution between GroupValue and CustomerValue. FK to Dictionary.EligibilityStatuses: 0=BlockedFromAccess, 1=ReadOnly, 2=AllOperations, 3=AllOperationsForExistingUsersOnly. This is the final status returned by Eligibility.GetResolvedAllowedUsingWalletStatus and consumed by all services that validate crypto access. (Tier 1 - upstream wiki, WalletDB.Eligibility.StatusMap)';

