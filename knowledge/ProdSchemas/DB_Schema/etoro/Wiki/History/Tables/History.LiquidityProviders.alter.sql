-- =============================================================================
-- Databricks ALTER Script: main.trading.bronze_etoro_history_liquidityproviders  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviders.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.trading.bronze_etoro_history_liquidityproviders ALTER COLUMN LiquidityProviderID COMMENT 'The unique identifier of the liquidity provider instance. Matches Trade.LiquidityProviders.LiquidityProviderID (PK on the live table). Multiple history rows share the same LiquidityProviderID across different time periods as the provider was reconfigured. References the same LP whose settings changed.';
ALTER TABLE main.trading.bronze_etoro_history_liquidityproviders ALTER COLUMN LiquidityProviderName COMMENT 'The human-readable name of the LP instance used in operational tooling. Examples: "FD Provider UAT", "ZBFX3", "Marex OMS". Naming convention "Obsolete! Use Hedge Account" signals deprecated LP connections replaced by the hedge account model. Name changes generate new temporal history rows.';
ALTER TABLE main.trading.bronze_etoro_history_liquidityproviders ALTER COLUMN LiquidityProviderSettingsXML COMMENT 'Instance-specific connection settings in XML format. Mirrors the structure of Trade.LiquidityProviderType.TypeSettingsXML but at the instance level - contains account-specific parameters (endpoints, credentials, risk limits, lot sizes) that override or extend the type-level configuration. NULL for LPs without automated XML configuration. History of this XML tracks how connection settings evolved over time.';
ALTER TABLE main.trading.bronze_etoro_history_liquidityproviders ALTER COLUMN LiquidityProviderTypeID COMMENT 'The technology class of this LP instance. FK to Trade.LiquidityProviderType on the live table (not enforced in history). Multiple LP instances share the same LiquidityProviderTypeID (e.g., multiple FD accounts all using TypeID=3). Values from data: 3=FD, 7, 40=APEX, 69=ZBFX, 84=Marex, 10002=OMS. NULL if the LP is not typed (legacy or decommissioned).';
ALTER TABLE main.trading.bronze_etoro_history_liquidityproviders ALTER COLUMN DbLoginName COMMENT 'SQL Server login name that changed this LP configuration. Computed column on Trade.LiquidityProviders (= suser_name()); stored as a snapshot in history. Format: domain\\username (e.g., "TRAD\\danielma", "TRAD\\dotanva") or service account ("DevTradingSTG"). Identifies the operator who made the configuration change. NULL if the session context was unavailable.';
ALTER TABLE main.trading.bronze_etoro_history_liquidityproviders ALTER COLUMN AppLoginName COMMENT 'Application-level identity from context_info(). Computed column on live table; stored as snapshot in history. NULL in all observed history rows - LP configuration changes appear to be made directly via SQL or Configuration Manager without setting application context. varchar(500) accommodates the "username;ConfigurationManager" pattern seen in other tables.';
ALTER TABLE main.trading.bronze_etoro_history_liquidityproviders ALTER COLUMN SysStartTime COMMENT 'UTC timestamp when this LP configuration became current in Trade.LiquidityProviders. Set automatically by SQL Server SYSTEM_VERSIONING. The clustered index (SysEndTime, SysStartTime) supports efficient temporal range queries.';
ALTER TABLE main.trading.bronze_etoro_history_liquidityproviders ALTER COLUMN SysEndTime COMMENT 'UTC timestamp when this LP configuration was superseded. For all history rows, always a past timestamp. When SysEndTime = SysStartTime (ValidForSec=0), the LP was reconfigured immediately after the prior update - often seen during complex configuration workflows where settings are applied in rapid succession.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:56:03 UTC
-- Statements: 8/8 succeeded
-- ====================
