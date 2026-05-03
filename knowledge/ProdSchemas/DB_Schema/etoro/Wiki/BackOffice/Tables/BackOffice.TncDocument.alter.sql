-- =============================================================================
-- Databricks ALTER Script: bronze etoro.BackOffice.TncDocument
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_backoffice_tncdocument
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_backoffice_tncdocument (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument SET TBLPROPERTIES (
    'comment' = 'Registry of Terms & Conditions documents uploaded by back-office managers, organized by regulatory jurisdiction and country, with active/enabled flags controlling customer visibility. Source: etoro.BackOffice.TncDocument on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'BackOffice',
    'source_table' = 'TncDocument',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN DocumentID COMMENT 'Surrogate PK. Auto-incremented. NOT FOR REPLICATION. Uniquely identifies each T&C document entry. Referenced by BackOffice.ZendeskDocuments. (Tier 1 - upstream wiki, etoro.BackOffice.TncDocument)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN RegulationID COMMENT 'The regulatory jurisdiction this document applies to. Maps to Dictionary.Regulation.ID values (1=CySEC, 2=FCA, 4=ASIC, 5=BVI, 6=eToroUS, etc.). Customers are shown the document matching their regulation. (Tier 1 - upstream wiki, etoro.BackOffice.TncDocument)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN ManagerID COMMENT 'The back-office manager who uploaded this document. Audit trail reference to BackOffice.Manager.ManagerID. (Tier 1 - upstream wiki, etoro.BackOffice.TncDocument)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN DisplayName COMMENT 'Human-readable name shown to customers in the T&C acceptance UI (e.g., "Terms and Conditions - CySEC"). (Tier 1 - upstream wiki, etoro.BackOffice.TncDocument)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN ComputerName COMMENT 'Hostname of the machine from which the document was uploaded. Used for upload audit trail. (Tier 1 - upstream wiki, etoro.BackOffice.TncDocument)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN FileName COMMENT 'Physical filename/path of the PDF in storage. Format: {RegulationID}-{timestamp}-{original_name}.pdf. Used by StorageID to locate the file. (Tier 1 - upstream wiki, etoro.BackOffice.TncDocument)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN DateAdded COMMENT 'Timestamp when this document was uploaded/registered. Earliest records from 2015-05-03. (Tier 1 - upstream wiki, etoro.BackOffice.TncDocument)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN StorageID COMMENT 'Reference to the external storage system record (blob store or file share). Used with FileName to retrieve the actual PDF. (Tier 1 - upstream wiki, etoro.BackOffice.TncDocument)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN TncDocTypeID COMMENT 'FK to Dictionary.TncDocType. Classifies the document type. Default=1 (main Terms & Conditions). Other values may represent product-specific or jurisdictional addenda. (Tier 1 - upstream wiki, etoro.BackOffice.TncDocument)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN Enabled COMMENT '1=Document is active and visible to customers. 0=Document is suppressed/hidden without deletion. Can be toggled independently of IsActive. (Tier 1 - upstream wiki, etoro.BackOffice.TncDocument)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN IsActive COMMENT '1=Document is the current valid version. 0=Document has been superseded by a newer version (set by TncDocumentUpdateIsActive). Used with Enabled to determine if document is served to customers. (Tier 1 - upstream wiki, etoro.BackOffice.TncDocument)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_tncdocument ALTER COLUMN CountryID COMMENT 'FK to Dictionary.Country. If non-NULL, this document applies only to customers in the specified country within the regulation. NULL=applies to all countries in the regulation. Enables country-specific T&C overrides. (Tier 1 - upstream wiki, etoro.BackOffice.TncDocument)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
