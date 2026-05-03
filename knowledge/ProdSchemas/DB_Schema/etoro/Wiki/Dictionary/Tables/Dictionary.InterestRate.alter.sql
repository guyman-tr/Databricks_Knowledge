-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.InterestRate
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRate.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_interestrate
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_interestrate (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_interestrate SET TBLPROPERTIES (
    'comment' = 'System-versioned configuration table storing overnight interest/swap rates per currency, instrument type, and settlement model - the core rate data driving daily position financing charges. Source: etoro.Dictionary.InterestRate on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.InterestRate.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_interestrate SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'InterestRate',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_interestrate ALTER COLUMN InterestRateID COMMENT 'Currency identifier for the rate. Maps to a currency: 1=USD, 2=EUR, 3=GBP, 4=CHF, 10=AUD, 12=JPY, etc. Part of composite PK. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRate)';
ALTER TABLE main.general.bronze_etoro_dictionary_interestrate ALTER COLUMN InterestRateName COMMENT 'Human-readable currency label: "IR USD", "IR EUR", "IR GBP", etc. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRate)';
ALTER TABLE main.general.bronze_etoro_dictionary_interestrate ALTER COLUMN InterestRate COMMENT 'Legacy single rate field, retained for backward compatibility. Set to 0 in current records - superseded by InterestRateBuy/Sell split. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRate)';
ALTER TABLE main.general.bronze_etoro_dictionary_interestrate ALTER COLUMN UpdatedByUser COMMENT 'Username of the person or service that last modified this rate. Audit trail for rate changes. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRate)';
ALTER TABLE main.general.bronze_etoro_dictionary_interestrate ALTER COLUMN BeginTime COMMENT 'Temporal row start - GENERATED ALWAYS AS ROW START. When this rate version became effective. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRate)';
ALTER TABLE main.general.bronze_etoro_dictionary_interestrate ALTER COLUMN EndTime COMMENT 'Temporal row end - GENERATED ALWAYS AS ROW END. Active rates have 9999-12-31. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRate)';
ALTER TABLE main.general.bronze_etoro_dictionary_interestrate ALTER COLUMN InstrumentTypeID COMMENT 'Instrument type this rate applies to: 4=CFD, 5=Stock/Real, 6=Crypto, etc. Part of composite PK. Same currency can have different rates per instrument type. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRate)';
ALTER TABLE main.general.bronze_etoro_dictionary_interestrate ALTER COLUMN InterestRateBuy COMMENT 'Base overnight rate for long (buy) positions. Positive=customer pays, negative=customer earns swap credit. Combined with MarkupBuy for total customer rate. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRate)';
ALTER TABLE main.general.bronze_etoro_dictionary_interestrate ALTER COLUMN InterestRateSell COMMENT 'Base overnight rate for short (sell) positions. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRate)';
ALTER TABLE main.general.bronze_etoro_dictionary_interestrate ALTER COLUMN MarkupBuy COMMENT 'Broker markup added to InterestRateBuy. Total buy rate = InterestRateBuy + MarkupBuy. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRate)';
ALTER TABLE main.general.bronze_etoro_dictionary_interestrate ALTER COLUMN MarkupSell COMMENT 'Broker markup added to InterestRateSell. Total sell rate = InterestRateSell + MarkupSell. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRate)';
ALTER TABLE main.general.bronze_etoro_dictionary_interestrate ALTER COLUMN OverNightFeePatternID COMMENT 'Fee calculation pattern: 0=Regular (leveraged-only), 1=WithNonLeverageFee (all positions), 2=Manual. References Dictionary.OverNightFeePattern. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRate)';
ALTER TABLE main.general.bronze_etoro_dictionary_interestrate ALTER COLUMN SettlementTypeID COMMENT 'Settlement model: 0=CFD, 1=Real Stock, 4=Real Settlement, 5=TRS. Part of composite PK. References Dictionary.SettlementTypes. (Tier 1 - upstream wiki, etoro.Dictionary.InterestRate)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
