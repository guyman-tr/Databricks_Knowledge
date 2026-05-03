-- =============================================================================
-- Databricks ALTER Script: bronze WalletConversionDB.C2F.ConversionStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.ConversionStatuses.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletconversiondb_c2f_conversionstatuses
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletconversiondb_c2f_conversionstatuses (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_conversionstatuses SET TBLPROPERTIES (
    'comment' = 'Append-only status history for crypto-to-fiat conversions, recording each lifecycle transition with optional error details for audit and debugging. Source: WalletConversionDB.C2F.ConversionStatuses on the WalletConversionDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.ConversionStatuses.md).'
);

ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_conversionstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletConversionDB',
    'source_schema' = 'C2F',
    'source_table' = 'ConversionStatuses',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_conversionstatuses ALTER COLUMN Id COMMENT 'Auto-incrementing PK. Used in correlated subqueries to find the most recent status (ORDER BY Id DESC). Higher Id = more recent transition. (Tier 1 - upstream wiki, WalletConversionDB.C2F.ConversionStatuses)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_conversionstatuses ALTER COLUMN ConversionId COMMENT 'FK to C2F.Conversions.Id. Links each status entry to its parent conversion. Multiple rows per ConversionId (one per transition, typically 2). Indexed for efficient history lookups. (Tier 1 - upstream wiki, WalletConversionDB.C2F.ConversionStatuses)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_conversionstatuses ALTER COLUMN StatusId COMMENT 'FK to Dictionary.ConversionToFiatStatuses. Current status in this transition. Values: 1=Pending, 2=Failed, 3=Completed, 4=Rejected. See Conversion To Fiat Status. Included in NC index on ConversionId for covering queries. (Tier 1 - upstream wiki, WalletConversionDB.C2F.ConversionStatuses)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_conversionstatuses ALTER COLUMN DetailsJson COMMENT 'JSON payload with additional context for this transition. Populated for Failed statuses with error details (e.g., {"ErrorMessage":"Crypto Transaction Failed"}). NULL for Pending and Completed transitions. Set by InsertConversionStatus; empty strings converted to NULL. (Tier 1 - upstream wiki, WalletConversionDB.C2F.ConversionStatuses)';
ALTER TABLE main.bi_db.bronze_walletconversiondb_c2f_conversionstatuses ALTER COLUMN Occurred COMMENT 'UTC timestamp of the status transition. Default constraint auto-sets on insert. Indexed DESC for recency queries. Used by InsertConversionStatus to find the last status (ORDER BY Occurred DESC). (Tier 1 - upstream wiki, WalletConversionDB.C2F.ConversionStatuses)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:40:44 UTC
-- Bronze deploy: WalletConversionDB batch 1
-- ====================
