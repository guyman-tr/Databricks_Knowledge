-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.FundingTypeToXSDUniqueElement
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FundingTypeToXSDUniqueElement.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_fundingtypetoxsduniqueelement
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_fundingtypetoxsduniqueelement (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtypetoxsduniqueelement SET TBLPROPERTIES (
    'comment' = 'Many-to-many mapping table linking payment funding types to their unique XML element paths — defines which XSD field uniquely identifies a payment method within each funding type''s XML data structure. Source: etoro.Dictionary.FundingTypeToXSDUniqueElement on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FundingTypeToXSDUniqueElement.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_fundingtypetoxsduniqueelement SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'FundingTypeToXSDUniqueElement',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtypetoxsduniqueelement ALTER COLUMN FundingTypeID COMMENT 'FK to Dictionary.FundingType identifying the payment method category (1=Credit Card, 3=PayPal, 6/7=Bank transfer types, 8=email-based type). Part of composite PK. Determines which payment method category this uniqueness mapping applies to. (Tier 1 - upstream wiki, etoro.Dictionary.FundingTypeToXSDUniqueElement)';
ALTER TABLE main.general.bronze_etoro_dictionary_fundingtypetoxsduniqueelement ALTER COLUMN XSDUniqueElementID COMMENT 'FK to Dictionary.XSDUniqueElement identifying the XPath and data type of the unique field within the funding XML. Part of composite PK. Maps to XPath expressions like /Funding[1]/CardNumberAsString[1] that the system extracts to check for duplicates. (Dictionary.XSDUniqueElement) (Tier 1 - upstream wiki, etoro.Dictionary.FundingTypeToXSDUniqueElement)';

