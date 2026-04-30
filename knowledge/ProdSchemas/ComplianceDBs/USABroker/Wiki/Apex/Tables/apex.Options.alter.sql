-- =============================================================================
-- Databricks ALTER Script: bronze USABroker.apex.Options
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.Options.md
-- Layer: bronze
-- UC Target: main.general.bronze_usabroker_apex_options
-- =============================================================================

-- ---- UC Target: main.general.bronze_usabroker_apex_options (business_group=general) ----
ALTER TABLE main.general.bronze_usabroker_apex_options SET TBLPROPERTIES (
    'comment' = 'Comprehensive options trading record tracking each customer''s suitability assessment results, eligibility status, Apex approval status, and reasoning form workflow for options trading access. Source: USABroker.apex.Options on the USABroker production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.Options.md).'
);

ALTER TABLE main.general.bronze_usabroker_apex_options SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'USABroker',
    'source_schema' = 'apex',
    'source_table' = 'Options',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_usabroker_apex_options ALTER COLUMN GCID COMMENT 'Global Customer ID. Primary key - one options record per customer. Used as the lookup key by all Options procedures. (Tier 1 - upstream wiki, USABroker.apex.Options)';
ALTER TABLE main.general.bronze_usabroker_apex_options ALTER COLUMN AppropriatenessTestResultID COMMENT 'Result of the suitability/appropriateness assessment for options trading. FK to Dictionary.AppropriatenessTestResult: 0=None (not tested), 1=Failed (blocked), 2=Passed (approved). See Appropriateness Test Result. Set by SaveOptionsAppropriateness. (Dictionary.AppropriatenessTestResult) (Tier 1 - upstream wiki, USABroker.apex.Options)';
ALTER TABLE main.general.bronze_usabroker_apex_options ALTER COLUMN AppropriatenessProductID COMMENT 'The financial product being assessed for appropriateness. FK to Dictionary.AppropriatenessProduct: 0=None, 1=CFD, 2=FPSL, 3=Options. See Appropriateness Product. Set by SaveOptionsAppropriateness. (Dictionary.AppropriatenessProduct) (Tier 1 - upstream wiki, USABroker.apex.Options)';
ALTER TABLE main.general.bronze_usabroker_apex_options ALTER COLUMN AppropriatenessRecalculationReasonID COMMENT 'Reason why the appropriateness test was recalculated. Implicit FK to Dictionary.AppropriatenessRecalculationReason: 0=None, 1=BulkRecalculation, 2=RegulationChanged, 3=ReachedVerificationLevel2, 4=AnswerChanged, 5=Manual. See Appropriateness Recalculation Reason. Set by SaveOptionsAppropriateness. (Tier 1 - upstream wiki, USABroker.apex.Options)';
ALTER TABLE main.general.bronze_usabroker_apex_options ALTER COLUMN EligibilityStatusID COMMENT 'Whether the customer is eligible for options trading. FK to Dictionary.EligibilityStatus: 0=Disallowed, 1=Allowed. See Eligibility Status. Set by SaveOptionsEligibility. (Dictionary.EligibilityStatus) (Tier 1 - upstream wiki, USABroker.apex.Options)';
ALTER TABLE main.general.bronze_usabroker_apex_options ALTER COLUMN EligibilityStatusReasonID COMMENT 'Reference to the specific reason for the eligibility determination. Observed values include 4165 and 0. Not linked to a Dictionary table - likely references an internal reason code system. Set by SaveOptionsEligibility. (Tier 1 - upstream wiki, USABroker.apex.Options)';
ALTER TABLE main.general.bronze_usabroker_apex_options ALTER COLUMN OptionsStatusID COMMENT 'The Apex Clearing approval status for options trading. FK to Dictionary.OptionsStatus: 0=None, 1=Pending, 2=InProcess, 3=Approved, 4=Rejected. See Options Status. Only status 3 (Approved) enables options trading. Set by SaveOptionsStatus. (Dictionary.OptionsStatus) (Tier 1 - upstream wiki, USABroker.apex.Options)';
ALTER TABLE main.general.bronze_usabroker_apex_options ALTER COLUMN OptionsApexID COMMENT 'The Apex Clearing identifier for the options application/approval. Assigned by Apex when the options application is submitted. NULL until an application is sent to Apex. Indexed for reverse lookup by GetOptionsByOptionsApexId. Set by SaveOptionsStatus. (Tier 1 - upstream wiki, USABroker.apex.Options)';
ALTER TABLE main.general.bronze_usabroker_apex_options ALTER COLUMN ApplicationName COMMENT 'Name of the service/application that last modified this record. Acts as an audit trail for which system component made the most recent change. Known values: "UsaBroker", "WatchlistApi, watchlist-api", Jira ticket references for manual operations. Updated by every save procedure. (Tier 1 - upstream wiki, USABroker.apex.Options)';
ALTER TABLE main.general.bronze_usabroker_apex_options ALTER COLUMN OptionsStatusControlID COMMENT 'Administrative override for options trading access. FK to Dictionary.OptionsStatusControl: 0=None (no override), 1=Blocked (admin-blocked regardless of approval), 2=Allowed (admin-allowed). See Options Status Control. Set by SaveOptionsStatus. (Dictionary.OptionsStatusControl) (Tier 1 - upstream wiki, USABroker.apex.Options)';
ALTER TABLE main.general.bronze_usabroker_apex_options ALTER COLUMN BeginTime COMMENT 'System versioning row start time. Records when this version became active. Part of SYSTEM_TIME period for temporal table History.Options. (Tier 1 - upstream wiki, USABroker.apex.Options)';
ALTER TABLE main.general.bronze_usabroker_apex_options ALTER COLUMN EndTime COMMENT 'System versioning row end time. ''9999-12-31'' indicates current active row. Part of SYSTEM_TIME period. (Tier 1 - upstream wiki, USABroker.apex.Options)';
ALTER TABLE main.general.bronze_usabroker_apex_options ALTER COLUMN ReasoningStatusID COMMENT 'Status of the options reasoning form workflow. Implicit FK to Dictionary.ReasoningStatus: 0=None, 1=PendingReasoningScreen, 2=PendingManualReview, 3=Allowed, 4=DisallowedByManualReview. See Reasoning Status. NULL until reasoning workflow is initiated. Set by SaveOptionsReasoningStatus. (Tier 1 - upstream wiki, USABroker.apex.Options)';
ALTER TABLE main.general.bronze_usabroker_apex_options ALTER COLUMN ReasoningFormID COMMENT 'GUID linking to the specific reasoning form instance in Apex.OptionsReasoningForm. NULL until the user initiates a reasoning form submission. Set by SaveOptionsReasoningStatus. (Tier 1 - upstream wiki, USABroker.apex.Options)';
ALTER TABLE main.general.bronze_usabroker_apex_options ALTER COLUMN AppropriatenessTestDate COMMENT 'Timestamp of when the appropriateness/suitability test was last taken or recalculated. NULL if no test has been performed. Set by SaveOptionsAppropriateness. Used for regulatory record-keeping and determining when a retest may be required. (Tier 1 - upstream wiki, USABroker.apex.Options)';
ALTER TABLE main.general.bronze_usabroker_apex_options ALTER COLUMN StocksElegibilityStatusID COMMENT 'Eligibility status specifically for stock trading. Implicit FK to Dictionary.EligibilityStatus: 0=Disallowed, 1=Allowed. NULL for legacy records created before this column was added. Set by SaveOptionsEligibility. Note: column name has typo "Elegibility" instead of "Eligibility". (Tier 1 - upstream wiki, USABroker.apex.Options)';
ALTER TABLE main.general.bronze_usabroker_apex_options ALTER COLUMN CryptoElegibilityStatusID COMMENT 'Eligibility status specifically for cryptocurrency trading. Implicit FK to Dictionary.EligibilityStatus: 0=Disallowed, 1=Allowed. NULL for legacy records created before this column was added. Set by SaveOptionsEligibility. Note: column name has typo "Elegibility" instead of "Eligibility". (Tier 1 - upstream wiki, USABroker.apex.Options)';

