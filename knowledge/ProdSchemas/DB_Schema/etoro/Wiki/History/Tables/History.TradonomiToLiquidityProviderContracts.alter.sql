-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.TradonomiToLiquidityProviderContracts
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.TradonomiToLiquidityProviderContracts.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_tradonomitoliquidityprovidercontracts
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_tradonomitoliquidityprovidercontracts (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_tradonomitoliquidityprovidercontracts SET TBLPROPERTIES (
    'comment' = 'SQL Server system-versioned temporal history table for Trade.TradonomiToLiquidityProviderContracts - stores superseded mappings linking Tradonomi CFD contracts to specific liquidity provider contracts. Source: etoro.History.TradonomiToLiquidityProviderContracts on the etoro production database, ingested via the Generic Pipeline (Append strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.TradonomiToLiquidityProviderContracts.md).'
);

ALTER TABLE main.general.bronze_etoro_history_tradonomitoliquidityprovidercontracts SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'TradonomiToLiquidityProviderContracts',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_tradonomitoliquidityprovidercontracts ALTER COLUMN TradonomiContractID COMMENT 'Identifier of the Tradonomi CFD contract (references Trade.TradonomiContracts.ContractID in source). The Tradonomi contract being mapped to a liquidity provider. (Tier 1 - upstream wiki, etoro.History.TradonomiToLiquidityProviderContracts)';
ALTER TABLE main.general.bronze_etoro_history_tradonomitoliquidityprovidercontracts ALTER COLUMN LiquidityProviderContractID COMMENT 'Identifier of the external liquidity provider contract that backs the Tradonomi contract. Application-managed reference. (Tier 1 - upstream wiki, etoro.History.TradonomiToLiquidityProviderContracts)';
ALTER TABLE main.general.bronze_etoro_history_tradonomitoliquidityprovidercontracts ALTER COLUMN DbLoginName COMMENT 'SQL Server login that made the change (suser_name() at DML time). Preserved for change attribution. (Tier 1 - upstream wiki, etoro.History.TradonomiToLiquidityProviderContracts)';
ALTER TABLE main.general.bronze_etoro_history_tradonomitoliquidityprovidercontracts ALTER COLUMN AppLoginName COMMENT 'Application login from context_info() at DML time. Identifies the calling service or admin tool. (Tier 1 - upstream wiki, etoro.History.TradonomiToLiquidityProviderContracts)';
ALTER TABLE main.general.bronze_etoro_history_tradonomitoliquidityprovidercontracts ALTER COLUMN SysStartTime COMMENT 'UTC timestamp when this mapping became active. SQL Server system-versioning managed. (Tier 1 - upstream wiki, etoro.History.TradonomiToLiquidityProviderContracts)';
ALTER TABLE main.general.bronze_etoro_history_tradonomitoliquidityprovidercontracts ALTER COLUMN SysEndTime COMMENT 'UTC timestamp when this mapping was superseded. Clustered index leading column. (Tier 1 - upstream wiki, etoro.History.TradonomiToLiquidityProviderContracts)';

