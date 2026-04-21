-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Country_Codes_Mapping_ISO
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso SET TBLPROPERTIES (
    'comment' = '`eMoney_Country_Codes_Mapping_ISO` is a manually maintained cross-reference table that maps the full ISO 3166-1 country code standard (248 countries) to eToro DWH dimension IDs. It serves as the bridge between the fiat platform''s use of ISO numeric country codes and the analytical data warehouse country dimension. In the fiat transaction pipeline (`FiatTransactions`), country of transaction is stored as a 3-digit ISO numeric code (`TransactionCountryIso`). This table resolves that numeric code to a 2-letter alpha code (for display), a 3-letter alpha code (for instrument joins), and the DWH internal `eToroDWHCountryID` (for joining to `DWH_dbo.Dim_Country` and applying country-level risk scores). This table is used by two key SPs: `SP_eMoney_DimFact_Transaction` (transaction country resolution for fact table population) and `SP_eMoney_Customer_Risk_Assessment` (High-Risk Country lookups for customer risk scoring). There is no automated refresh - the table was bulk-loaded from the ISO 3166-1 standard on 2024...'
);

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(eToroDWHCountryID)',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso ALTER COLUMN `CountryName` COMMENT 'Full ISO 3166-1 country name (e.g., "United Kingdom of Great Britain and Northern Ireland"). (Tier 2 - SP and manual load context)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso ALTER COLUMN `CountryAlphaTwoCode` COMMENT 'ISO 3166-1 alpha-2 code (2-letter; e.g., GB, US, DE). Used for display and UI rendering. (Tier 2 - SP and manual load context)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso ALTER COLUMN `CountryAlphaThreeCode` COMMENT 'ISO 3166-1 alpha-3 code (3-letter; e.g., GBR, USA, DEU). Used for instrument joins to DWH_dbo.Dim_Instrument. (Tier 2 - SP and manual load context)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso ALTER COLUMN `CountryNumericCode_ISO` COMMENT 'ISO 3166-1 numeric code (3-digit string; e.g., ''826'', ''840'', ''276''). Primary FK from FiatTransactions.TransactionCountryIso. HASH distribution key. (Tier 2 - SP_eMoney_DimFact_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso ALTER COLUMN `eToroDWHCountryID` COMMENT 'eToro DWH internal country dimension ID from DWH_dbo.Dim_Country. Manual mapping bridging ISO numeric to DWH country key. (Tier 2 - SP_eMoney_DimFact_Transaction, SP_eMoney_Customer_Risk_Assessment)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso ALTER COLUMN `UpdateDate` COMMENT 'Bulk-load timestamp. Static; all rows = 2024-06-24. (Tier 2 - Manual load metadata)';

-- ---- Column PII Tags ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso ALTER COLUMN `CountryName` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso ALTER COLUMN `CountryAlphaTwoCode` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso ALTER COLUMN `CountryAlphaThreeCode` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso ALTER COLUMN `CountryNumericCode_ISO` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso ALTER COLUMN `eToroDWHCountryID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
