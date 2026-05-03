-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.InstrumentGroups
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentGroups.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_instrumentgroups
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_instrumentgroups (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_instrumentgroups SET TBLPROPERTIES (
    'comment' = 'Junction table mapping trading instruments to classification groups, enabling the platform to control which instruments are restricted to real stock only, blocked from copy trading, CFD-only, US-restricted, or subject to Net Open Position (NOP) exposure limits. Source: etoro.Trade.InstrumentGroups on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentGroups.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_instrumentgroups SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'InstrumentGroups',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_instrumentgroups ALTER COLUMN ProviderID COMMENT 'Liquidity provider/broker identifier. Part of composite FK to Trade.ProviderToInstrument(ProviderID, InstrumentID). All current rows use ProviderID=1 (primary provider). Determines which provider''s instrument listing this group membership applies to. (Tier 1 - upstream wiki, etoro.Trade.InstrumentGroups)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentgroups ALTER COLUMN InstrumentID COMMENT 'Trading instrument identifier. Part of composite PK (InstrumentID, GroupID) and composite FK to Trade.ProviderToInstrument. References the instrument being classified. An instrument can appear in multiple rows with different GroupIDs. (Tier 1 - upstream wiki, etoro.Trade.InstrumentGroups)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentgroups ALTER COLUMN GroupID COMMENT 'Group classification identifier. Part of composite PK. FK to Dictionary.TradingInstrumentGroups(GroupID). Key values: 1=RealOnly (real stock only), 2=CopyBlock (no copy-trading), 3=CFDOnly, 4=US_Restricted. 315 total groups exist including MaxNOP limits and QA automation groups. Checked by Trade.IsInstrumentInGroup and used in fee calculations. (Tier 1 - upstream wiki, etoro.Trade.InstrumentGroups)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentgroups ALTER COLUMN SysStartTime COMMENT 'System-versioned temporal column (GENERATED ALWAYS AS ROW START). Records when this group assignment became effective. Default is current UTC time at INSERT. Part of PERIOD FOR SYSTEM_TIME. (Tier 1 - upstream wiki, etoro.Trade.InstrumentGroups)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentgroups ALTER COLUMN SysEndTime COMMENT 'System-versioned temporal column (GENERATED ALWAYS AS ROW END). Records when this group assignment was removed or changed. Value of 9999-12-31 indicates the assignment is current. Part of PERIOD FOR SYSTEM_TIME. (Tier 1 - upstream wiki, etoro.Trade.InstrumentGroups)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentgroups ALTER COLUMN DbLoginName COMMENT 'Computed audit column: suser_name(). Captures the SQL Server login name of the session that last modified this row. Used for auditing which database account performed the change. (Tier 1 - upstream wiki, etoro.Trade.InstrumentGroups)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentgroups ALTER COLUMN AppLoginName COMMENT 'Computed audit column: CONVERT(varchar(500), context_info()). Captures the application-level user identity from CONTEXT_INFO, which is set by Trade.InsertInstrumentGroup and Trade.DeleteInstrumentGroup from the @AppLoginName parameter. Identifies the back-office operator who made the group assignment change. (Tier 1 - upstream wiki, etoro.Trade.InstrumentGroups)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
