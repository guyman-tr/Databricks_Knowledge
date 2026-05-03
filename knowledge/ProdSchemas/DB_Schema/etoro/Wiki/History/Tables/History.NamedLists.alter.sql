-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.NamedLists
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.NamedLists.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_namedlists
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_namedlists (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_namedlists SET TBLPROPERTIES (
    'comment' = 'SQL Server temporal history table automatically maintained by the database engine, recording every past state of CEP.NamedLists - the CEP (Customer Engagement Platform) configuration table that defines named customer segments and their SQL-based population queries. Source: etoro.History.NamedLists on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.NamedLists.md).'
);

ALTER TABLE main.general.bronze_etoro_history_namedlists SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'NamedLists',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_namedlists ALTER COLUMN NamedListID COMMENT 'The CEP named list identifier. Matches CEP.NamedLists.NamedListID (IDENTITY PK NOT FOR REPLICATION on the live table). Multiple history rows share the same NamedListID as each configuration change creates a new history entry. References the list whose configuration was active during [SysStartTime, SysEndTime). (Tier 1 - upstream wiki, etoro.History.NamedLists)';
ALTER TABLE main.general.bronze_etoro_history_namedlists ALTER COLUMN Name COMMENT 'The human-readable name of the named list. Examples from data: "Large AUM". Used in CEP UI and reports to identify the customer segment. Changes to Name generate a new temporal history row. (Tier 1 - upstream wiki, etoro.History.NamedLists)';
ALTER TABLE main.general.bronze_etoro_history_namedlists ALTER COLUMN Statment COMMENT 'The SQL expression or stored procedure call that defines the list''s population logic. Note: column name has a typo ("Statment" not "Statement"). Pattern: exec [CEP].[PR_Run_Statment] @ListID={N}, @DB=''etoro_repl'', @SERVER=''[AMS-REPL]'', @ListParameters=''''. The actual query is encapsulated in CEP.PR_Run_Statment. Changes to Statment are tracked for compliance and audit. (Tier 1 - upstream wiki, etoro.History.NamedLists)';
ALTER TABLE main.general.bronze_etoro_history_namedlists ALTER COLUMN PeriodicIntervalSec COMMENT 'How frequently (in seconds) the CEP scheduler should re-execute this list''s population query. 1700 seconds = ~28 minutes for "Large AUM". NULL if the list is not periodically refreshed (on-demand only). Changes to refresh frequency generate history entries. (Tier 1 - upstream wiki, etoro.History.NamedLists)';
ALTER TABLE main.general.bronze_etoro_history_namedlists ALTER COLUMN NamedListTypeID COMMENT 'The type/category of the named list. FK to Dictionary.CEPNamedListTypeID on the live table (no FK enforced in history). Classifies what kind of customer segment this is (e.g., campaign targeting, risk monitoring). Value 2 observed in data. (Tier 1 - upstream wiki, etoro.History.NamedLists)';
ALTER TABLE main.general.bronze_etoro_history_namedlists ALTER COLUMN LastUpdated COMMENT 'The last time the list was executed/populated (when CEP.NamedListRefresh last ran for this list). Distinct from ValidFrom (when the definition changed) - LastUpdated tracks operational execution, ValidFrom tracks configuration changes. (Tier 1 - upstream wiki, etoro.History.NamedLists)';
ALTER TABLE main.general.bronze_etoro_history_namedlists ALTER COLUMN ValidFrom COMMENT 'UTC timestamp of the last business-data change to this list definition (Name, Statment, PeriodicIntervalSec, NamedListTypeID). Updated by the CEPNamedListsUpdate trigger. Distinct from SysStartTime (which changes on any column update, even LastUpdated changes). (Tier 1 - upstream wiki, etoro.History.NamedLists)';
ALTER TABLE main.general.bronze_etoro_history_namedlists ALTER COLUMN DbLoginName COMMENT 'The SQL Server login name of the session that last changed this row. Computed column on the live table (= suser_name()). Captured at change time and stored in history. Identifies the database-level operator. (Tier 1 - upstream wiki, etoro.History.NamedLists)';
ALTER TABLE main.general.bronze_etoro_history_namedlists ALTER COLUMN AppLoginName COMMENT 'The application-level identity from context_info(). Computed column on live table. The CEP application sets context_info() before DML to record who is making the change (e.g., the user in the CEP admin UI). NULL if context_info was not set. (Tier 1 - upstream wiki, etoro.History.NamedLists)';
ALTER TABLE main.general.bronze_etoro_history_namedlists ALTER COLUMN SysStartTime COMMENT 'UTC timestamp when this row version became current in CEP.NamedLists. Populated automatically by SQL Server SYSTEM_VERSIONING (GENERATED ALWAYS AS ROW START). (Tier 1 - upstream wiki, etoro.History.NamedLists)';
ALTER TABLE main.general.bronze_etoro_history_namedlists ALTER COLUMN SysEndTime COMMENT 'UTC timestamp when this row version was superseded and moved to history. The interval [SysStartTime, SysEndTime) is the period during which this named list configuration was active. (Tier 1 - upstream wiki, etoro.History.NamedLists)';
ALTER TABLE main.general.bronze_etoro_history_namedlists ALTER COLUMN HostName COMMENT 'The machine name of the client that changed this row. Computed column on live table (= host_name()). Captured at change time and stored in history. (Tier 1 - upstream wiki, etoro.History.NamedLists)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
