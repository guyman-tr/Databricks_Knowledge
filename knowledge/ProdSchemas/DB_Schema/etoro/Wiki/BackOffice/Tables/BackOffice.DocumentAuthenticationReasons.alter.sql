-- =============================================================================
-- Databricks ALTER Script: bronze etoro.BackOffice.DocumentAuthenticationReasons
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.DocumentAuthenticationReasons.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_backoffice_documentauthenticationreasons
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_backoffice_documentauthenticationreasons (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_backoffice_documentauthenticationreasons SET TBLPROPERTIES (
    'comment' = 'Records the authentication outcome reasons for each KYC document by verification type (POI/POA/Selfie), storing the results returned by automated verification systems like Au10tix. 932,866 rows covering 886,923 documents; 89.7% have ReasonID=0 (Ok - document passed). Source: etoro.BackOffice.DocumentAuthenticationReasons on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.DocumentAuthenticationReasons.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_backoffice_documentauthenticationreasons SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'BackOffice',
    'source_table' = 'DocumentAuthenticationReasons',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_backoffice_documentauthenticationreasons ALTER COLUMN DocumentID COMMENT 'The KYC document being authenticated. Implicit FK to BackOffice.CustomerDocument(DocumentID) - no declared FK constraint. CLUSTERED INDEX leading key - physical storage order is by DocumentID for efficient document-level lookups. Part of NC PK. 886,923 distinct values. (Tier 1 - upstream wiki, etoro.BackOffice.DocumentAuthenticationReasons)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_documentauthenticationreasons ALTER COLUMN ReasonID COMMENT 'Authentication outcome reason code. FK (WITH CHECK) to Dictionary.AuthenticationReason(ReasonID). 107 possible values (0-107 with gaps): 0=Ok (document passed), 1=Expired Document, 3=Name Mismatch, 4=Forged Document, 5=Multipage Document Do Not Match, 6=Not Authentic, 10=Document Type Not Accepted By Etoro, 32=Face Was Not Detected, 34=Address Mismatch, 40=Document Issue Date Not Present, 46=Match (face match check for selfie), 47=Faces Do Not Match, 48=Indecisive, 52=Forged Selfie, 53=Missing Address Details, 80-84=Not Authentic subtypes, 85-90=Bad Quality subtypes, 101=Not Authentic - Inconsistent POA, 103=Fake Webcam, 105=Liveliness Not Detected, 106=Spoofing. Part of NC PK. (Tier 1 - upstream wiki, etoro.BackOffice.DocumentAuthenticationReasons)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_documentauthenticationreasons ALTER COLUMN TypeID COMMENT 'The verification type under which this reason was generated. FK (WITH CHECK) to Dictionary.DocumentAutheticationType(TypeID). Values: 1=POI (81.1%), 2=POA (17.7%), 3=Selfie (0.5%), 4=SelfieLiveliness (0.6%), 5=SelfieMotion (0.06%). Note: "DocumentAutheticationType" has a typo in the dictionary table name (Authe_tic_ation). Default in SetDocumentAuthenticationReasons: 1 (POI). Part of NC PK. (Tier 1 - upstream wiki, etoro.BackOffice.DocumentAuthenticationReasons)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
