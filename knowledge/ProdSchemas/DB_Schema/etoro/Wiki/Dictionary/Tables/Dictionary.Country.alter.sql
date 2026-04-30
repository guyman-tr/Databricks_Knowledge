-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Country
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_country
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_country (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_country SET TBLPROPERTIES (
    'comment' = 'Master reference table defining all 251 countries/territories with their geographic, localization, regulatory, marketing, and risk classification attributes. Source: etoro.Dictionary.Country on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_country SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Country',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_country ALTER COLUMN CountryID COMMENT 'Primary key. 0=Not available (fallback), 1-250=countries ordered roughly alphabetically. Referenced by Customer.CustomerStatic.CountryID, Dictionary.CountryBin6/8.CountryID, Dictionary.CountryToCountryGroup.CountryID, and 30+ procedures. (Tier 1 - upstream wiki, etoro.Dictionary.Country)';
ALTER TABLE main.general.bronze_etoro_dictionary_country ALTER COLUMN RegionID COMMENT 'FK to Dictionary.Region. Geographic region for analytics and default currency inheritance. 23 distinct values used. 0=Unknown (default). (Tier 1 - upstream wiki, etoro.Dictionary.Country)';
ALTER TABLE main.general.bronze_etoro_dictionary_country ALTER COLUMN DefaultCurrencyID COMMENT 'FK to Dictionary.Currency. The default trading account currency assigned to new users from this country. 6 distinct values: 1=USD (most), 2=EUR (Europe), 3=GBP (UK), 5=AUD (Australia), 7=CAD (Canada), 86=PLN (Poland). Permanent — cannot be changed after registration. (Tier 1 - upstream wiki, etoro.Dictionary.Country)';
ALTER TABLE main.general.bronze_etoro_dictionary_country ALTER COLUMN LanguageID COMMENT 'FK to Dictionary.Language. Default UI language for new users from this country. 11 distinct values. English is the most common default. User can change post-registration. (Tier 1 - upstream wiki, etoro.Dictionary.Country)';
ALTER TABLE main.general.bronze_etoro_dictionary_country ALTER COLUMN Abbreviation COMMENT 'ISO 3166-1 alpha-2 country code (e.g., "US", "GB", "DE"). UNIQUE constraint. Used in UI display, API parameters, and geolocation matching. (Tier 1 - upstream wiki, etoro.Dictionary.Country)';
ALTER TABLE main.general.bronze_etoro_dictionary_country ALTER COLUMN LongAbbreviation COMMENT 'ISO 3166-1 alpha-3 country code (e.g., "USA", "GBR", "DEU"). UNIQUE constraint. Used in some international reporting standards. (Tier 1 - upstream wiki, etoro.Dictionary.Country)';
ALTER TABLE main.general.bronze_etoro_dictionary_country ALTER COLUMN Name COMMENT 'Full country name in English. UNIQUE constraint. Used in UI dropdowns, reports, and compliance documents. (Tier 1 - upstream wiki, etoro.Dictionary.Country)';
ALTER TABLE main.general.bronze_etoro_dictionary_country ALTER COLUMN PhonePrefix COMMENT 'International dialing code (e.g., "1" for US, "44" for UK, "972" for Israel). NULL for some territories. Used for phone verification and SMS routing. (Tier 1 - upstream wiki, etoro.Dictionary.Country)';
ALTER TABLE main.general.bronze_etoro_dictionary_country ALTER COLUMN IsActive COMMENT 'Whether this country is currently active on the platform. 250 active, 1 inactive (CountryID=0). Inactive countries are hidden from registration but retained for existing users. (Tier 1 - upstream wiki, etoro.Dictionary.Country)';
ALTER TABLE main.general.bronze_etoro_dictionary_country ALTER COLUMN IsHighRiskCountry COMMENT 'AML/compliance risk flag. 0=standard (237 countries), 1=high-risk (14 countries). Triggers enhanced due diligence, additional document requirements, and stricter transaction monitoring. (Tier 1 - upstream wiki, etoro.Dictionary.Country)';
ALTER TABLE main.general.bronze_etoro_dictionary_country ALTER COLUMN IsEligibleForRAFBonusCountry COMMENT 'Whether users from this country can participate in the Refer-A-Friend bonus program. Default=1 (eligible). Set to 0 where regulatory or fraud patterns prohibit bonuses. (Tier 1 - upstream wiki, etoro.Dictionary.Country)';
ALTER TABLE main.general.bronze_etoro_dictionary_country ALTER COLUMN MarketingRegionID COMMENT 'FK to Dictionary.MarketingRegion. Segments countries for marketing campaigns. Distinct from geographic Region — MarketingRegion groups by marketing strategy (e.g., "Arabic" cuts across Asia/Africa regions). (Tier 1 - upstream wiki, etoro.Dictionary.Country)';
ALTER TABLE main.general.bronze_etoro_dictionary_country ALTER COLUMN RiskGroupID COMMENT 'FK to Dictionary.CountryRiskGroup. Granular risk classification: 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit. More nuanced than the binary IsHighRiskCountry flag. (Tier 1 - upstream wiki, etoro.Dictionary.Country)';
ALTER TABLE main.general.bronze_etoro_dictionary_country ALTER COLUMN EconomicTypeID COMMENT 'FK to Dictionary.CountryEconomicType. Economic classification of the country. 0=default (unclassified for most countries). (Tier 1 - upstream wiki, etoro.Dictionary.Country)';
ALTER TABLE main.general.bronze_etoro_dictionary_country ALTER COLUMN IsSettlementRestricted COMMENT 'Whether users from this country are restricted to CFD-only trading (cannot hold REAL assets). 21 countries restricted. Most notable: United States. Overrides instrument-level settlement availability. (Tier 1 - upstream wiki, etoro.Dictionary.Country)';
ALTER TABLE main.general.bronze_etoro_dictionary_country ALTER COLUMN IsoCode COMMENT 'ISO 3166-1 numeric country code (e.g., "840" for US, "826" for UK). Used for international financial reporting (SWIFT, FATCA). NULL for some territories. (Tier 1 - upstream wiki, etoro.Dictionary.Country)';

