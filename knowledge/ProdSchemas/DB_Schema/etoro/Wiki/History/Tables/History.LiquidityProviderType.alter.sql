-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.LiquidityProviderType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderType.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_history_liquidityprovidertype
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_history_liquidityprovidertype (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_history_liquidityprovidertype SET TBLPROPERTIES (
    'comment' = 'Temporal history table capturing all configuration changes made to Trade.LiquidityProviderType - the classification of external liquidity provider connection technologies used by the eToro hedging engine. Source: etoro.History.LiquidityProviderType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderType.md).'
);

ALTER TABLE main.trading.bronze_etoro_history_liquidityprovidertype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'LiquidityProviderType',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_history_liquidityprovidertype ALTER COLUMN LiquidityProviderTypeID COMMENT 'Unique identifier for the provider type. This is the PK of Trade.LiquidityProviderType; in the history table it can repeat for the same ID representing successive configuration versions. Numeric ranges follow loose conventions: 1-299=legacy brokers, 300-499=direct exchange connections, 9000-9999=FIX protocol providers, 10000-10999=specialized feeds. Referenced by History.LiquidityProviders.LiquidityProviderTypeID. (Tier 1 - upstream wiki, etoro.History.LiquidityProviderType)';
ALTER TABLE main.trading.bronze_etoro_history_liquidityprovidertype ALTER COLUMN Name COMMENT 'Human-readable name of the provider type (e.g., "FD", "Talos", "FIX_IG"). Maximum 50 characters. This name is used in operational tooling to identify the technology stack. Some names are placeholders (e.g., "DO NOT USE", "OMS Horizon - Do not use") indicating deprecated types. Some names contain typos preserved from original entry (e.g., "Blooberg Futures"). (Tier 1 - upstream wiki, etoro.History.LiquidityProviderType)';
ALTER TABLE main.trading.bronze_etoro_history_liquidityprovidertype ALTER COLUMN TypeSettingsXML COMMENT 'XML configuration blob defining the .NET assembly and class names for the Hedge Engine and Price Control System (PCS). Structure: PCSClassInfo (price feed class), HedgingProviderClassInfo (hedge execution class), executionClassInfo (execution client), ProviderExecutionSettings (default_lot_size), OnixsEngineSettings (FIX reconnect parameters). NULL for types without automated assembly configuration. Empty <typeSettings/> for configured but class-less types (Watchlist, some deprecated types). The history of this XML reveals how provider integrations evolved over time. (Tier 1 - upstream wiki, etoro.History.LiquidityProviderType)';
ALTER TABLE main.trading.bronze_etoro_history_liquidityprovidertype ALTER COLUMN DbLoginName COMMENT 'Captured database login name of the user who last modified this row at time of archival. In the live table (Trade.LiquidityProviderType) this is a computed column = suser_name(); here it is stored as a snapshot. Format: domain\username (e.g., "TRAD\michaelta", "ETORO_ADMIN"). Identifies the operator who made the configuration change. NULL for some rows where context was unavailable. (Tier 1 - upstream wiki, etoro.History.LiquidityProviderType)';
ALTER TABLE main.trading.bronze_etoro_history_liquidityprovidertype ALTER COLUMN AppLoginName COMMENT 'Application-level identity of who initiated the change, stored as a snapshot (in live table this is a computed column = context_info()). Format: "username;ConfigurationManager" followed by null-byte padding to fill the 500-byte buffer (visible as Unicode null characters in raw data). The ";ConfigurationManager" suffix indicates changes made through the Configuration Manager tool. NULL for changes made directly via SQL (no context_info set). (Tier 1 - upstream wiki, etoro.History.LiquidityProviderType)';
ALTER TABLE main.trading.bronze_etoro_history_liquidityprovidertype ALTER COLUMN SysStartTime COMMENT 'UTC timestamp when this version of the provider type configuration became active in Trade.LiquidityProviderType. Set automatically by SQL Server SYSTEM_VERSIONING. Precision: 7 decimal places (100ns). Together with SysEndTime, defines the exact period during which this configuration was live. The clustered index is ordered by SysEndTime ASC, SysStartTime ASC for efficient temporal range scans. (Tier 1 - upstream wiki, etoro.History.LiquidityProviderType)';
ALTER TABLE main.trading.bronze_etoro_history_liquidityprovidertype ALTER COLUMN SysEndTime COMMENT 'UTC timestamp when this version was superseded (replaced by a newer configuration in Trade.LiquidityProviderType). Set automatically by SQL Server SYSTEM_VERSIONING when the live row is modified or deleted. When SysEndTime equals SysStartTime, the configuration was changed immediately after insertion (effectively instantaneous). The clustered index leading column supports queries filtering by "was this type configured before date X?" (Tier 1 - upstream wiki, etoro.History.LiquidityProviderType)';

