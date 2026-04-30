-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.InterestRate
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRate.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_interestrate
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_interestrate (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_interestrate SET TBLPROPERTIES (
    'comment' = 'Temporal history table capturing all changes to the base interest rate configuration by instrument type and settlement type, preserving the audit trail of central bank rates and eToro markups used to calculate overnight fees. Source: etoro.History.InterestRate on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRate.md).'
);

ALTER TABLE main.general.bronze_etoro_history_interestrate SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'InterestRate',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_interestrate ALTER COLUMN InterestRateID COMMENT 'Identifier for the interest rate group. PK part in the live table (combined with InstrumentTypeID and SettlementTypeID). Corresponds to a named currency group (e.g., ID=1 = IR USD, ID=4 = IR CHF). (Tier 1 - upstream wiki, etoro.History.InterestRate)';
ALTER TABLE main.general.bronze_etoro_history_interestrate ALTER COLUMN InterestRateName COMMENT 'Human-readable name for this interest rate group, typically the currency denomination (e.g., "IR USD", "IR CHF"). Used for display in the Trading OpsTool interface. (Tier 1 - upstream wiki, etoro.History.InterestRate)';
ALTER TABLE main.general.bronze_etoro_history_interestrate ALTER COLUMN InterestRate COMMENT 'Legacy base rate field. Contains 0 in all recent data - superseded by the separate InterestRateBuy and InterestRateSell columns added when buy/sell rates were split. (Tier 1 - upstream wiki, etoro.History.InterestRate)';
ALTER TABLE main.general.bronze_etoro_history_interestrate ALTER COLUMN UpdatedByUser COMMENT 'Username of the operator or system process that last updated this rate. NOT NULL, so automated updates use a service account name. (Tier 1 - upstream wiki, etoro.History.InterestRate)';
ALTER TABLE main.general.bronze_etoro_history_interestrate ALTER COLUMN BeginTime COMMENT 'UTC timestamp when this rate configuration became active in Dictionary.InterestRate (non-standard name for SysStartTime). (Tier 1 - upstream wiki, etoro.History.InterestRate)';
ALTER TABLE main.general.bronze_etoro_history_interestrate ALTER COLUMN EndTime COMMENT 'UTC timestamp when this rate configuration was superseded (non-standard name for SysEndTime). (Tier 1 - upstream wiki, etoro.History.InterestRate)';
ALTER TABLE main.general.bronze_etoro_history_interestrate ALTER COLUMN InstrumentTypeID COMMENT 'Instrument type this rate applies to (e.g., 4 = Forex). Part of composite PK in live table. Determines which class of instruments uses this base rate. (Tier 1 - upstream wiki, etoro.History.InterestRate)';
ALTER TABLE main.general.bronze_etoro_history_interestrate ALTER COLUMN InterestRateBuy COMMENT 'Market benchmark rate for long buy positions (e.g., SOFR for USD, SARON for CHF). Updated automatically from market data. Combined with MarkupBuy to produce the customer-facing buy rate. (Tier 1 - upstream wiki, etoro.History.InterestRate)';
ALTER TABLE main.general.bronze_etoro_history_interestrate ALTER COLUMN InterestRateSell COMMENT 'Market benchmark rate for short sell positions. Combined with MarkupSell to produce the customer-facing sell rate. (Tier 1 - upstream wiki, etoro.History.InterestRate)';
ALTER TABLE main.general.bronze_etoro_history_interestrate ALTER COLUMN MarkupBuy COMMENT 'eToro''s spread/markup added to InterestRateBuy to calculate the final overnight buy fee. Negative = eToro subsidizes the buy rate; positive = eToro charges above the market rate. (Tier 1 - upstream wiki, etoro.History.InterestRate)';
ALTER TABLE main.general.bronze_etoro_history_interestrate ALTER COLUMN MarkupSell COMMENT 'eToro''s spread/markup added to InterestRateSell. Negative = eToro passes through a discount on short positions; positive = adds charge on top of market rate. (Tier 1 - upstream wiki, etoro.History.InterestRate)';
ALTER TABLE main.general.bronze_etoro_history_interestrate ALTER COLUMN OverNightFeePatternID COMMENT 'Determines fee calculation scope: 0=Regular (no non-leveraged buy fees), 1=WithNonLeverageFee (fees apply to non-leveraged positions too), 2=Manual (not auto-calculated). (History.OverNightFeePattern). (Tier 1 - upstream wiki, etoro.History.InterestRate)';
ALTER TABLE main.general.bronze_etoro_history_interestrate ALTER COLUMN SettlementTypeID COMMENT 'Settlement type this rate applies to: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Part of composite PK in live table. (Dictionary.SettlementTypes). (Tier 1 - upstream wiki, etoro.History.InterestRate)';

