-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_NOP_Report
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report SET TBLPROPERTIES (
    'comment' = ''
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report SET TAGS (
    'domain' = 'dealing',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN Date COMMENT 'Report date. Saturday is skipped; Sunday uses prior Friday''s date.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN AccountName COMMENT 'LP account name (e.g., ''GS'', ''IB'', ''JP'', ''Vision'', ''SAXO'').';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN InstrumentID COMMENT 'Instrument primary key.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN InstrumentName COMMENT 'Instrument name. Denormalized from Dim_Instrument.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN AssetClass COMMENT 'Asset class grouping (e.g., Stocks, FX, Crypto).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN NOP COMMENT 'Net Open Position with this LP (in USD or native units - varies by LP).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN Margin COMMENT 'Margin held at this LP for this instrument position.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN OpenPremium COMMENT 'Open premium value (relevant for options/structured products).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN [Unrealised_P&L/VariationMargin] COMMENT '⚠️ Contains `&` and `/` - quote in SQL. Unrealised P&L or variation margin posted at this LP.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN NOPDirection COMMENT '''Long'' or ''Short'' indicating net direction of the position.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN Currency COMMENT 'Currency of the NOP/margin figures.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN ExchangeRate COMMENT 'FX rate used to convert to reporting currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN NOP_USD COMMENT 'NOP converted to USD.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated.';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN AccountName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN AssetClass SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN Margin SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN OpenPremium SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN [Unrealised_P&L/VariationMargin] SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN NOPDirection SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN ExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN NOP_USD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
