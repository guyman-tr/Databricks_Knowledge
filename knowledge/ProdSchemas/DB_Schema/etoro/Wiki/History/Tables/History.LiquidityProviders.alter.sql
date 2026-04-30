-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.LiquidityProviders
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviders.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_history_liquidityproviders
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_history_liquidityproviders (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_history_liquidityproviders SET TBLPROPERTIES (
    'comment' = 'SQL Server temporal history table automatically maintained by the database engine, recording every past configuration state of Trade.LiquidityProviders - the registry of individual liquidity provider connection instances used by eToro''s hedging engine. Source: etoro.History.LiquidityProviders on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviders.md).'
);

ALTER TABLE main.trading.bronze_etoro_history_liquidityproviders SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'LiquidityProviders',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_history_liquidityproviders ALTER COLUMN LiquidityProviderID COMMENT 'The unique identifier of the liquidity provider instance. Matches Trade.LiquidityProviders.LiquidityProviderID (PK on the live table). Multiple history rows share the same LiquidityProviderID across different time periods as the provider was reconfigured. References the same LP whose settings changed. (Tier 1 - upstream wiki, etoro.History.LiquidityProviders)';
ALTER TABLE main.trading.bronze_etoro_history_liquidityproviders ALTER COLUMN LiquidityProviderName COMMENT 'The human-readable name of the LP instance used in operational tooling. Examples: "FD Provider UAT", "ZBFX3", "Marex OMS". Naming convention "Obsolete! Use Hedge Account" signals deprecated LP connections replaced by the hedge account model. Name changes generate new temporal history rows. (Tier 1 - upstream wiki, etoro.History.LiquidityProviders)';
ALTER TABLE main.trading.bronze_etoro_history_liquidityproviders ALTER COLUMN LiquidityProviderSettingsXML COMMENT 'Instance-specific connection settings in XML format. Mirrors the structure of Trade.LiquidityProviderType.TypeSettingsXML but at the instance level - contains account-specific parameters (endpoints, credentials, risk limits, lot sizes) that override or extend the type-level configuration. NULL for LPs without automated XML configuration. History of this XML tracks how connection settings evolved over time. (Tier 1 - upstream wiki, etoro.History.LiquidityProviders)';
ALTER TABLE main.trading.bronze_etoro_history_liquidityproviders ALTER COLUMN LiquidityProviderTypeID COMMENT 'The technology class of this LP instance. FK to Trade.LiquidityProviderType on the live table (not enforced in history). Multiple LP instances share the same LiquidityProviderTypeID (e.g., multiple FD accounts all using TypeID=3). Values from data: 3=FD, 7, 40=APEX, 69=ZBFX, 84=Marex, 10002=OMS. NULL if the LP is not typed (legacy or decommissioned). (Tier 1 - upstream wiki, etoro.History.LiquidityProviders)';
ALTER TABLE main.trading.bronze_etoro_history_liquidityproviders ALTER COLUMN DbLoginName COMMENT 'SQL Server login name that changed this LP configuration. Computed column on Trade.LiquidityProviders (= suser_name()); stored as a snapshot in history. Format: domain\username (e.g., "TRAD\danielma", "TRAD\dotanva") or service account ("DevTradingSTG"). Identifies the operator who made the configuration change. NULL if the session context was unavailable. (Tier 1 - upstream wiki, etoro.History.LiquidityProviders)';
ALTER TABLE main.trading.bronze_etoro_history_liquidityproviders ALTER COLUMN AppLoginName COMMENT 'Application-level identity from context_info(). Computed column on live table; stored as snapshot in history. NULL in all observed history rows - LP configuration changes appear to be made directly via SQL or Configuration Manager without setting application context. varchar(500) accommodates the "username;ConfigurationManager" pattern seen in other tables. (Tier 1 - upstream wiki, etoro.History.LiquidityProviders)';
ALTER TABLE main.trading.bronze_etoro_history_liquidityproviders ALTER COLUMN SysStartTime COMMENT 'UTC timestamp when this LP configuration became current in Trade.LiquidityProviders. Set automatically by SQL Server SYSTEM_VERSIONING. The clustered index (SysEndTime, SysStartTime) supports efficient temporal range queries. (Tier 1 - upstream wiki, etoro.History.LiquidityProviders)';
ALTER TABLE main.trading.bronze_etoro_history_liquidityproviders ALTER COLUMN SysEndTime COMMENT 'UTC timestamp when this LP configuration was superseded. For all history rows, always a past timestamp. When SysEndTime = SysStartTime (ValidForSec=0), the LP was reconfigured immediately after the prior update - often seen during complex configuration workflows where settings are applied in rapid succession. (Tier 1 - upstream wiki, etoro.History.LiquidityProviders)';

