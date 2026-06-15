-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Apex/Tables/Apex.SketchInvestigationDoNotAppealReason.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason ALTER COLUMN ID COMMENT 'Auto-incrementing surrogate primary key. ~42K records to date.';
ALTER TABLE main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason ALTER COLUMN GCID COMMENT 'Global Customer ID of the customer whose investigation produced this do-not-appeal reason.';
ALTER TABLE main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason ALTER COLUMN ApexID COMMENT 'The customer''s Apex Clearing account ID. Stored here for direct reference without needing to JOIN to ApexData.';
ALTER TABLE main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason ALTER COLUMN SketchID COMMENT 'GUID of the Sketch investigation that produced this reason. Multiple reasons can share the same SketchID when the investigation returned multiple blockers.';
ALTER TABLE main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason ALTER COLUMN ReasonTypeID COMMENT 'Category of the investigation reason. FK to Dictionary.SketchInvestigationReasonType: 0=None, 1=Indeterminate (inconclusive), 2=Reject (definitive failure). See [Sketch Investigation Reason Type](_glossary.md#sketch-investigation-reason-type). All observed data shows ReasonTypeID=2 (Reject). (Dictionary.SketchInvestigationReasonType)';
ALTER TABLE main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason ALTER COLUMN ReasonConstant COMMENT 'Machine-readable constant identifying the specific reason. Maps to constants in the Sketch/Equifax API. Examples: SSN_FRAUD_VICTIM, DOB_NO_SSN_RELATION_FOUND, ADDRESS_NOT_VERIFIED, ADDRESS_NONRESIDENTIAL. Used for programmatic handling and matching against Apex.SketchInvestigationReason configuration.';
ALTER TABLE main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason ALTER COLUMN SketchDataSource COMMENT 'The data bureau that provided this verification result. Observed value: "Equifax". Identifies which third-party data source flagged the issue.';
ALTER TABLE main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason ALTER COLUMN ReasonDescription COMMENT 'Human-readable description of the verification failure. Examples: "Applicant profile contains a fraud victim warning", "SSN could not be verified to the date of birth provided". NULL is allowed but typically populated from the Sketch API response.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:28:00 UTC
-- Statements: 8/8 succeeded
-- ====================
