-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Dictionary_TribeScriptStatus
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_tribescriptstatus
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_tribescriptstatus SET TBLPROPERTIES (
    'comment' = '`eMoney_Dictionary_TribeScriptStatus` is a lookup/reference table that defines the valid approval workflow states for scripts executed against the Tribe provider system. Each row maps an integer ID to a human-readable status name. Tribe is the card-issuing and payment infrastructure provider for eToro Money; scripts queued for execution against Tribe follow a two-step approval gate before running. The 3 states represent the linear workflow: `Unapproved (0)` - script is pending review; `Approved (1)` - script has been authorized for execution; `Executed (2)` - script has been run against the Tribe system. Script status transitions are tracked in `Tribe.FilesScriptHistoryStatus` in FiatDwhDB. This dictionary is sourced from `FiatDwhDB.Dictionary.TribeScriptStatus` via Generic Pipeline Bronze export. All Synapse rows carry UpdateDate 2023-06-12 (single bulk load). Synapse: REPLICATE, HEAP.'
);

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_tribescriptstatus SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_tribescriptstatus ALTER COLUMN `TribeScriptStatusID` COMMENT 'Lookup identifier. Primary key. 0=Unapproved, 1=Approved, 2=Executed. (Tier 1 - Dictionary.TribeScriptStatus)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_tribescriptstatus ALTER COLUMN `TribeScriptStatus` COMMENT 'Human-readable name for this value. 0=Unapproved, 1=Approved, 2=Executed. (Tier 1 - Dictionary.TribeScriptStatus)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_tribescriptstatus ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 - Generic Pipeline)';

-- ---- Column PII Tags ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_tribescriptstatus ALTER COLUMN `TribeScriptStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_tribescriptstatus ALTER COLUMN `TribeScriptStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_tribescriptstatus ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
