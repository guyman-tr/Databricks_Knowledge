-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Tribe.AccountsActivities_RiskActions-322546
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.AccountsActivities_RiskActions-322546.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546 (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546 SET TBLPROPERTIES (
    'comment' = 'Child table storing risk action details from Tribe account activity records, containing risk rule evaluations triggered during transaction processing. Source: FiatDwhDB.Tribe.AccountsActivities_RiskActions-322546 on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.AccountsActivities_RiskActions-322546.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546 SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Tribe',
    'source_table' = 'AccountsActivities_RiskActions-322546',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546 ALTER COLUMN @Created COMMENT 'DWH insertion timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_RiskActions-322546)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546 ALTER COLUMN @Id COMMENT 'Unique record identifier. PK. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_RiskActions-322546)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546 ALTER COLUMN @AccountsActivities@Id-862157 COMMENT 'FK to parent Tribe.AccountsActivities-862157. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_RiskActions-322546)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546 ALTER COLUMN Created COMMENT 'Source system timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_RiskActions-322546)';

