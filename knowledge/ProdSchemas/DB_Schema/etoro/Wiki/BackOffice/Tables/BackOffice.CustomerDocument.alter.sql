-- =============================================================================
-- Databricks ALTER Script: bronze etoro.BackOffice.CustomerDocument
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_backoffice_customerdocument
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_backoffice_customerdocument (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocument SET TBLPROPERTIES (
    'comment' = 'Central repository of all KYC/AML identity documents submitted by customers for regulatory verification, storing metadata for 8.78M documents from 2009 to present. Source: etoro.BackOffice.CustomerDocument on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md).'
);

ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocument SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'BackOffice',
    'source_table' = 'CustomerDocument',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocument ALTER COLUMN DocumentID COMMENT 'Auto-generated unique document identifier. NC PK; the UNIQUE CLUSTERED index is on (CID, DocumentID) for customer-partitioned range scans. Referenced by BackOffice.CustomerDocumentToDocumentType, BackOffice.DocumentVendors, BackOffice.DocumentAuthenticationReasons, BackOffice.ZendeskDocuments. 13.4M issued (current max), 8.78M active. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocument)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocument ALTER COLUMN CID COMMENT 'Customer account ID - FK to Customer.CustomerStatic. The primary account the document belongs to. Combined with DocumentID as the unique clustered key (Idx_BackOffice_CustomerDocument_CID) for efficient per-customer document range scans. Note: GCID is used for cross-account person lookups. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocument)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocument ALTER COLUMN ManagerID COMMENT 'The BackOffice staff member who uploaded or processed this document. 0 = automated system upload (customer self-uploaded via portal or API). Non-zero = manual upload by a BackOffice agent (e.g., from fax, email, or Zendesk attachment). FK to BackOffice.Manager (no constraint). (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocument)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocument ALTER COLUMN DisplayName COMMENT 'The original filename as shown to BackOffice staff and in the document management UI. Preserves the customer''s original file name (e.g., "passport_scan.jpg", "utility_bill.pdf"). May differ from FileName if the storage layer renamed the file. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocument)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocument ALTER COLUMN ComputerName COMMENT 'Legacy field: the name of the computer/workstation from which the document was uploaded. Populated when BackOffice staff uploaded documents from named workstations in older versions of the BackOffice system. In modern automated uploads this may be the hostname of the application server. Not used in current queries. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocument)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocument ALTER COLUMN FileName COMMENT 'The stored/persisted filename in the document management system. May differ from DisplayName if the storage layer applies naming conventions on upload. Used internally for file retrieval. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocument)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocument ALTER COLUMN DateAdded COMMENT 'Timestamp when the document was first uploaded/created in the system. Range from 2009-10-29 (platform launch) to today. Used in GetAllUserDocuments for date filtering (@minDateAdded parameter). Has composite index: (Comment, DateAdded, CID, StorageID) INCLUDE DocumentID for audit queries. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocument)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocument ALTER COLUMN Accounting COMMENT 'Flag intended to link a document to accounting processes. Default 0 and currently 0 for ALL 8.78M rows - this appears to be a planned feature that was never activated in production. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocument)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocument ALTER COLUMN Obsolete COMMENT 'Soft-delete flag: 1 = document has been superseded, found to be fraudulent, or otherwise invalidated. Set by BackOffice.CustomerDocumentObsoleteSign procedure. Only 249 of 8.78M documents are obsolete. GetAllUserDocuments returns the Obsolete flag so the UI can visually differentiate invalid documents. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocument)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocument ALTER COLUMN Comment COMMENT 'Optional BackOffice agent comment attached to the document at upload time. Returned by GetAllUserDocuments procedure. Has composite index (Comment, DateAdded, CID, StorageID) enabling comment-based audit searches. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocument)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocument ALTER COLUMN DocumentSizeActionTypeID COMMENT 'Status of the document''s compressed/thumbnail version in the processing pipeline. FK to Dictionary.DocumentSizeActionType. Values: 0="reduced size ready" (thumbnail generated - 99.9999% of docs), 1="no reduced size available" (compression not applicable), 2="not processed yet" (default on insert - processing pipeline pending). Default=2 then updated to 0/1 by processing job. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocument)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocument ALTER COLUMN StorageID COMMENT 'External document storage system reference key. Points to the actual file blob in the document storage service (CDN/blob storage). 99.9999% populated. NULL for 10 very old records (2009 era before storage system integration). The GetAllUserDocuments procedure filters WHERE StorageID IS NOT NULL, confirming NULL records are excluded from normal operations. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocument)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocument ALTER COLUMN SuggestedDocumentTypeID COMMENT 'AI vendor''s (Au10tix/Onfido) predicted document type classification. FK to Dictionary.DocumentType. Values: 1=Proof of Address, 2=Proof of Identity, 3=Credit Card, 4=Authorization Form, 5=Corporate doc (and more). Set by the automated document classification pipeline on upload. BackOffice agents confirm or override this via CustomerDocumentToDocumentType. 99.99% populated. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocument)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocument ALTER COLUMN SessionID COMMENT 'Upload session identifier from the customer''s document submission session. Correlates multiple documents uploaded in the same session (e.g., POI + POA submitted together in one KYC flow). Returned by GetAllUserDocuments for session-level tracing. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocument)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocument ALTER COLUMN SuggestedDocumentSubTypeID COMMENT 'AI vendor''s suggested document sub-classification (e.g., subtype of Proof of Identity: Passport vs Driver''s License vs National ID). Added by Onfido integration (COMOP-2473, 2021). Returned by GetAllUserDocuments. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocument)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocument ALTER COLUMN GCID COMMENT 'Group Customer ID - the person-level identifier that spans all of a customer''s accounts across regulatory jurisdictions. Links this document to ALL of the customer''s eToro accounts (eToro UK CID, eToro CySEC CID, etc.). 100% populated (8.78M/8.78M). Primary search key in GetAllUserDocuments (WHERE cc.GCID = @gcid). Has dedicated ix_CustomerDocuments_GCID index for fast person-level document retrieval. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocument)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
