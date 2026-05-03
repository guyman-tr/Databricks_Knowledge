-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.HBCExecutionLog
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCExecutionLog.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_etoro_hedge_hbcexecutionlog
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_etoro_hedge_hbcexecutionlog (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog SET TBLPROPERTIES (
    'comment' = 'HBC (Hedge By Customer) execution audit log: one row per HBC hedge execution attempt, capturing requested vs executed lots, eToro rate vs LP rate, timing, and success/failure outcome; parent of Hedge.HBCOrderLog (individual orders within an execution). Source: etoro.Hedge.HBCExecutionLog on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCExecutionLog.md).'
);

ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'HBCExecutionLog',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog ALTER COLUMN ExecutionID COMMENT 'Externally assigned execution identifier (no IDENTITY - assigned by HedgeServer application). CLUSTERED PK. Links to Trade position data via InitExecutionID/EndExecutionID. Range 12M-13.8M in this environment suggests shared counter with other execution subsystems. (Tier 1 - upstream wiki, etoro.Hedge.HBCExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog ALTER COLUMN HedgeServerID COMMENT 'FK to Trade.HedgeServer. The hedge server instance that performed this execution. All rows in this environment use HedgeServerID=1. (Tier 1 - upstream wiki, etoro.Hedge.HBCExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog ALTER COLUMN LiquidityAccountID COMMENT 'FK to Trade.LiquidityAccounts. The liquidity account (provider connection) used. All rows: LiquidityAccountID=10 (ZBFX Price2 Execution). HBC in this environment routes exclusively through ZBFX. (Tier 1 - upstream wiki, etoro.Hedge.HBCExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog ALTER COLUMN InstrumentID COMMENT 'The instrument being hedged. Implicit reference to Trade.Instrument. InstrumentID=100000 appears for NOP aggregate crypto executions. 152 distinct values. (Tier 1 - upstream wiki, etoro.Hedge.HBCExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog ALTER COLUMN IsBuy COMMENT 'Direction: 1=BUY hedge (eToro is buying from provider to hedge net short customer exposure), 0=SELL hedge. ~95% are buys (63%) or sells (31%). (Tier 1 - upstream wiki, etoro.Hedge.HBCExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog ALTER COLUMN IsSuccess COMMENT 'Whether the execution completed successfully. 94% true. False rows have FailReason populated. Note: execution can succeed even if ExecutionAmountInLots != RequestAmountInLots (lot rounding is expected). (Tier 1 - upstream wiki, etoro.Hedge.HBCExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog ALTER COLUMN RequestAmountInLots COMMENT 'The pre-rounding lot amount calculated from the exposure/order. May be fractional (e.g., 2.46). This is the "ideal" amount before lot-size adjustment. (Tier 1 - upstream wiki, etoro.Hedge.HBCExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog ALTER COLUMN ExecutionAmountInLots COMMENT 'The actual lot amount submitted to the provider after whole-lot rounding. Always a whole number in practice (e.g., 3.000000). Discrepancy vs RequestAmountInLots is intentional (over-hedge by rounding up). Validated by GetHBCEstimationsDiscrepencies against customer position sum. (Tier 1 - upstream wiki, etoro.Hedge.HBCExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog ALTER COLUMN ExecutionRate COMMENT 'The eToro-side execution rate recorded for this hedge. May be spread-adjusted for manual executions or limit-adjusted for TP/SL executions. Uses dbo.dtPrice custom type (high-precision decimal). (Tier 1 - upstream wiki, etoro.Hedge.HBCExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog ALTER COLUMN StartTime COMMENT 'UTC datetime when the hedge execution was initiated (order sent to provider). Clustered index column (filtered NC WHERE IsSuccess=1). (Tier 1 - upstream wiki, etoro.Hedge.HBCExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog ALTER COLUMN EndTime COMMENT 'UTC datetime when the execution completed (fill received or failure detected). EndTime - StartTime = execution latency. Used by GetHBCEstimationsDiscrepencies to filter recent executions. (Tier 1 - upstream wiki, etoro.Hedge.HBCExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog ALTER COLUMN FailReason COMMENT 'Human-readable failure reason for IsSuccess=0 rows. Common values: "unrecoverable error during execution", "execution time exceeded", "liquidity provider not available for hedging", "allowed rate difference exceeded", "execution amount larger then deal size reject threshold". NULL for successful executions. (Tier 1 - upstream wiki, etoro.Hedge.HBCExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog ALTER COLUMN LPExecutionRate COMMENT 'The actual fill rate returned by the liquidity provider. NULL if IsSuccess=0. The difference from ExecutionRate represents slippage. Rate is converted back to eToro units via RateConversionFactor in Trade.LiquidityProviderContracts. (Tier 1 - upstream wiki, etoro.Hedge.HBCExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog ALTER COLUMN MarketRateIDAtExecutionEnd COMMENT 'Reference to the market rate record at the time execution completed. Used for audit - captures the prevailing market rate at fill time for post-trade analysis. (Tier 1 - upstream wiki, etoro.Hedge.HBCExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog ALTER COLUMN ShouldWaitForConfirm COMMENT 'Maps to @IsManualRequest parameter in LogHBCExecution (column name was not updated when parameter renamed). True for manual hedge orders from the Dealing Desk that require explicit confirmation before completing. NULL for older rows and standard executions. (Tier 1 - upstream wiki, etoro.Hedge.HBCExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog ALTER COLUMN InitialRate COMMENT 'The eToro market rate at hedge initiation time (customer''s reference rate). Nullable - may be absent for cancel executions. Enables comparison of rate at order creation vs rate at fill (InitialRate vs LPExecutionRate). (Tier 1 - upstream wiki, etoro.Hedge.HBCExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog ALTER COLUMN IsCancelExecution COMMENT '1 if this row represents a cancellation of a previous execution. DEFAULT 0. 78 cancel rows in data. Cancellation requests arrive via RabbitMQ from HedgeAPI. (Tier 1 - upstream wiki, etoro.Hedge.HBCExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_hbcexecutionlog ALTER COLUMN CancelledExecutionID COMMENT 'For IsCancelExecution=1 rows: the ExecutionID of the original execution being cancelled. DEFAULT 0 for normal (non-cancel) executions. (Tier 1 - upstream wiki, etoro.Hedge.HBCExecutionLog)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
