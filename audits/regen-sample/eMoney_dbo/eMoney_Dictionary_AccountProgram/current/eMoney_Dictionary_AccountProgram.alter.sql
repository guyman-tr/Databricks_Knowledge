-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Dictionary_AccountProgram
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountprogram
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountprogram SET TBLPROPERTIES (
    'comment' = '`eMoney_Dictionary_AccountProgram` is a lookup/reference table that defines the valid values for account program type in the eToro Money fiat platform. Each row maps an integer ID to a human-readable program name. The two active programs - **card** (physical/virtual debit card) and **iban** (IBAN bank account) - represent the fundamental product types offered by eToro Money. The `Unknown` (0) sentinel covers legacy or unclassified accounts. This dictionary is sourced directly from `FiatDwhDB.Dictionary.AccountPrograms` via the Generic Pipeline Bronze export and materialized into Synapse DWH. It is referenced by `eMoney_Dim_Account.AccountProgramID`, `eMoney_Dictionary_AccountSubProgram.AccountProgramID`, and downstream analytics tables throughout `eMoney_dbo`. The table is effectively static - the last UpdateDate is 2023-06-12. Synapse: REPLICATE, HEAP.'
);

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountprogram SET TAGS (
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
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountprogram ALTER COLUMN `AccountProgramID` COMMENT 'Lookup identifier. Primary key. 0=Unknown, 1=card, 2=iban. (Tier 1 - Dictionary.AccountPrograms)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountprogram ALTER COLUMN `AccountProgram` COMMENT 'Human-readable name for this value. 0=Unknown, 1=card, 2=iban. (Tier 1 - Dictionary.AccountPrograms)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountprogram ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 - Generic Pipeline)';

-- ---- Column PII Tags ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountprogram ALTER COLUMN `AccountProgramID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountprogram ALTER COLUMN `AccountProgram` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountprogram ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
