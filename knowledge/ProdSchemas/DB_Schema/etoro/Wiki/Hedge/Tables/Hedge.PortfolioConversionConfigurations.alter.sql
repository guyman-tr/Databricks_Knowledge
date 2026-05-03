-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.PortfolioConversionConfigurations
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.PortfolioConversionConfigurations.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations SET TBLPROPERTIES (
    'comment' = 'Maps synthetic non-expiry instruments to their underlying real futures contracts with a weighting multiplier - enables rolling futures hedge by setting Multiplier=0 on expiring contracts and Multiplier=1 on the next contract. Source: etoro.Hedge.PortfolioConversionConfigurations on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.PortfolioConversionConfigurations.md).'
);

ALTER TABLE main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'PortfolioConversionConfigurations',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations ALTER COLUMN InstrumentID COMMENT 'First component of composite PK. FK to Trade.Instrument (fk_potfolioConvertedInstrument). The synthetic non-expiry instrument visible to eToro clients - e.g., InstrumentID=17 = "Oil (Non Expiry)". This is the instrument being "converted" from synthetic to real-futures representation. (Tier 1 - upstream wiki, etoro.Hedge.PortfolioConversionConfigurations)';
ALTER TABLE main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations ALTER COLUMN InstrumentIDToHedge COMMENT 'Second component of composite PK. FK to Trade.Instrument (fk_potfolioHedgedInstrument). The actual exchange-traded futures contract used to hedge the synthetic instrument - e.g., InstrumentID=290 = "Crude Oil Future February 24". One InstrumentID can map to multiple futures contracts (one row per contract). (Tier 1 - upstream wiki, etoro.Hedge.PortfolioConversionConfigurations)';
ALTER TABLE main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations ALTER COLUMN Multiplier COMMENT 'The weighting factor (0.0 to 1.0) defining what fraction of the synthetic instrument''s exposure is hedged via this futures contract. Multiplier=1 = 100% of the hedge uses this contract (active). Multiplier=0 = this contract no longer carries any of the hedge (expired/rolled out). For rolling futures, exactly one row per InstrumentID will have Multiplier=1 at any given time. (Tier 1 - upstream wiki, etoro.Hedge.PortfolioConversionConfigurations)';
ALTER TABLE main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations ALTER COLUMN SysStartTime COMMENT 'System-generated temporal period start. Timestamp when this configuration row became effective. Used with SysEndTime for system versioning (SYSTEM_VERSIONING = ON). History retained in History.PortfolioConversionConfigurations. (Tier 1 - upstream wiki, etoro.Hedge.PortfolioConversionConfigurations)';
ALTER TABLE main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations ALTER COLUMN SysEndTime COMMENT 'System-generated temporal period end. ''9999-12-31'' for all active rows. Set to actual timestamp when a row is updated or deleted. (Tier 1 - upstream wiki, etoro.Hedge.PortfolioConversionConfigurations)';
ALTER TABLE main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations ALTER COLUMN DbLoginName COMMENT 'Computed column. SQL Server login name of the session that last modified this row. Captures DBA/deployment identity. Same audit pattern as Hedge.OrderTypeConfiguration. (Tier 1 - upstream wiki, etoro.Hedge.PortfolioConversionConfigurations)';
ALTER TABLE main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations ALTER COLUMN AppLoginName COMMENT 'Computed column. Application-level user context from context_info(). Set by the application before DML operations to identify the calling service or user. Same audit pattern as Hedge.OrderTypeConfiguration. (Tier 1 - upstream wiki, etoro.Hedge.PortfolioConversionConfigurations)';
ALTER TABLE main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations ALTER COLUMN HostName COMMENT 'Computed column. The hostname of the client machine that made the last change. Not present in OrderTypeConfiguration - this table additionally captures the host for change attribution. Useful for identifying which hedge server instance or admin machine modified the config. (Tier 1 - upstream wiki, etoro.Hedge.PortfolioConversionConfigurations)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
