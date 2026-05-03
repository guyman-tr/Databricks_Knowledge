-- =============================================================================
-- Databricks ALTER Script: bronze etoro.BackOffice.CustomerDocumentToDocumentType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype SET TBLPROPERTIES (
    'comment' = 'KYC document classification records linking uploaded customer documents to their assigned document types, with expiry dates, rejection reasons, and agent classification details. Source: etoro.BackOffice.CustomerDocumentToDocumentType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md).'
);

ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'BackOffice',
    'source_table' = 'CustomerDocumentToDocumentType',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype ALTER COLUMN DocumentToDocumentTypeID COMMENT 'Auto-generated unique classification record ID. NOT FOR REPLICATION. Clustered PK. Referenced by BackOffice.CustomerTranslationDetails (via DocumentToDocumentTypeID). (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocumentToDocumentType)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype ALTER COLUMN DocumentID COMMENT 'The document being classified. FK (WITH CHECK) to BackOffice.CustomerDocument(DocumentID). Multiple rows per DocumentID are allowed (re-classification history). Part of the UNIQUE constraint. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocumentToDocumentType)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype ALTER COLUMN DocumentTypeID COMMENT 'The formal document type assigned by the BackOffice agent or automation. FK (WITH CHECK) to Dictionary.DocumentType. Key values: 1=Proof of Address (7.5%), 2=Proof of Identity (59.8%), 3=Credit Card (1.0%), 6=Not Accepted - rejected (3.3%), 12=W-8BEN Form (7.7%), 14=W9 (18.1%), 15=Selfie, 17=VideoIdent, 18=SelfieLiveliness, 22=SSN Card. MaxAgeInMonths in Dictionary.DocumentType defines validity period. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocumentToDocumentType)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype ALTER COLUMN IssueDate COMMENT 'The date the document was issued (e.g., passport issue date). NULL for document types where issue date is not relevant (most POI records use ExpiryDate instead). For POA, IssueDate is when the utility bill/bank statement was issued. Part of the UNIQUE constraint to allow re-classification with different dates. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocumentToDocumentType)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype ALTER COLUMN ExpiryDate COMMENT 'The date after which this document classification is considered expired and must be re-submitted. Critical for passport expiry (POI), POA staleness (36 months), W-8BEN/W9 renewals. GetExpiredIdentityDocuments queries this field. Some rows have ExpiryDate=2034 as a sentinel "no expiry" value. Part of UNIQUE constraint. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocumentToDocumentType)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype ALTER COLUMN FundingID COMMENT 'Links this classification to a specific payment/funding record when the document is associated with a credit card or payment method verification (e.g., credit card copy). FK (WITH CHECK) to Billing.Funding(FundingID). NULL for 99% of rows - only populated for DocumentTypeID=3 (Credit Card) cases. Part of UNIQUE constraint. Filtered NC index for fast FundingID lookups. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocumentToDocumentType)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype ALTER COLUMN ManagerID COMMENT 'BackOffice agent who performed this classification. 0=Au10tix automated classification system. Non-zero=manual BackOffice agent (FK semantics to BackOffice.Manager, no constraint). NULL for 1 row only (data anomaly). (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocumentToDocumentType)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype ALTER COLUMN Comment COMMENT 'Agent''s note or automation message for this classification. Common values: "" (empty, BackOffice agent with no note), "Authenticate by au10tix" (automated), specific rejection explanation text. Max 1024 chars. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocumentToDocumentType)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype ALTER COLUMN RejectReasonID COMMENT 'Rejection reason when DocumentTypeID=6 (Not Accepted). Implicit FK to Dictionary.DocumentRejectReason. NULL for 96.7% of rows (approved/pending classifications). Top values: 15=POA cannot be accepted (34,289), 4=POI Expired (4,205), 38=SSN not acceptable (1,618), 14=POA missing address (1,090). See Section 2.2 for full reason list. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocumentToDocumentType)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype ALTER COLUMN RejectEmailSent COMMENT 'Whether the rejection notification email was sent to the customer. 1=sent, 0=not sent, NULL=not applicable (non-rejection classification). NULL for 96.9% of rows. Used with DocumentRejectReasonToNotificationType to determine email template. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocumentToDocumentType)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype ALTER COLUMN Translated COMMENT 'Flag indicating whether a translation was provided for this document (for non-English documents requiring translation). 1=translated. NULL for 99.9% of rows - rarely used. Updated via CustomerDocumentTypeUpdateTranslatedStatus procedure. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocumentToDocumentType)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype ALTER COLUMN DocumentClassificationID COMMENT 'Sub-classification refining the DocumentTypeID. FK (WITH CHECK) to Dictionary.DocumentClassification. Examples under DocumentTypeID=2 (POI): 1=Passport, 2=ID, 3=Driving License, 4=Electoral Card, 46=Residence Permit. Under DocumentTypeID=1 (POA): 6=Utility Bill, 7=Bank Statement, 40=Driving License POA. NULL for older rows that predate this field. 73 classification values in total. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocumentToDocumentType)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype ALTER COLUMN SignedDate COMMENT 'Date the document was signed. Relevant for DocumentTypeID=4 (Authorization Form) and DocumentTypeID=9 (Client Forms). NULL for most rows. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocumentToDocumentType)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype ALTER COLUMN Occurred COMMENT 'UTC timestamp when this classification record was created. Default GETUTCDATE(). NULL for rows created before this column was added (pre-2020). Latest value extends to 2034 in some rows - these appear to be sentinel values (not actual classification dates). (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocumentToDocumentType)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype ALTER COLUMN SideID COMMENT 'Which side(s) of the physical document were submitted. FK (WITH CHECK) to Dictionary.DocumentSide. Values: 0=NotRecognizable, 1=Front, 2=Back, 3=Front & Back. NULL for 40.3% of rows (pre-dates this field or not applicable for single-sided documents). Part of UNIQUE constraint. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocumentToDocumentType)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype ALTER COLUMN VisaTypeID COMMENT 'US work/student visa type for visa documents (DocumentClassificationID=65 "US Visa"). FK (WITH CHECK) to Dictionary.VisaType. Values: 1=E1, 2=E2, 3=E3, 4=F1, 5=G4, 6=H1B, 7=L1, 8=O1, 9=TN1, 10=TN2. NULL for 99.9% of rows. Added 2022-05-10 per COMOP-4557 to support US eToro customers with non-citizen work visas as POI. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerDocumentToDocumentType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
