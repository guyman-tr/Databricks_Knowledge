-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.CEP_LOG_NamedLists
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CEP_LOG_NamedLists.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_cep_log_namedlists
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_cep_log_namedlists (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_cep_log_namedlists SET TBLPROPERTIES (
    'comment' = 'Trigger-based audit log capturing previous versions of CEP named list definitions; each row records a past state of a named list''s SQL statement, refresh interval, and type. Source: etoro.History.CEP_LOG_NamedLists on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CEP_LOG_NamedLists.md).'
);

ALTER TABLE main.general.bronze_etoro_history_cep_log_namedlists SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'CEP_LOG_NamedLists',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_cep_log_namedlists ALTER COLUMN NamedListID COMMENT 'Identifies the named list that was changed. References CEP.NamedLists. Part of composite PK. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_NamedLists)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_namedlists ALTER COLUMN Name COMMENT 'The human-readable name of the named list as it existed before this change. Examples: "Bonus traders", "US ILQ". (Tier 1 - upstream wiki, etoro.History.CEP_LOG_NamedLists)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_namedlists ALTER COLUMN Statment COMMENT 'The SQL statement executed to populate this list (for dynamic lists, NamedListTypeID=2). Note: misspelling of "Statement" preserved from DDL. Empty string for static lists. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_NamedLists)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_namedlists ALTER COLUMN PeriodicIntervalSec COMMENT 'For SQL-driven lists, how often (in seconds) the SQL statement is re-executed to refresh list membership. 60=refresh every minute. NULL or 0 for static lists. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_NamedLists)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_namedlists ALTER COLUMN NamedListTypeID COMMENT 'Type of named list: 1=static/simple list, 2=SQL-driven dynamic list (executes Statment on schedule). (Tier 1 - upstream wiki, etoro.History.CEP_LOG_NamedLists)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_namedlists ALTER COLUMN LastUpdated COMMENT 'Timestamp of the most recent list membership refresh at time of this change. May be NULL for lists that have never been refreshed. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_NamedLists)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_namedlists ALTER COLUMN ValidFrom COMMENT 'Timestamp when this named list version became active. Copied from parent row. Part of composite PK. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_NamedLists)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_namedlists ALTER COLUMN ValidTo COMMENT 'Timestamp when this named list was superseded. Defaults to getutcdate() at INSERT. Part of composite PK. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_NamedLists)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
