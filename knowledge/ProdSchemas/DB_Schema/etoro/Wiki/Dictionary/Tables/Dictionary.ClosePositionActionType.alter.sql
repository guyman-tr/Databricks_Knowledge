-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.ClosePositionActionType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ClosePositionActionType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_closepositionactiontype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_closepositionactiontype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_closepositionactiontype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 27 triggers/reasons for closing a trading position — used for attribution, analytics, and fee routing. Source: etoro.Dictionary.ClosePositionActionType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ClosePositionActionType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_closepositionactiontype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'ClosePositionActionType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_closepositionactiontype ALTER COLUMN ID COMMENT 'Primary key identifying the closure trigger. 0=Customer, 1=Stop Loss, 2=End of Week, 3=SL via trade server, 4=Return to Market, 5=Take Profit, 6=TP via trade server, 7=Contract Rollover, 8=BackOffice, 9=Hierarchical Close, 10=Hierarchical recovery, 11=Join Demo Challenge, 12=Close All, 13=Copy Stop Loss, 14=Mirror manual close, 15=Manual Liquidation, 16=BSL, 17=Manual Unregister, 18=BO Unregister, 19=Redeem, 20=Operational adjustment, 21=Orphaned, 22=Transferred Out, 23=Alignment, 24=Delist, 25=Close by rate, 26=Expiry. Stored with every closed position for permanent attribution. See Close Position Action Type. (Dictionary.ClosePositionActionType) (Tier 1 - upstream wiki, etoro.Dictionary.ClosePositionActionType)';
ALTER TABLE main.general.bronze_etoro_dictionary_closepositionactiontype ALTER COLUMN ClosePositionActionName COMMENT 'Human-readable label for the closure trigger. Used in account statements, trading reports, and back-office displays. (Tier 1 - upstream wiki, etoro.Dictionary.ClosePositionActionType)';

