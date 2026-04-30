-- =============================================================================
-- Databricks ALTER Script: bronze USABroker.apex.SketchInvestigationDoNotAppealReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.SketchInvestigationDoNotAppealReason.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason SET TBLPROPERTIES (
    'comment' = 'Records specific CIP investigation failure reasons from Sketch/Equifax that prevent automatic appeal, creating a per-customer audit trail of identity verification blockers. Source: USABroker.apex.SketchInvestigationDoNotAppealReason on the USABroker production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.SketchInvestigationDoNotAppealReason.md).'
);

ALTER TABLE main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'USABroker',
    'source_schema' = 'apex',
    'source_table' = 'SketchInvestigationDoNotAppealReason',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason ALTER COLUMN ID COMMENT 'Auto-incrementing surrogate primary key. ~42K records to date. (Tier 1 - upstream wiki, USABroker.apex.SketchInvestigationDoNotAppealReason)';
ALTER TABLE main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason ALTER COLUMN GCID COMMENT 'Global Customer ID of the customer whose investigation produced this do-not-appeal reason. (Tier 1 - upstream wiki, USABroker.apex.SketchInvestigationDoNotAppealReason)';
ALTER TABLE main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason ALTER COLUMN ApexID COMMENT 'The customer''s Apex Clearing account ID. Stored here for direct reference without needing to JOIN to ApexData. (Tier 1 - upstream wiki, USABroker.apex.SketchInvestigationDoNotAppealReason)';
ALTER TABLE main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason ALTER COLUMN SketchID COMMENT 'GUID of the Sketch investigation that produced this reason. Multiple reasons can share the same SketchID when the investigation returned multiple blockers. (Tier 1 - upstream wiki, USABroker.apex.SketchInvestigationDoNotAppealReason)';
ALTER TABLE main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason ALTER COLUMN ReasonTypeID COMMENT 'Category of the investigation reason. FK to Dictionary.SketchInvestigationReasonType: 0=None, 1=Indeterminate (inconclusive), 2=Reject (definitive failure). See Sketch Investigation Reason Type. All observed data shows ReasonTypeID=2 (Reject). (Dictionary.SketchInvestigationReasonType) (Tier 1 - upstream wiki, USABroker.apex.SketchInvestigationDoNotAppealReason)';
ALTER TABLE main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason ALTER COLUMN ReasonConstant COMMENT 'Machine-readable constant identifying the specific reason. Maps to constants in the Sketch/Equifax API. Examples: SSN_FRAUD_VICTIM, DOB_NO_SSN_RELATION_FOUND, ADDRESS_NOT_VERIFIED, ADDRESS_NONRESIDENTIAL. Used for programmatic handling and matching against Apex.SketchInvestigationReason configuration. (Tier 1 - upstream wiki, USABroker.apex.SketchInvestigationDoNotAppealReason)';
ALTER TABLE main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason ALTER COLUMN SketchDataSource COMMENT 'The data bureau that provided this verification result. Observed value: "Equifax". Identifies which third-party data source flagged the issue. (Tier 1 - upstream wiki, USABroker.apex.SketchInvestigationDoNotAppealReason)';
ALTER TABLE main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason ALTER COLUMN ReasonDescription COMMENT 'Human-readable description of the verification failure. Examples: "Applicant profile contains a fraud victim warning", "SSN could not be verified to the date of birth provided". NULL is allowed but typically populated from the Sketch API response. (Tier 1 - upstream wiki, USABroker.apex.SketchInvestigationDoNotAppealReason)';

