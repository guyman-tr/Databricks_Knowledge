-- =============================================================================
-- Databricks ALTER Script: main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.PortfolioConversionConfigurations.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations ALTER COLUMN InstrumentID COMMENT 'First component of composite PK. FK to Trade.Instrument (fk_potfolioConvertedInstrument). The synthetic non-expiry instrument visible to eToro clients - e.g., InstrumentID=17 = "Oil (Non Expiry)". This is the instrument being "converted" from synthetic to real-futures representation.';
ALTER TABLE main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations ALTER COLUMN InstrumentIDToHedge COMMENT 'Second component of composite PK. FK to Trade.Instrument (fk_potfolioHedgedInstrument). The actual exchange-traded futures contract used to hedge the synthetic instrument - e.g., InstrumentID=290 = "Crude Oil Future February 24". One InstrumentID can map to multiple futures contracts (one row per contract).';
ALTER TABLE main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations ALTER COLUMN Multiplier COMMENT 'The weighting factor (0.0 to 1.0) defining what fraction of the synthetic instrument''s exposure is hedged via this futures contract. Multiplier=1 = 100% of the hedge uses this contract (active). Multiplier=0 = this contract no longer carries any of the hedge (expired/rolled out). For rolling futures, exactly one row per InstrumentID will have Multiplier=1 at any given time.';
ALTER TABLE main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations ALTER COLUMN SysStartTime COMMENT 'System-generated temporal period start. Timestamp when this configuration row became effective. Used with SysEndTime for system versioning (SYSTEM_VERSIONING = ON). History retained in History.PortfolioConversionConfigurations.';
ALTER TABLE main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations ALTER COLUMN SysEndTime COMMENT 'System-generated temporal period end. ''9999-12-31'' for all active rows. Set to actual timestamp when a row is updated or deleted.';
ALTER TABLE main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations ALTER COLUMN DbLoginName COMMENT 'Computed column. SQL Server login name of the session that last modified this row. Captures DBA/deployment identity. Same audit pattern as Hedge.OrderTypeConfiguration.';
ALTER TABLE main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations ALTER COLUMN AppLoginName COMMENT 'Computed column. Application-level user context from `context_info()`. Set by the application before DML operations to identify the calling service or user. Same audit pattern as Hedge.OrderTypeConfiguration.';
ALTER TABLE main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations ALTER COLUMN HostName COMMENT 'Computed column. The hostname of the client machine that made the last change. Not present in OrderTypeConfiguration - this table additionally captures the host for change attribution. Useful for identifying which hedge server instance or admin machine modified the config.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:28:21 UTC
-- Statements: 8/8 succeeded
-- ====================
