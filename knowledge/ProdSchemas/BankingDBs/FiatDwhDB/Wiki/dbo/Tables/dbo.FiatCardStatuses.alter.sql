-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.FiatCardStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardStatuses.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiatcardstatuses
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiatcardstatuses (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcardstatuses SET TBLPROPERTIES (
    'comment' = 'Event-sourced status history table tracking all card lifecycle changes (NotActivated, Activated, Blocked, Suspended, Risk, Stolen, Lost, Expired, Fraud) for each card and card instance. Source: FiatDwhDB.dbo.FiatCardStatuses on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardStatuses.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcardstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'FiatCardStatuses',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcardstatuses ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate PK. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCardStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcardstatuses ALTER COLUMN CardId COMMENT 'FK to dbo.FiatCards.Id. The logical card whose status changed. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCardStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcardstatuses ALTER COLUMN CardStatusId COMMENT 'Status: 0-8. See Card Status. (Dictionary.CardStatuses) (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCardStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcardstatuses ALTER COLUMN ExpirationDate COMMENT 'Card expiration date at the time of this status event. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCardStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcardstatuses ALTER COLUMN EventTimestamp COMMENT 'When the status change occurred in the source system. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCardStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcardstatuses ALTER COLUMN Created COMMENT 'When this record was written to the DWH. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCardStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcardstatuses ALTER COLUMN CardInstanceId COMMENT 'Implicit ref to dbo.FiatCardInstances.Id. Which physical/virtual card instance this status applies to. Default 0 for legacy records pre-migration. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCardStatuses)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:05:44 UTC
-- Bronze deploy: FiatDwhDB batch 1
-- ====================
