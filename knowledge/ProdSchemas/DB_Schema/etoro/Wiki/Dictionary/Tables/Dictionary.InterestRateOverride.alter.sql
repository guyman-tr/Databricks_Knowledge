-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.InterestRateOverride
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_dictionary_interestrateoverride
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_dictionary_interestrateoverride (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_dictionary_interestrateoverride SET TBLPROPERTIES (
    'comment' = 'System-versioned configuration table defining manual overrides to overnight interest (swap) rates — allowing operations to customize buy/sell rates and markup percentages at the instrument, exchange, or instrument-type level with full temporal audit history. Source: etoro.Dictionary.InterestRateOverride on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRateOverride.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_dictionary_interestrateoverride SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'InterestRateOverride',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_dictionary_interestrateoverride ALTER COLUMN InterestRateOverrideID COMMENT 'Auto-incrementing primary key. Uniquely identifies each override rule. Referenced by Trade.UpdateInterestRateOverride and Trade.DeleteInterestRateOverride. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_interestrateoverride ALTER COLUMN InstrumentID COMMENT 'Specific instrument to override (most specific level). NULL when override targets an exchange or type. FK to Dictionary.Currency.InstrumentID. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_interestrateoverride ALTER COLUMN ExchangeID COMMENT 'Exchange to override (mid-level specificity). NULL when override targets a specific instrument or type. FK to Dictionary.ExchangeInfo. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_interestrateoverride ALTER COLUMN InstrumentTypeID COMMENT 'Instrument type to override (broadest level). NULL when override targets a specific instrument or exchange. FK to Dictionary.CurrencyType. 1=Forex, 2=Commodities, 3=Indices, 4=Indices, 5=Stocks, 10=Crypto. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_interestrateoverride ALTER COLUMN UpdatedByUser COMMENT 'Username of the operations staff member who created or last modified this override. Used for audit trail and accountability. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_interestrateoverride ALTER COLUMN InterestRateBuy COMMENT 'Base overnight interest rate for long (buy) positions. Positive = customer pays, negative = customer receives. Combined with MarkupBuy for final rate. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_interestrateoverride ALTER COLUMN InterestRateSell COMMENT 'Base overnight interest rate for short (sell) positions. Positive = customer pays, negative = customer receives. Combined with MarkupSell for final rate. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_interestrateoverride ALTER COLUMN MarkupBuy COMMENT 'eToro''s markup percentage on the buy (long) overnight rate. Added to InterestRateBuy to determine the customer-facing rate. Represents eToro''s revenue component. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_interestrateoverride ALTER COLUMN MarkupSell COMMENT 'eToro''s markup percentage on the sell (short) overnight rate. Added to InterestRateSell to determine the customer-facing rate. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_interestrateoverride ALTER COLUMN BeginTime COMMENT 'System-versioned row start time. Generated automatically by SQL Server. Indicates when this version of the override became active. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_interestrateoverride ALTER COLUMN EndTime COMMENT 'System-versioned row end time. Generated automatically. Current rows have 9999-12-31 23:59:59.999. Historical rows have the timestamp of the next modification. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_interestrateoverride ALTER COLUMN OverNightFeePatternID COMMENT 'Fee charging pattern for this override. FK to Dictionary.OverNightFeePattern. Determines on which days/how fees are charged (e.g., daily, triple Wednesday, weekday-only). NULL = use default pattern. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_interestrateoverride ALTER COLUMN SettlementTypeID COMMENT 'Settlement model for this override. FK to Dictionary.SettlementTypes. 0=default/any, 1=CFD, 2=Real, 3=DMA, 4=Indices, 5=TRS. Allows different rates per settlement type. Default: 0. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRateOverride)';

