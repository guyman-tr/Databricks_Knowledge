-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.SubPrograms
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.SubPrograms.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_subprograms
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_subprograms (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_subprograms SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the regional and tier-specific fiat sub-programs available on the platform, mapping each to its parent account program and provider-side program name. Source: FiatDwhDB.dbo.SubPrograms on the FiatDwhDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.SubPrograms.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_subprograms SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'SubPrograms',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_subprograms ALTER COLUMN Id COMMENT 'Sub-program identifier. Primary key. Values 1-16 currently defined. Referenced by FiatAccount.SubProgramId, EligibilityRules.SubProgramId, ProgramTransitionRules source/destination, and ProgramTransitionsEligibility. (Tier 1 - upstream wiki, FiatDwhDB.dbo.SubPrograms)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_subprograms ALTER COLUMN Name COMMENT 'Human-readable sub-program name. Format: "{Type} {Tier} {Region}" (e.g., "Card Premium UK", "IBAN EU Green"). Used in reporting and customer-facing displays. (Tier 1 - upstream wiki, FiatDwhDB.dbo.SubPrograms)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_subprograms ALTER COLUMN AccountProgramId COMMENT 'Parent account program: 1=card, 2=iban. See Account Program. (Dictionary.AccountPrograms). Determines the fundamental product type. (Tier 1 - upstream wiki, FiatDwhDB.dbo.SubPrograms)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_subprograms ALTER COLUMN CugProgramName COMMENT 'Provider-side Closed User Group program identifier. Format: "{Type}_{Tier}_{Region}" (e.g., "Card_Premium_UK"). Used in Tribe API calls and provider configuration. (Tier 1 - upstream wiki, FiatDwhDB.dbo.SubPrograms)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_subprograms ALTER COLUMN Region COMMENT 'Geographic region for this sub-program: UK, EU, UAE, AUS, DK. Determines which banking rails, regulations, and currency options apply. NULL would indicate a region-agnostic program (none currently). (Tier 1 - upstream wiki, FiatDwhDB.dbo.SubPrograms)';

