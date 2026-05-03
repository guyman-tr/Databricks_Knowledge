-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.ProgramTransitionsEligibility
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.ProgramTransitionsEligibility.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibility
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibility (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibility SET TBLPROPERTIES (
    'comment' = 'Tracks customer eligibility for program transitions (sub-program upgrades/downgrades), recording the source, destination, and triggering context for each eligibility assessment. Source: FiatDwhDB.dbo.ProgramTransitionsEligibility on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.ProgramTransitionsEligibility.md).'
);

ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibility SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'ProgramTransitionsEligibility',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibility ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, FiatDwhDB.dbo.ProgramTransitionsEligibility)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibility ALTER COLUMN AccountId COMMENT 'FK to dbo.FiatAccount.Id. The account being assessed for transition. (Tier 1 - upstream wiki, FiatDwhDB.dbo.ProgramTransitionsEligibility)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibility ALTER COLUMN Gcid COMMENT 'Global Customer ID. Denormalized from FiatAccount for efficient querying. (Tier 1 - upstream wiki, FiatDwhDB.dbo.ProgramTransitionsEligibility)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibility ALTER COLUMN SourceSubProgramId COMMENT 'Current sub-program the customer is in. FK to dbo.SubPrograms. See Sub-Program. (Tier 1 - upstream wiki, FiatDwhDB.dbo.ProgramTransitionsEligibility)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibility ALTER COLUMN DestinationSubProgramId COMMENT 'Target sub-program the customer would move to. FK to dbo.SubPrograms. (Tier 1 - upstream wiki, FiatDwhDB.dbo.ProgramTransitionsEligibility)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibility ALTER COLUMN SourceId COMMENT 'How eligibility was determined: 0=Unknown, 1=UserAPI, 2=Manual. See Program Transition Eligibility Source. Live data also shows value 4 (extended/undocumented). (Tier 1 - upstream wiki, FiatDwhDB.dbo.ProgramTransitionsEligibility)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibility ALTER COLUMN Created COMMENT 'UTC timestamp when this eligibility record was created. (Tier 1 - upstream wiki, FiatDwhDB.dbo.ProgramTransitionsEligibility)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibility ALTER COLUMN CorrelationId COMMENT 'Unique ID linking this eligibility assessment to the triggering business operation. Enables distributed tracing. (Tier 1 - upstream wiki, FiatDwhDB.dbo.ProgramTransitionsEligibility)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dbo_programtransitionseligibility ALTER COLUMN PlatformId COMMENT 'Platform context identifier. Links to the platform instance where the eligibility was assessed. (Tier 1 - upstream wiki, FiatDwhDB.dbo.ProgramTransitionsEligibility)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:05:44 UTC
-- Bronze deploy: FiatDwhDB batch 1
-- ====================
