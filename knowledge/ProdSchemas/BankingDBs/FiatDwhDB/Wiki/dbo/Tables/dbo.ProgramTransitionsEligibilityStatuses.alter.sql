-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.ProgramTransitionsEligibilityStatuses.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibilitystatuses
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibilitystatuses (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibilitystatuses SET TBLPROPERTIES (
    'comment' = 'Event-sourced status table tracking the outcome of program transition eligibility assessments (Pending, Completed, Rejected, Disabled, Expired). Source: FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.ProgramTransitionsEligibilityStatuses.md).'
);

ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibilitystatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'ProgramTransitionsEligibilityStatuses',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibilitystatuses ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate PK. (Tier 1 - upstream wiki, FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibilitystatuses ALTER COLUMN ProgramTransitionEligibilityId COMMENT 'FK to dbo.ProgramTransitionsEligibility.Id. The eligibility assessment this status belongs to. (Tier 1 - upstream wiki, FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibilitystatuses ALTER COLUMN StatusId COMMENT 'Outcome status: 0=Pending, 1=Completed, 2=Rejected, 3=Disabled, 4=Expired. See Program Transition Eligibility Status. (Dictionary.ProgramTransitionEligibilityStatuses) (Tier 1 - upstream wiki, FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibilitystatuses ALTER COLUMN Created COMMENT 'UTC timestamp when this status was recorded. (Tier 1 - upstream wiki, FiatDwhDB.dbo.ProgramTransitionsEligibilityStatuses)';

