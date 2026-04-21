-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Dictionary_AccountSubProgram
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountsubprogram
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountsubprogram SET TBLPROPERTIES (
    'comment' = '`eMoney_Dictionary_AccountSubProgram` defines the complete set of fiat product offerings available on the eToro Money platform at sub-program granularity. Each sub-program represents a specific product variant combining an account type (card or IBAN), a tier level (Standard/Green, Premium/Black, Limited), and a geographic region (UK, EU, UAE, AUS, DK). Sub-programs determine the features, limits, and pricing a customer receives. This lookup is sourced from `FiatDwhDB.dbo.SubPrograms` - note the dbo schema, not the Dictionary schema. It expands on `eMoney_Dictionary_AccountProgram` (which only distinguishes card vs IBAN at program level) by providing the full regional and tier breakdown. As of 2026-04-20, the Synapse table has 10 of 16 source rows. The missing 6 sub-programs (IDs 11-16) correspond to Card Green EU, Card Black EU, IBAN Green AUS, IBAN Black AUS, IBAN Green DKK, and IBAN Black DKK - the AUS and European/DK expansions added after the initial Synapse load. Accounts with these sub-programs will ...'
);

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountsubprogram SET TAGS (
    'domain' = 'customer',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountsubprogram ALTER COLUMN `AccountSubProgramID` COMMENT 'Sub-program identifier. Primary key. Referenced by FiatAccount.SubProgramId, EligibilityRules.SubProgramId, ProgramTransitionRules source/destination, and ProgramTransitionsEligibility. DWH note: Synapse currently contains 10 of 16 source values; IDs 11-16 (AUS and DK sub-programs) are in FiatDwhDB source but not yet reflected. (Tier 1 - dbo.SubPrograms)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountsubprogram ALTER COLUMN `AccountSubProgram` COMMENT 'Human-readable sub-program name. Format: "{Type} {Tier} {Region}" (e.g., "Card Premium UK", "IBAN EU Green"). Used in reporting and customer-facing displays. (Tier 1 - dbo.SubPrograms)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountsubprogram ALTER COLUMN `AccountProgramID` COMMENT 'Parent account program: 1=card, 2=iban. See Account Program. (Dictionary.AccountPrograms). Determines the fundamental product type. (Tier 1 - dbo.SubPrograms)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountsubprogram ALTER COLUMN `CUGAccountSubProgram` COMMENT 'Provider-side Closed User Group program identifier. Format: "{Type}_{Tier}_{Region}" (e.g., "Card_Premium_UK"). Used in Tribe API calls and provider configuration. (Tier 1 - dbo.SubPrograms)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountsubprogram ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 - Generic Pipeline)';

-- ---- Column PII Tags ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountsubprogram ALTER COLUMN `AccountSubProgramID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountsubprogram ALTER COLUMN `AccountSubProgram` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountsubprogram ALTER COLUMN `AccountProgramID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountsubprogram ALTER COLUMN `CUGAccountSubProgram` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountsubprogram ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
