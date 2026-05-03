-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.OpenPositionActionType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OpenPositionActionType.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_dictionary_openpositionactiontype
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_dictionary_openpositionactiontype (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_dictionary_openpositionactiontype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 18 triggers/reasons for opening a new trading position - used for attribution, analytics, and fee routing. Source: etoro.Dictionary.OpenPositionActionType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OpenPositionActionType.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_dictionary_openpositionactiontype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'OpenPositionActionType',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_dictionary_openpositionactiontype ALTER COLUMN ID COMMENT 'Identifier for the open trigger (no PK constraint in DDL). -1=Undefined, 0=Customer, 1=Hierarchical Open, 2=Reopen, 3=Open Open, 4=Stock Dividend, 5=Corporate Action, 6=Technical Issue, 7=Operational adjustment, 8=Add Funds, 9=Reinvestment, 10=Admin, 11=Stacking, 12=Promotion, 13=ACATS_IN, 14=ReedemForNFT, 15=Technical, 16=Alignment, 17=Recurring Investment. Stored with every position for permanent attribution. See Open Position Action Type. (Dictionary.OpenPositionActionType) (Tier 1 - upstream wiki, etoro.Dictionary.OpenPositionActionType)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_openpositionactiontype ALTER COLUMN OpenPositionActionName COMMENT 'Human-readable label for the open trigger. Used in account statements, trading reports, and back-office displays. (Tier 1 - upstream wiki, etoro.Dictionary.OpenPositionActionType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
