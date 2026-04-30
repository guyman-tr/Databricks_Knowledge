-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.PortfolioConversionConfigurations
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.PortfolioConversionConfigurations.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_etoro_history_portfolioconversionconfigurations
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_etoro_history_portfolioconversionconfigurations (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_etoro_history_portfolioconversionconfigurations SET TBLPROPERTIES (
    'comment' = 'SQL Server temporal history table storing prior row versions of Hedge.PortfolioConversionConfigurations, preserving the audit trail for changes to the instrument-to-hedge-instrument conversion multiplier mappings used by the hedging engine. Source: etoro.History.PortfolioConversionConfigurations on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.PortfolioConversionConfigurations.md).'
);

ALTER TABLE main.dealing.bronze_etoro_history_portfolioconversionconfigurations SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'PortfolioConversionConfigurations',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_etoro_history_portfolioconversionconfigurations ALTER COLUMN InstrumentID COMMENT 'Source instrument whose exposure is being converted/hedged. Part of the composite key from source table. FK to Trade.Instrument (fk_potfolioConvertedInstrument). (Tier 1 - upstream wiki, etoro.History.PortfolioConversionConfigurations)';
ALTER TABLE main.dealing.bronze_etoro_history_portfolioconversionconfigurations ALTER COLUMN InstrumentIDToHedge COMMENT 'Target instrument used to hedge the source instrument''s exposure. Part of the composite key. FK to Trade.Instrument (fk_potfolioHedgedInstrument). One InstrumentID can map to multiple InstrumentIDToHedge values. (Tier 1 - upstream wiki, etoro.History.PortfolioConversionConfigurations)';
ALTER TABLE main.dealing.bronze_etoro_history_portfolioconversionconfigurations ALTER COLUMN Multiplier COMMENT 'Conversion factor for calculating hedge quantity from source exposure. 0 = mapping disabled/inactive; 1.0 = full 1:1 equivalent hedge; other values = partial or scaled hedge. (Tier 1 - upstream wiki, etoro.History.PortfolioConversionConfigurations)';
ALTER TABLE main.dealing.bronze_etoro_history_portfolioconversionconfigurations ALTER COLUMN SysStartTime COMMENT 'UTC timestamp when this configuration version became active. SQL Server temporal period start. datetime2(2) precision (10ms). SysStartTime=SysEndTime indicates INSERT-capture record from TRG_T_PortfolioConversionConfigurations. (Tier 1 - upstream wiki, etoro.History.PortfolioConversionConfigurations)';
ALTER TABLE main.dealing.bronze_etoro_history_portfolioconversionconfigurations ALTER COLUMN SysEndTime COMMENT 'UTC timestamp when this configuration version was superseded. SysStartTime=SysEndTime = INSERT-capture record. (Tier 1 - upstream wiki, etoro.History.PortfolioConversionConfigurations)';
ALTER TABLE main.dealing.bronze_etoro_history_portfolioconversionconfigurations ALTER COLUMN DbLoginName COMMENT 'SQL Server login that made the change, computed from SUSER_NAME() in source table. Captured at write time. Typically "TRAD\{username}" format (e.g., "TRAD\ranlev"). (Tier 1 - upstream wiki, etoro.History.PortfolioConversionConfigurations)';
ALTER TABLE main.dealing.bronze_etoro_history_portfolioconversionconfigurations ALTER COLUMN AppLoginName COMMENT 'Application context from CONTEXT_INFO() in source. Set by ConfigurationManager before the write. Format: "{username};ConfigurationManager" padded with null bytes to 500 chars. (Tier 1 - upstream wiki, etoro.History.PortfolioConversionConfigurations)';
ALTER TABLE main.dealing.bronze_etoro_history_portfolioconversionconfigurations ALTER COLUMN HostName COMMENT 'Server hostname from host_name() at write time. Identifies which hedge engine server (e.g., "STG-TRD-R-HEDGE") made the configuration change. Added in this version; absent in the older History.PortfolioConversionConfiguration (singular). (Tier 1 - upstream wiki, etoro.History.PortfolioConversionConfigurations)';

