-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_etoro_backoffice_tncdocument  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN DocumentID COMMENT 'Surrogate PK. Auto-incremented. NOT FOR REPLICATION. Uniquely identifies each T&C document entry. Referenced by BackOffice.ZendeskDocuments.';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN RegulationID COMMENT 'The regulatory jurisdiction this document applies to. Maps to Dictionary.Regulation.ID values (1=CySEC, 2=FCA, 4=ASIC, 5=BVI, 6=eToroUS, etc.). Customers are shown the document matching their regulation.';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN ManagerID COMMENT 'The back-office manager who uploaded this document. Audit trail reference to BackOffice.Manager.ManagerID.';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN DisplayName COMMENT 'Human-readable name shown to customers in the T&C acceptance UI (e.g., "Terms and Conditions - CySEC").';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN ComputerName COMMENT 'Hostname of the machine from which the document was uploaded. Used for upload audit trail.';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN FileName COMMENT 'Physical filename/path of the PDF in storage. Format: `{RegulationID}-{timestamp}-{original_name}.pdf`. Used by StorageID to locate the file.';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN DateAdded COMMENT 'Timestamp when this document was uploaded/registered. Earliest records from 2015-05-03.';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN StorageID COMMENT 'Reference to the external storage system record (blob store or file share). Used with FileName to retrieve the actual PDF.';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN TncDocTypeID COMMENT 'FK to Dictionary.TncDocType. Classifies the document type. Default=1 (main Terms & Conditions). Other values may represent product-specific or jurisdictional addenda.';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN Enabled COMMENT '1=Document is active and visible to customers. 0=Document is suppressed/hidden without deletion. Can be toggled independently of IsActive.';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN IsActive COMMENT '1=Document is the current valid version. 0=Document has been superseded by a newer version (set by TncDocumentUpdateIsActive). Used with Enabled to determine if document is served to customers.';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN CountryID COMMENT 'FK to Dictionary.Country. If non-NULL, this document applies only to customers in the specified country within the regulation. NULL=applies to all countries in the regulation. Enables country-specific T&C overrides.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:26:31 UTC
-- Statements: 12/12 succeeded
-- ====================
