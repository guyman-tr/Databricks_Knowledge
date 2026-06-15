-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_etoro_history_liquidityprovidercontracts  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN ContractID COMMENT 'Auto-incremented contract identifier (IDENTITY in active table). Each new contract gets a unique sequential ID. Used in audit trail (History.AuditHistory) as a reference. Not a composite key component - the PK is (InstrumentID, LiquidityProviderID, ExchangeID).';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN LiquidityProviderID COMMENT 'ID of the liquidity provider. FK to Trade.LiquidityProviderType in active table. Identifies which external LP (broker, exchange connection, internalizer) this contract covers.';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN InstrumentID COMMENT 'Financial instrument ID. FK to Trade.Instrument in active table. Identifies which financial instrument this LP-exchange contract covers.';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN FromDate COMMENT 'Start date of the LP-instrument contract. When the contract became effective. FromDate = ToDate on many rows indicates a contract that was created and immediately superseded (trigger artifact or same-day replacement).';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN ToDate COMMENT 'End date of the LP-instrument contract. When the contract was replaced or terminated. ToDate = 2100-01-01 00:00:00 = open-ended contract with no planned expiry. The default in active table is ''2100-01-01''.';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN Ticker COMMENT 'The LP''s symbol/ticker for this instrument. Used to map eToro instrument IDs to the LP''s own identifiers in price feeds and order routing. Formats observed: Bloomberg equity tickers ("AAPL US@NBSC Equity"), simple symbols ("BA"), numeric IDs ("1016586"). NULL if no ticker assigned.';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN ExchangeID COMMENT 'Exchange through which this LP contract routes. FK to Price.Exchange in active table. DEFAULT 1 (the primary/default exchange). All observed rows: ExchangeID=1.';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN RateConversionFactor COMMENT 'Multiplicative factor applied to prices from this LP for this instrument. DEFAULT 1.0 (no conversion). Non-1 values indicate instruments where the LP quotes in different units (e.g., pence vs pounds, cents vs dollars) or requires a fixed price scaling. NULL if not applicable.';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN DbLoginName COMMENT 'Materialized SQL Server login name (suser_name()) at the time this row version was closed. In active table this is a computed column; stored here as a snapshot. Identifies which DB login modified the contract.';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN AppLoginName COMMENT 'Materialized application identity (context_info()) at version close time. Stored here as a snapshot. NULL if not set by the writing application.';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN SysStartTime COMMENT 'Start of the validity window for this history row. Set by SQL Server temporal engine. For INSERT artifacts: SysStartTime = SysEndTime. For genuine updates: the timestamp when the previous contract state became current.';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN SysEndTime COMMENT 'End of the validity window for this history row. Set to the UTC time of the UPDATE/DELETE that closed this version. CLUSTERED INDEX leads with SysEndTime for optimal temporal query performance.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:26:46 UTC
-- Statements: 12/12 succeeded
-- ====================
