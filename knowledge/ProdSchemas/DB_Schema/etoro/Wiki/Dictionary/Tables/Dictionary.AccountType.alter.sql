-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.AccountType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AccountType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_accounttype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_accounttype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_accounttype SET TBLPROPERTIES (
    'comment' = 'Lookup table classifying eToro accounts by ownership type and purpose, controlling features, regulatory treatment, and fee structures. Source: etoro.Dictionary.AccountType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AccountType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_accounttype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'AccountType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_accounttype ALTER COLUMN AccountTypeID COMMENT 'Primary key identifying the account classification. 1=Private, 2=Corporate, 3=IB Account, 4=Joint, 5=White Label, 6=Affiliate Private, 7=Employee, 8=Custodian, 9=Fund, 10=eToro Group, 11=News, 12=White List, 13=Analyst, 14=SMSF, 15=Affiliate Corporate, 16=Administrated, 17=Funded Employee. Controls feature access, regulatory treatment, fee structures, and compliance monitoring level. See Account Type. (Dictionary.AccountType) (Tier 1 - upstream wiki, etoro.Dictionary.AccountType)';
ALTER TABLE main.general.bronze_etoro_dictionary_accounttype ALTER COLUMN AccountTypeName COMMENT 'Human-readable label for the account type. Used in BackOffice UI, compliance reporting, and DWH exports. UNIQUE constraint ensures no duplicate names. (Tier 1 - upstream wiki, etoro.Dictionary.AccountType)';

