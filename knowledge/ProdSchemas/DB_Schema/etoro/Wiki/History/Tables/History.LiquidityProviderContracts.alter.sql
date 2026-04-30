-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.LiquidityProviderContracts
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_history_liquidityprovidercontracts
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_history_liquidityprovidercontracts (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts SET TBLPROPERTIES (
    'comment' = 'SQL Server temporal history table storing prior row versions of Trade.LiquidityProviderContracts, capturing the complete history of which instruments were contractually available through which liquidity providers and exchanges over time. Source: etoro.History.LiquidityProviderContracts on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'LiquidityProviderContracts',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN ContractID COMMENT 'Auto-incremented contract identifier (IDENTITY in active table). Each new contract gets a unique sequential ID. Used in audit trail (History.AuditHistory) as a reference. Not a composite key component - the PK is (InstrumentID, LiquidityProviderID, ExchangeID). (Tier 1 - upstream wiki, etoro.History.LiquidityProviderContracts)';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN LiquidityProviderID COMMENT 'ID of the liquidity provider. FK to Trade.LiquidityProviderType in active table. Identifies which external LP (broker, exchange connection, internalizer) this contract covers. (Tier 1 - upstream wiki, etoro.History.LiquidityProviderContracts)';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN InstrumentID COMMENT 'Financial instrument ID. FK to Trade.Instrument in active table. Identifies which financial instrument this LP-exchange contract covers. (Tier 1 - upstream wiki, etoro.History.LiquidityProviderContracts)';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN FromDate COMMENT 'Start date of the LP-instrument contract. When the contract became effective. FromDate = ToDate on many rows indicates a contract that was created and immediately superseded (trigger artifact or same-day replacement). (Tier 1 - upstream wiki, etoro.History.LiquidityProviderContracts)';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN ToDate COMMENT 'End date of the LP-instrument contract. When the contract was replaced or terminated. ToDate = 2100-01-01 00:00:00 = open-ended contract with no planned expiry. The default in active table is ''2100-01-01''. (Tier 1 - upstream wiki, etoro.History.LiquidityProviderContracts)';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN Ticker COMMENT 'The LP''s symbol/ticker for this instrument. Used to map eToro instrument IDs to the LP''s own identifiers in price feeds and order routing. Formats observed: Bloomberg equity tickers ("AAPL US@NBSC Equity"), simple symbols ("BA"), numeric IDs ("1016586"). NULL if no ticker assigned. (Tier 1 - upstream wiki, etoro.History.LiquidityProviderContracts)';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN ExchangeID COMMENT 'Exchange through which this LP contract routes. FK to Price.Exchange in active table. DEFAULT 1 (the primary/default exchange). All observed rows: ExchangeID=1. (Tier 1 - upstream wiki, etoro.History.LiquidityProviderContracts)';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN RateConversionFactor COMMENT 'Multiplicative factor applied to prices from this LP for this instrument. DEFAULT 1.0 (no conversion). Non-1 values indicate instruments where the LP quotes in different units (e.g., pence vs pounds, cents vs dollars) or requires a fixed price scaling. NULL if not applicable. (Tier 1 - upstream wiki, etoro.History.LiquidityProviderContracts)';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN DbLoginName COMMENT 'Materialized SQL Server login name (suser_name()) at the time this row version was closed. In active table this is a computed column; stored here as a snapshot. Identifies which DB login modified the contract. (Tier 1 - upstream wiki, etoro.History.LiquidityProviderContracts)';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN AppLoginName COMMENT 'Materialized application identity (context_info()) at version close time. Stored here as a snapshot. NULL if not set by the writing application. (Tier 1 - upstream wiki, etoro.History.LiquidityProviderContracts)';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN SysStartTime COMMENT 'Start of the validity window for this history row. Set by SQL Server temporal engine. For INSERT artifacts: SysStartTime = SysEndTime. For genuine updates: the timestamp when the previous contract state became current. (Tier 1 - upstream wiki, etoro.History.LiquidityProviderContracts)';
ALTER TABLE main.bi_db.bronze_etoro_history_liquidityprovidercontracts ALTER COLUMN SysEndTime COMMENT 'End of the validity window for this history row. Set to the UTC time of the UPDATE/DELETE that closed this version. CLUSTERED INDEX leads with SysEndTime for optimal temporal query performance. (Tier 1 - upstream wiki, etoro.History.LiquidityProviderContracts)';

