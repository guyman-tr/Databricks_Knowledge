-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.dbo.FiatCurrencyBalancesStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCurrencyBalancesStatuses.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalancesstatuses
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalancesstatuses (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalancesstatuses SET TBLPROPERTIES (
    'comment' = 'Event-sourced status history table tracking all lifecycle changes for currency balances, including the source and reason for each change. Source: FiatDwhDB.dbo.FiatCurrencyBalancesStatuses on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCurrencyBalancesStatuses.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalancesstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'dbo',
    'source_table' = 'FiatCurrencyBalancesStatuses',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalancesstatuses ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCurrencyBalancesStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalancesstatuses ALTER COLUMN CurrencyBalancesId COMMENT 'FK to dbo.FiatCurrencyBalances.Id. The balance whose status changed. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCurrencyBalancesStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalancesstatuses ALTER COLUMN StatusType COMMENT 'Balance status: 0=Active, 1=ReceiveOnly, 2=SpendOnly, 3=Suspended, 4=Blocked. See Currency Balance Status. (Dictionary.CurrencyBalanceStatuses) (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCurrencyBalancesStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalancesstatuses ALTER COLUMN EventTimestamp COMMENT 'When the status change occurred in the source system. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCurrencyBalancesStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalancesstatuses ALTER COLUMN Created COMMENT 'When this record was written to the DWH. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCurrencyBalancesStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalancesstatuses ALTER COLUMN StatusChangeSourceId COMMENT 'Who initiated the change: 0-4. See Status Change Source. (Dictionary.StatusChangeSources). Nullable for legacy records. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCurrencyBalancesStatuses)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dbo_fiatcurrencybalancesstatuses ALTER COLUMN StatusChangeReasonId COMMENT 'Why the change was made: 0-19. See Status Change Reason. (Dictionary.StatusChangeReasons). Nullable for legacy records. (Tier 1 - upstream wiki, FiatDwhDB.dbo.FiatCurrencyBalancesStatuses)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:05:44 UTC
-- Bronze deploy: FiatDwhDB batch 1
-- ====================
