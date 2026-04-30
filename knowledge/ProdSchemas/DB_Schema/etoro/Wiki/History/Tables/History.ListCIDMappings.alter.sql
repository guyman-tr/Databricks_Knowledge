-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.ListCIDMappings
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ListCIDMappings.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_listcidmappings
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_listcidmappings (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_listcidmappings SET TBLPROPERTIES (
    'comment' = 'SQL Server temporal history table automatically maintained by the database engine, recording every past state of CEP.ListCIDMappings - the Customer Engagement Platform table mapping individual customers (CIDs) to named targeting lists. Source: etoro.History.ListCIDMappings on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ListCIDMappings.md).'
);

ALTER TABLE main.general.bronze_etoro_history_listcidmappings SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'ListCIDMappings',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_listcidmappings ALTER COLUMN NamedListID COMMENT 'The CEP named list this customer belonged to. FK to CEP.NamedLists on the live table (not enforced in history). Matches CEP.NamedLists.NamedListID. NamedListID=1="Large AUM", NamedListID=3=Bonus-only customers (critical: controls IsHedged flag), others as defined in CEP.NamedLists. Part of the composite PK on the live table: (NamedListID, CID). (Tier 1 - upstream wiki, etoro.History.ListCIDMappings)';
ALTER TABLE main.general.bronze_etoro_history_listcidmappings ALTER COLUMN CID COMMENT 'The customer who was a member of this named list. FK to Customer.CustomerStatic enforced on the live table (not in history). Multiple history rows with the same CID represent the customer''s membership history across different lists or different time periods. (Tier 1 - upstream wiki, etoro.History.ListCIDMappings)';
ALTER TABLE main.general.bronze_etoro_history_listcidmappings ALTER COLUMN ValidFrom COMMENT 'Business timestamp of when this CID was added to the named list. DEFAULT getutcdate() on the live table. Set on INSERT and preserved unchanged in history. May differ from SysStartTime (which reflects the temporal row version start after the INSERT trigger''s no-op UPDATE). Legacy rows may show ValidFrom dates from 2012 while SysStartTime reflects when temporal versioning was enabled. (Tier 1 - upstream wiki, etoro.History.ListCIDMappings)';
ALTER TABLE main.general.bronze_etoro_history_listcidmappings ALTER COLUMN DbLoginName COMMENT 'SQL Server login that changed this list membership. Computed column on live table (= suser_name()); stored as snapshot in history. Values: "DEV\trading_services" (automated scheduler), "TRAD\orshoh" (manual CEP admin action). Identifies the database session responsible for the add/remove. (Tier 1 - upstream wiki, etoro.History.ListCIDMappings)';
ALTER TABLE main.general.bronze_etoro_history_listcidmappings ALTER COLUMN AppLoginName COMMENT 'CEP application user who triggered the change. Computed column on live table (= CONVERT(varchar(500), context_info())). Set by CEP.ArchiveListCIDMapping via SET CONTEXT_INFO before DELETE. Stored null-padded to 128 bytes (context_info buffer size) then stored as varchar(500). NULL when automated scheduler runs without application context. (Tier 1 - upstream wiki, etoro.History.ListCIDMappings)';
ALTER TABLE main.general.bronze_etoro_history_listcidmappings ALTER COLUMN SysStartTime COMMENT 'UTC timestamp when this membership row version became current in CEP.ListCIDMappings. For newly inserted CIDs: reflects the INSERT trigger''s no-op UPDATE timestamp (milliseconds after actual INSERT). Populated automatically by SQL Server SYSTEM_VERSIONING. (Tier 1 - upstream wiki, etoro.History.ListCIDMappings)';
ALTER TABLE main.general.bronze_etoro_history_listcidmappings ALTER COLUMN SysEndTime COMMENT 'UTC timestamp when this customer''s membership in the named list ended (was removed). All 52 NamedListID=1 history rows share SysEndTime="2024-11-06 11:24:39" - confirming they were removed in a single batch refresh operation. SysEndTime=SysStartTime indicates an immediately-superseded row (INSERT trigger pattern). (Tier 1 - upstream wiki, etoro.History.ListCIDMappings)';

