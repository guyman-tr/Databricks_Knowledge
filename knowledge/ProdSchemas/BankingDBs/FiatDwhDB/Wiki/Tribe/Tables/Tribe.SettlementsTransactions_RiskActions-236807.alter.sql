-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.SettlementsTransactions_RiskActions-236807.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807 (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807 SET TBLPROPERTIES (
    'comment' = 'Child table storing risk action records from Tribe settlement transaction files. Parent: SettlementsTransactions-333243. Source: FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.SettlementsTransactions_RiskActions-236807.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807 SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Tribe',
    'source_table' = 'SettlementsTransactions_RiskActions-236807',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807 ALTER COLUMN @Created COMMENT 'DWH timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807 ALTER COLUMN @Id COMMENT 'PK. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807 ALTER COLUMN @SettlementsTransactions@Id-333243 COMMENT 'FK to parent. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807 ALTER COLUMN Created COMMENT 'Source timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807)';

