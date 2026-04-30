-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Price.Exchange
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.Exchange.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_price_exchange
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_price_exchange (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_price_exchange SET TBLPROPERTIES (
    'comment' = 'Master registry of 93 stock exchanges and trading venues used across eToro''s pricing and instrument infrastructure - each row maps an internal ExchangeID to the exchange''s standard identifiers (ISO MIC code, Reuters RIC suffix) and country, enabling feed routing, ticker resolution, and instrument display across all data providers. Source: etoro.Price.Exchange on the etoro production database, ingested via the Generic Pipeline (Override strategy, 30-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.Exchange.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_price_exchange SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Price',
    'source_table' = 'Exchange',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '30'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_price_exchange ALTER COLUMN ExchangeID COMMENT 'Primary key. Integer identifier assigned manually (not IDENTITY). Organizes by data-provider context: 1-2 = Xignite virtual; 3-47 = standard exchanges; 48-67 = JPM codes; 68+ = additional venues. Referenced by Trade.LiquidityProviderContracts.ExchangeID and Trade.InstrumentMetaData.ExchangeID. (Tier 1 - upstream wiki, etoro.Price.Exchange)';
ALTER TABLE main.bi_db.bronze_etoro_price_exchange ALTER COLUMN Name COMMENT 'Short exchange code name (up to 16 chars). Used in operations tooling and GetTickerInfo output. Not always an ISO standard code - some are IB-specific (IDEALPRO, ISLAND, SMART) or vendor-specific (DEFAULT_EXCHANGE). (Tier 1 - upstream wiki, etoro.Price.Exchange)';
ALTER TABLE main.bi_db.bronze_etoro_price_exchange ALTER COLUMN Description COMMENT 'Human-readable full exchange name. Some have minor typos from original data entry (e.g., "Eurpoe CHIX", "Exchnage"). Displayed in internal tooling and monitoring dashboards. (Tier 1 - upstream wiki, etoro.Price.Exchange)';
ALTER TABLE main.bi_db.bronze_etoro_price_exchange ALTER COLUMN Mic COMMENT 'Market Identifier Code (ISO 10383). Standard 4-character exchange identifier used by Bloomberg, regulatory reporting, and feed routing. Some non-standard values exist for virtual venues (DEFEXC, GLBEXC) and broker-specific identifiers (SMRT, IDLP, JPM 2-letter codes). (Tier 1 - upstream wiki, etoro.Price.Exchange)';
ALTER TABLE main.bi_db.bronze_etoro_price_exchange ALTER COLUMN CountryID COMMENT 'FK to Dictionary.Country. Geographic country of the exchange. CountryID=0 for exchanges without a resolved country mapping (JPM codes, some virtual venues). Key country IDs: 219=USA, 218=UK, 79=Germany, 74=France, 102=Italy, 196=Sweden, 197=Switzerland. (Tier 1 - upstream wiki, etoro.Price.Exchange)';
ALTER TABLE main.bi_db.bronze_etoro_price_exchange ALTER COLUMN DbLoginName COMMENT 'Computed: SQL Server login of last row modifier. Auto-set on every DML. (Tier 1 - upstream wiki, etoro.Price.Exchange)';
ALTER TABLE main.bi_db.bronze_etoro_price_exchange ALTER COLUMN AppLoginName COMMENT 'Computed: application identity from context_info(). Populated when the calling service sets context_info before DML. (Tier 1 - upstream wiki, etoro.Price.Exchange)';
ALTER TABLE main.bi_db.bronze_etoro_price_exchange ALTER COLUMN SysStartTime COMMENT 'Temporal row validity start. Auto-managed by SQL Server system versioning. (Tier 1 - upstream wiki, etoro.Price.Exchange)';
ALTER TABLE main.bi_db.bronze_etoro_price_exchange ALTER COLUMN SysEndTime COMMENT 'Temporal row validity end. Historical versions in History.Exchange. (Tier 1 - upstream wiki, etoro.Price.Exchange)';
ALTER TABLE main.bi_db.bronze_etoro_price_exchange ALTER COLUMN Ric COMMENT 'Reuters/Refinitiv exchange suffix appended to RIC tickers (e.g., AAPL.N where N = NYSE). NULL for exchanges not available on Reuters/Refinitiv or where RIC routing is not used. Used by GetTickerInfo to build complete Reuters ticker strings for liquidity provider feeds. (Tier 1 - upstream wiki, etoro.Price.Exchange)';

