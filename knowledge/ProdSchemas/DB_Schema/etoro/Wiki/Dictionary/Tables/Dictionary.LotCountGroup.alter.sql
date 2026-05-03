-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.LotCountGroup
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.LotCountGroup.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_lotcountgroup
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_lotcountgroup (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_lotcountgroup SET TBLPROPERTIES (
    'comment' = 'Maps lot count groups to eToro Club player levels, enabling tier-based position sizing rules across the platform. Source: etoro.Dictionary.LotCountGroup on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.LotCountGroup.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_lotcountgroup SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'LotCountGroup',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_lotcountgroup ALTER COLUMN LotCountGroupID COMMENT 'Unique identifier for the lot count group tier. Values 0 - 4 map to Bronze/Silver/Gold/Platinum/Test. Referenced by BackOffice.SetLotCountGroupID and customer tier assignment logic. (Tier 1 - upstream wiki, etoro.Dictionary.LotCountGroup)';
ALTER TABLE main.general.bronze_etoro_dictionary_lotcountgroup ALTER COLUMN LotCountGroupName COMMENT 'Human-readable tier name: "Group Bronze", "Group Silver", "Group Gold", "Group Platinum", "Group Test". Used in BackOffice displays and reporting. (Tier 1 - upstream wiki, etoro.Dictionary.LotCountGroup)';
ALTER TABLE main.general.bronze_etoro_dictionary_lotcountgroup ALTER COLUMN PlayerLevelID COMMENT 'FK to Dictionary.PlayerLevel. Maps this lot count group to an eToro Club membership tier. Values: 1=Bronze, 5=Silver, 3=Gold, 2=Platinum, 4=Test. See Player Level. (Tier 1 - upstream wiki, etoro.Dictionary.LotCountGroup)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
