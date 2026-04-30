-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Regulation
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Regulation.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_regulation
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_regulation (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_regulation SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the financial regulatory authorities under which eToro entities operate, controlling compliance rules, leverage limits, instrument availability, and legal jurisdiction. Source: etoro.Dictionary.Regulation on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Regulation.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_regulation SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Regulation',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_regulation ALTER COLUMN ID COMMENT 'Primary key identifying the regulatory authority. 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. Stored in Customer.CustomerStatic.RegulationID. See Regulation. (Dictionary.Regulation) (Tier 1 - upstream wiki, etoro.Dictionary.Regulation)';
ALTER TABLE main.general.bronze_etoro_dictionary_regulation ALTER COLUMN Name COMMENT 'Short code for the regulation. Used in code branching (CASE WHEN RegulationName = ''CySEC''), logging, and API responses. (Tier 1 - upstream wiki, etoro.Dictionary.Regulation)';
ALTER TABLE main.general.bronze_etoro_dictionary_regulation ALTER COLUMN IsUSA COMMENT 'Whether this regulation governs US users. 1=US jurisdiction (affects instrument availability, tax forms, leverage), 0=non-US. Used as a primary branch in business logic across Trading, Billing, and Compliance schemas. (Tier 1 - upstream wiki, etoro.Dictionary.Regulation)';
ALTER TABLE main.general.bronze_etoro_dictionary_regulation ALTER COLUMN JurisdictionName COMMENT 'The eToro legal entity name for this jurisdiction (e.g., "eToro EU", "eToro UK", "eToro AUS"). NULL for regulations without a dedicated legal entity. Used in legal documents, terms & conditions, and regulatory disclosures. (Tier 1 - upstream wiki, etoro.Dictionary.Regulation)';
ALTER TABLE main.general.bronze_etoro_dictionary_regulation ALTER COLUMN BankID COMMENT 'FK to Dictionary.Bank — the banking partner for client fund custody under this regulation. NULL when the custodian is managed externally or not yet assigned. See Dictionary.Bank. (Tier 1 - upstream wiki, etoro.Dictionary.Regulation)';
ALTER TABLE main.general.bronze_etoro_dictionary_regulation ALTER COLUMN RegulationLongName COMMENT 'Full formal name of the regulatory authority (e.g., "Cyprus Securities Exchange Commission (CySEC)"). Used in legal disclosures, terms & conditions, and regulatory filings. (Tier 1 - upstream wiki, etoro.Dictionary.Regulation)';
ALTER TABLE main.general.bronze_etoro_dictionary_regulation ALTER COLUMN RegulationShortName COMMENT 'Abbreviated regulatory name for compact display (e.g., "CySEC", "FCA", "MSB"). Used in UI badges, compliance dashboards, and compact reporting. (Tier 1 - upstream wiki, etoro.Dictionary.Regulation)';
ALTER TABLE main.general.bronze_etoro_dictionary_regulation ALTER COLUMN DefaultRegulationID COMMENT 'Self-reference to Dictionary.Regulation — the fallback regulation when this regulation cannot process a specific operation. Non-US → BVI (5), US → eToroUS (6). Used in edge cases where the primary regulation has restrictions. (Tier 1 - upstream wiki, etoro.Dictionary.Regulation)';

