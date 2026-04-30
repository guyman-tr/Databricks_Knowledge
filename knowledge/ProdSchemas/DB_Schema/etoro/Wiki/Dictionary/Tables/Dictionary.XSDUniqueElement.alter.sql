-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.XSDUniqueElement
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.XSDUniqueElement.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_xsduniqueelement
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_xsduniqueelement (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_xsduniqueelement SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the XPath paths and data types of unique XML elements within payment funding data — used to identify and validate specific fields (card number, email, account ID) when checking for duplicate or unique funding records. Source: etoro.Dictionary.XSDUniqueElement on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.XSDUniqueElement.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_xsduniqueelement SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'XSDUniqueElement',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_xsduniqueelement ALTER COLUMN XSDUniqueElementID COMMENT 'Unique identifier for the XML element definition: 1=CardNumber, 2=Email, 3=AccountID. Referenced by Dictionary.FundingTypeToXSDUniqueElement (mapping which elements apply to each funding type) and Internal.CheckUniqueFundingXMLValue (the uniqueness check function). (Tier 1 - upstream wiki, etoro.Dictionary.XSDUniqueElement)';
ALTER TABLE main.general.bronze_etoro_dictionary_xsduniqueelement ALTER COLUMN Path COMMENT 'XPath expression pointing to the element within the funding XML document (e.g., /Funding[1]/CardNumberAsString[1]). Used in SQL Server''s .value() XML method to extract the element''s value for comparison. Unique constraint (DXSD_PATH) prevents duplicate path definitions. (Tier 1 - upstream wiki, etoro.Dictionary.XSDUniqueElement)';
ALTER TABLE main.general.bronze_etoro_dictionary_xsduniqueelement ALTER COLUMN ElementType COMMENT 'SQL Server data type used when extracting the value via XPath .value(''path'', ''type''). VARCHAR(MAX) for string elements (card numbers, emails), INTEGER for numeric elements (account IDs). Determines the comparison semantics (string vs numeric matching). (Tier 1 - upstream wiki, etoro.Dictionary.XSDUniqueElement)';

