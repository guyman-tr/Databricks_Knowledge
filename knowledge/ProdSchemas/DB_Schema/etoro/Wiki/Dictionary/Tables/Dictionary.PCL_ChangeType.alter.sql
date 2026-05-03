-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PCL_ChangeType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PCL_ChangeType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_pcl_changetype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_pcl_changetype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_pcl_changetype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining 15 position change log (PCL) event types - tracking every modification to a position from open through close, including SL/TP edits, fee charges, mirror operations, partial closes, and data fixes. Source: etoro.Dictionary.PCL_ChangeType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PCL_ChangeType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_pcl_changetype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PCL_ChangeType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_pcl_changetype ALTER COLUMN ChangeTypeID COMMENT 'Primary key identifying the PCL change type. 0=Open Position, 1=Edit Stop Loss, 2=Edit Take Profit, 3=Edit Over Weekend, 4=EOW Fee, 5=Detach from Mirror, 6=Close Position, 7=Enable/Disable TSL, 8=PositionRedeemCancel, 9=PositionRedeemPending, 10=PositionRedeemClose, 11=Partial close, 12=Edit due to partial close, 13=Edit Is Settled, 14=Data Fix. Used in Trade.PostDetachOperation, Trade.GetPositionsChangesForDataApi, and failure dashboards. (Tier 1 - upstream wiki, etoro.Dictionary.PCL_ChangeType)';
ALTER TABLE main.general.bronze_etoro_dictionary_pcl_changetype ALTER COLUMN ChangeTypeName COMMENT 'Human-readable description of the change type. Displayed in position audit reports, API responses, and SSRS dashboards. (Tier 1 - upstream wiki, etoro.Dictionary.PCL_ChangeType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
