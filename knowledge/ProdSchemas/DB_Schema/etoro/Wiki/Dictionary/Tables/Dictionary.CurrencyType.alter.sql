-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CurrencyType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CurrencyType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_currencytype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_currencytype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_currencytype SET TBLPROPERTIES (
    'comment' = 'Lookup table classifying tradeable instruments into asset classes (Forex, Stocks, Crypto, etc.), controlling trading rules, minimum position sizes, price sources, and UI presentation. Source: etoro.Dictionary.CurrencyType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CurrencyType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_currencytype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CurrencyType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_currencytype ALTER COLUMN CurrencyTypeID COMMENT 'Primary key identifying the asset class. 1=Forex, 2=Commodity, 3=CFD (legacy), 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. Foreign key in Dictionary.Currency. See Currency Type. (Dictionary.CurrencyType) (Tier 1 - upstream wiki, etoro.Dictionary.CurrencyType)';
ALTER TABLE main.general.bronze_etoro_dictionary_currencytype ALTER COLUMN Name COMMENT 'Human-readable asset class label. UNIQUE constraint. Used in UI category tabs, reporting, and API responses. (Tier 1 - upstream wiki, etoro.Dictionary.CurrencyType)';
ALTER TABLE main.general.bronze_etoro_dictionary_currencytype ALTER COLUMN MinPositionAmountAbsolute COMMENT 'Minimum trade size in account currency (absolute amount, not percentage). Enforced at order entry time. Ranges from $10 (Stocks, ETF, Crypto) to $200 (Indices). Zero for inactive asset classes. (Tier 1 - upstream wiki, etoro.Dictionary.CurrencyType)';
ALTER TABLE main.general.bronze_etoro_dictionary_currencytype ALTER COLUMN Priority COMMENT 'Display sort order in the platform''s asset class navigation tabs. Lower number = higher priority (Stocks=1 appears first). NULL for inactive/legacy asset classes not shown in UI. (Tier 1 - upstream wiki, etoro.Dictionary.CurrencyType)';
ALTER TABLE main.general.bronze_etoro_dictionary_currencytype ALTER COLUMN PricesBy COMMENT 'Price feed provider name. "eToro" for internally-sourced prices (Forex, Commodity, Indices, Crypto). "Xignite" for externally-sourced equity prices (Stocks, ETF). NULL for inactive asset classes. (Tier 1 - upstream wiki, etoro.Dictionary.CurrencyType)';
ALTER TABLE main.general.bronze_etoro_dictionary_currencytype ALTER COLUMN SLTPApproachPercent COMMENT 'Minimum distance between current price and SL/TP levels, expressed as a percentage. 0.10% for Forex (tight stops allowed), 1.00% for most others. NULL for inactive asset classes. Enforced in order validation. (Tier 1 - upstream wiki, etoro.Dictionary.CurrencyType)';
ALTER TABLE main.general.bronze_etoro_dictionary_currencytype ALTER COLUMN ImageUrl COMMENT 'CDN URL for the asset class avatar/icon displayed in the mobile and web UI. Points to etoro-cdn.etorostatic.com. NULL for inactive asset classes. (Tier 1 - upstream wiki, etoro.Dictionary.CurrencyType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
