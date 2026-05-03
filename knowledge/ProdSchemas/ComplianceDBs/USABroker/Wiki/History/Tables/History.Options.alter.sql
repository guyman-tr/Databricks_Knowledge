-- =============================================================================
-- Databricks ALTER Script: bronze USABroker.History.Options
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/History/Tables/History.Options.md
-- Layer: bronze
-- UC Target: main.general.bronze_usabroker_history_options
-- =============================================================================

-- ---- UC Target: main.general.bronze_usabroker_history_options (business_group=general) ----
ALTER TABLE main.general.bronze_usabroker_history_options SET TBLPROPERTIES (
    'comment' = 'System-versioned temporal history table that automatically stores previous versions of Apex.Options rows when they are updated, providing a complete audit trail of options trading eligibility, appropriateness, and approval status changes. Source: USABroker.History.Options on the USABroker production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/History/Tables/History.Options.md).'
);

ALTER TABLE main.general.bronze_usabroker_history_options SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'USABroker',
    'source_schema' = 'History',
    'source_table' = 'Options',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_usabroker_history_options ALTER COLUMN GCID COMMENT 'Global Customer ID. Same value as Apex.Options.GCID at the time this version was active. (Tier 1 - upstream wiki, USABroker.History.Options)';
ALTER TABLE main.general.bronze_usabroker_history_options ALTER COLUMN AppropriatenessTestResultID COMMENT 'Result of the suitability/appropriateness assessment AT THE TIME this version was active. 0=None, 1=Failed, 2=Passed. See Appropriateness Test Result. (Tier 1 - upstream wiki, USABroker.History.Options)';
ALTER TABLE main.general.bronze_usabroker_history_options ALTER COLUMN AppropriatenessProductID COMMENT 'The financial product being assessed for appropriateness at the time this version was active. See Appropriateness Product. (Tier 1 - upstream wiki, USABroker.History.Options)';
ALTER TABLE main.general.bronze_usabroker_history_options ALTER COLUMN AppropriatenessRecalculationReasonID COMMENT 'Reason why the appropriateness test was recalculated at the time this version was active. See Appropriateness Recalculation Reason. (Tier 1 - upstream wiki, USABroker.History.Options)';
ALTER TABLE main.general.bronze_usabroker_history_options ALTER COLUMN EligibilityStatusID COMMENT 'Whether the customer was eligible for options trading at the time this version was active. 0=Disallowed, 1=Allowed. See Eligibility Status. (Tier 1 - upstream wiki, USABroker.History.Options)';
ALTER TABLE main.general.bronze_usabroker_history_options ALTER COLUMN EligibilityStatusReasonID COMMENT 'The specific reason for the eligibility determination at the time this version was active. (Tier 1 - upstream wiki, USABroker.History.Options)';
ALTER TABLE main.general.bronze_usabroker_history_options ALTER COLUMN OptionsStatusID COMMENT 'The Apex Clearing approval status for options trading AT THE TIME this version was active. 0=None, 1=Pending, 2=InProcess, 3=Approved, 4=Rejected. See Options Status. (Tier 1 - upstream wiki, USABroker.History.Options)';
ALTER TABLE main.general.bronze_usabroker_history_options ALTER COLUMN OptionsApexID COMMENT 'The Apex Clearing identifier for the options application at the time this version was active. NULL until an application was sent to Apex. (Tier 1 - upstream wiki, USABroker.History.Options)';
ALTER TABLE main.general.bronze_usabroker_history_options ALTER COLUMN ApplicationName COMMENT 'Name of the service/application that last modified the record at the time this version was written. (Tier 1 - upstream wiki, USABroker.History.Options)';
ALTER TABLE main.general.bronze_usabroker_history_options ALTER COLUMN OptionsStatusControlID COMMENT 'Administrative override for options trading access at the time this version was active. 0=None, 1=Blocked, 2=Allowed. See Options Status Control. (Tier 1 - upstream wiki, USABroker.History.Options)';
ALTER TABLE main.general.bronze_usabroker_history_options ALTER COLUMN BeginTime COMMENT 'When this version became active (was originally written to Apex.Options). Part of the temporal period. (Tier 1 - upstream wiki, USABroker.History.Options)';
ALTER TABLE main.general.bronze_usabroker_history_options ALTER COLUMN EndTime COMMENT 'When this version was superseded by a newer version. The update timestamp. Part of the temporal period. Clustered index key (EndTime, BeginTime). (Tier 1 - upstream wiki, USABroker.History.Options)';
ALTER TABLE main.general.bronze_usabroker_history_options ALTER COLUMN ReasoningStatusID COMMENT 'Status of the options reasoning form workflow at the time this version was active. See Reasoning Status. (Tier 1 - upstream wiki, USABroker.History.Options)';
ALTER TABLE main.general.bronze_usabroker_history_options ALTER COLUMN ReasoningFormID COMMENT 'GUID linking to the reasoning form instance active at the time this version was written. (Tier 1 - upstream wiki, USABroker.History.Options)';
ALTER TABLE main.general.bronze_usabroker_history_options ALTER COLUMN AppropriatenessTestDate COMMENT 'Timestamp of when the appropriateness test was last taken or recalculated as of this version. (Tier 1 - upstream wiki, USABroker.History.Options)';
ALTER TABLE main.general.bronze_usabroker_history_options ALTER COLUMN StocksElegibilityStatusID COMMENT 'Eligibility status for stock trading at the time this version was active. 0=Disallowed, 1=Allowed. Note: column name has typo "Elegibility". (Tier 1 - upstream wiki, USABroker.History.Options)';
ALTER TABLE main.general.bronze_usabroker_history_options ALTER COLUMN CryptoElegibilityStatusID COMMENT 'Eligibility status for cryptocurrency trading at the time this version was active. 0=Disallowed, 1=Allowed. Note: column name has typo "Elegibility". (Tier 1 - upstream wiki, USABroker.History.Options)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:47:20 UTC
-- Bronze deploy: USABroker batch 1
-- ====================
