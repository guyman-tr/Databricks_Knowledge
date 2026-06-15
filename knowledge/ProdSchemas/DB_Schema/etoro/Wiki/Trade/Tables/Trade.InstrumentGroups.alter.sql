-- =============================================================================
-- Databricks ALTER Script: main.trading.bronze_etoro_trade_instrumentgroups  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentGroups.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.trading.bronze_etoro_trade_instrumentgroups ALTER COLUMN ProviderID COMMENT 'Liquidity provider/broker identifier. Part of composite FK to Trade.ProviderToInstrument(ProviderID, InstrumentID). All current rows use ProviderID=1 (primary provider). Determines which provider''s instrument listing this group membership applies to.';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentgroups ALTER COLUMN InstrumentID COMMENT 'Trading instrument identifier. Part of composite PK (InstrumentID, GroupID) and composite FK to Trade.ProviderToInstrument. References the instrument being classified. An instrument can appear in multiple rows with different GroupIDs.';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentgroups ALTER COLUMN GroupID COMMENT 'Group classification identifier. Part of composite PK. FK to Dictionary.TradingInstrumentGroups(GroupID). Key values: 1=RealOnly (real stock only), 2=CopyBlock (no copy-trading), 3=CFDOnly, 4=US_Restricted. 315 total groups exist including MaxNOP limits and QA automation groups. Checked by Trade.IsInstrumentInGroup and used in fee calculations.';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentgroups ALTER COLUMN SysStartTime COMMENT 'System-versioned temporal column (GENERATED ALWAYS AS ROW START). Records when this group assignment became effective. Default is current UTC time at INSERT. Part of PERIOD FOR SYSTEM_TIME.';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentgroups ALTER COLUMN SysEndTime COMMENT 'System-versioned temporal column (GENERATED ALWAYS AS ROW END). Records when this group assignment was removed or changed. Value of 9999-12-31 indicates the assignment is current. Part of PERIOD FOR SYSTEM_TIME.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:28:51 UTC
-- Statements: 5/5 succeeded
-- ====================
