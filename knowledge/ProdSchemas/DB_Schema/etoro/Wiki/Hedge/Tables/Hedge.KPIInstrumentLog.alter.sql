-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.KPIInstrumentLog
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.KPIInstrumentLog.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_hedge_kpiinstrumentlog
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_hedge_kpiinstrumentlog (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_hedge_kpiinstrumentlog SET TBLPROPERTIES (
    'comment' = 'Periodic per-instrument trading volume KPI log: captures customer position volume vs. hedge account volume per (HedgeServer, Instrument) for each time window; written to the primary DB via linked-server synonym by Hedge.InsertKPIData running on the secondary. Source: etoro.Hedge.KPIInstrumentLog on the etoro production database, ingested via the Generic Pipeline (Append strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.KPIInstrumentLog.md).'
);

ALTER TABLE main.general.bronze_etoro_hedge_kpiinstrumentlog SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'KPIInstrumentLog',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_hedge_kpiinstrumentlog ALTER COLUMN ID COMMENT 'Auto-increment surrogate key. NONCLUSTERED PK + also CLUSTERED (via separate index). NOT FOR REPLICATION prevents identity increment on replication. (Tier 1 - upstream wiki, etoro.Hedge.KPIInstrumentLog)';
ALTER TABLE main.general.bronze_etoro_hedge_kpiinstrumentlog ALTER COLUMN OccurredInsert COMMENT 'DB server UTC timestamp when the KPI row was inserted. DEFAULT GETUTCDATE(). Records when the KPI calculation ran, not the period it covers. (Tier 1 - upstream wiki, etoro.Hedge.KPIInstrumentLog)';
ALTER TABLE main.general.bronze_etoro_hedge_kpiinstrumentlog ALTER COLUMN StartTime COMMENT 'Start of the KPI measurement period. Provided by the caller (@startTime). Typically aligns to a fixed interval boundary (e.g., 5-minute intervals). Used for dedup check. (Tier 1 - upstream wiki, etoro.Hedge.KPIInstrumentLog)';
ALTER TABLE main.general.bronze_etoro_hedge_kpiinstrumentlog ALTER COLUMN EndTime COMMENT 'End of the KPI measurement period. Provided by the caller (@endTime). NC index on EndTime for time-range queries. (Tier 1 - upstream wiki, etoro.Hedge.KPIInstrumentLog)';
ALTER TABLE main.general.bronze_etoro_hedge_kpiinstrumentlog ALTER COLUMN HedgeServerID COMMENT 'The hedge server this KPI covers. References Trade.HedgeServer (implicit, no FK). (Tier 1 - upstream wiki, etoro.Hedge.KPIInstrumentLog)';
ALTER TABLE main.general.bronze_etoro_hedge_kpiinstrumentlog ALTER COLUMN HedgeServerMode COMMENT 'The HedgeStrategyModeID of the server at KPI calculation time. Enables strategy-mode filtering in historical analysis. (Tier 1 - upstream wiki, etoro.Hedge.KPIInstrumentLog)';
ALTER TABLE main.general.bronze_etoro_hedge_kpiinstrumentlog ALTER COLUMN InstrumentID COMMENT 'The instrument this KPI row covers. 0 = unmatched/null instrument (ISNULL default). Implicit reference to Trade.Instrument. (Tier 1 - upstream wiki, etoro.Hedge.KPIInstrumentLog)';
ALTER TABLE main.general.bronze_etoro_hedge_kpiinstrumentlog ALTER COLUMN TotalUnitsCustomers COMMENT 'Total position units transacted by real customers (excluding PlayerLevelID=4 test users) in the period, for this instrument+server. Sum of AmountInUnitsDecimal from PositionTbl + History.Position. (Tier 1 - upstream wiki, etoro.Hedge.KPIInstrumentLog)';
ALTER TABLE main.general.bronze_etoro_hedge_kpiinstrumentlog ALTER COLUMN TotalUnitsAccount COMMENT 'Total units executed through the hedge account in the period. Sum from ExecutionRequestBreakdownLog + ExecutionLog (OrderState=4 fills). Comparing to TotalUnitsCustomers reveals over/under-hedging. (Tier 1 - upstream wiki, etoro.Hedge.KPIInstrumentLog)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
