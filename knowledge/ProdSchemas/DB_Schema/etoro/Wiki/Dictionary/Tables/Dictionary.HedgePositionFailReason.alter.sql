-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.HedgePositionFailReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgePositionFailReason.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_hedgepositionfailreason
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_hedgepositionfailreason (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_hedgepositionfailreason SET TBLPROPERTIES (
    'comment' = 'Lookup table defining 24 hedge position failure reasons — market conditions, liquidity issues, technical errors, and recovery-related failures that explain why a hedge order could not be executed at the liquidity provider. Source: etoro.Dictionary.HedgePositionFailReason on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgePositionFailReason.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_hedgepositionfailreason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'HedgePositionFailReason',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_hedgepositionfailreason ALTER COLUMN HedgeFailID COMMENT 'Primary key identifying the failure reason. 0=Unknown, 1-9=Market/trading failures (closed/slippage/liquidity/margin/size/indicative/expired/no price), 10=API error, 11=Trade not found, 12=Netted away, 13-14=DB close/open fail, 15=Recovery invalidated, 16=Provider closed, 17=DB SP error, 18-19=Qty/duplicate, 20=Amount too low, 21=General, 22=GTD expired, 23=Cancellation sent. (Tier 1 - upstream wiki, etoro.Dictionary.HedgePositionFailReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_hedgepositionfailreason ALTER COLUMN HedgePositionFailSeverity COMMENT 'Severity classification of this failure reason. FK to Dictionary.HedgePositionFailSeverity. 1=None/NoProblem (informational), 2=Low/Warning, 3=Medium (investigate), 4=High, 5=Critical (alert immediately), 6=Unknown/TBD. Determines alerting thresholds and escalation paths. (Tier 1 - upstream wiki, etoro.Dictionary.HedgePositionFailReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_hedgepositionfailreason ALTER COLUMN FailText COMMENT 'Human-readable description of the failure. Displayed in hedge monitoring dashboards, alert emails, and operational reports. Provides sufficient context for operators to understand what happened without querying logs. (Tier 1 - upstream wiki, etoro.Dictionary.HedgePositionFailReason)';

