-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.BSLOperationThreshold
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.BSLOperationThreshold.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_bsloperationthreshold
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_bsloperationthreshold (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_bsloperationthreshold SET TBLPROPERTIES (
    'comment' = 'Configuration table defining the 4 equity percentage thresholds that trigger BSL (Balance Stop-Loss) actions - two warning levels, a liquidation trigger, and an unblock recovery threshold. Source: etoro.Dictionary.BSLOperationThreshold on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.BSLOperationThreshold.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_bsloperationthreshold SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'BSLOperationThreshold',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_bsloperationthreshold ALTER COLUMN ID COMMENT 'Primary key identifying the threshold row. Values 1-4. Referenced by procedures using hardcoded IDs (e.g., WHERE ID = 1 for liquidation, WHERE ID = 4 for unblock). (Tier 1 - upstream wiki, etoro.Dictionary.BSLOperationThreshold)';
ALTER TABLE main.general.bronze_etoro_dictionary_bsloperationthreshold ALTER COLUMN MessageTypeID COMMENT 'FK (implicit) to Dictionary.BSLMessageTypes.ID. Determines which type of BSL message is generated when this threshold is crossed: 1=Warning, 2=Liquidation, 3=Unblock. Multiple thresholds can map to the same message type (both alerts map to MessageTypeID=1). (Tier 1 - upstream wiki, etoro.Dictionary.BSLOperationThreshold)';
ALTER TABLE main.general.bronze_etoro_dictionary_bsloperationthreshold ALTER COLUMN Name COMMENT 'Human-readable label for the threshold (e.g., ''Liquidation'', ''First alert'', ''Second Alert'', ''Unblock''). Used in dashboards and configuration UIs. (Tier 1 - upstream wiki, etoro.Dictionary.BSLOperationThreshold)';
ALTER TABLE main.general.bronze_etoro_dictionary_bsloperationthreshold ALTER COLUMN ValueInPercent COMMENT 'The equity percentage that triggers this action. Read directly by trading procedures: Trade.InsertBSLMessagesIntoQueue reads all 4 values using SUM(IIF(ID = N, ValueInPercent, 0)), while Trade.GetMaxAmountToWithdraw reads the liquidation threshold and divides by 100 for ratio calculations. (Tier 1 - upstream wiki, etoro.Dictionary.BSLOperationThreshold)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
