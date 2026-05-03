-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.MatchStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.MatchStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_matchstatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_matchstatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_matchstatus SET TBLPROPERTIES (
    'comment' = 'Defines the reconciliation match states for billing deposits and withdrawal-to-funding transactions, tracking whether financial records have been verified against external payment provider data. Source: etoro.Dictionary.MatchStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.MatchStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_matchstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'MatchStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_matchstatus ALTER COLUMN MatchStatusID COMMENT 'Unique identifier for the reconciliation state: 0=UnMatched (Open), 1=UnMatched (Closed), 2=UnMatched (Old), 3=Matched (Automatically), 4=Matched (Manually), 5=Matched (With Difference), 6=Matched (Offline Approval). Referenced by Billing.Deposit, Billing.WithdrawToFunding, and 30+ billing procedures. (Tier 1 - upstream wiki, etoro.Dictionary.MatchStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_matchstatus ALTER COLUMN Name COMMENT 'Human-readable reconciliation state label. Enforced unique by UK_DMS_Name. Displayed in billing reconciliation reports and BackOffice screens. (Tier 1 - upstream wiki, etoro.Dictionary.MatchStatus)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
