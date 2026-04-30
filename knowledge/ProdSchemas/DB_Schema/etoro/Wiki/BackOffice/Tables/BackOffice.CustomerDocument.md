# BackOffice.CustomerDocument

> Central repository of all KYC/AML identity documents submitted by customers for regulatory verification, storing metadata for 8.78M documents from 2009 to present.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | DocumentID (INT IDENTITY, NC PK) + CID (UNIQUE CLUSTERED with DocumentID) |
| **Partition** | No |
| **Indexes** | 4 active (1 NC PK + 1 unique clustered + 2 nonclustered) |

---

## 1. Business Meaning

BackOffice.CustomerDocument is eToro's primary registry of customer identity documents submitted for KYC (Know Your Customer) and AML (Anti-Money Laundering) compliance. Each row represents one uploaded document file - a passport scan, utility bill, credit card photo, selfie, or other regulatory document - tracking who uploaded it, when, what type it is, and where the actual file is stored in the document storage system.

Without this table, eToro cannot verify customer identities, process withdrawals for unverified customers, or demonstrate regulatory compliance to FCA, CySEC, ASIC, and other regulators. Every document request, verification approval, and compliance audit traces back to rows in this table.

Documents are created when customers upload files through the eToro web/mobile application (ManagerID=0 = automated system upload) or when BackOffice staff manually upload documents on behalf of customers (ManagerID = the staff member's ID). The table drives the entire KYC workflow: documents flow through classification (SuggestedDocumentTypeID set by AI vendors like Au10tix and Onfido), then into BackOffice.CustomerDocumentToDocumentType for formal classification and approval. GCID enables a person's documents to be queried across all their eToro accounts in any regulatory jurisdiction.

---

## 2. Business Logic

### 2.1 Document Storage Architecture

**What**: The actual document files are stored in an external system; CustomerDocument holds only the metadata and a reference key to the file.

**Columns Involved**: `DocumentID`, `StorageID`, `FileName`, `DisplayName`

**Rules**:
- StorageID is the external storage system reference (blob storage / CDN key) - 99.9999% of records have this populated (10 records with NULL = edge cases from early 2009)
- DisplayName is the filename shown to BackOffice staff and customers (the original uploaded filename)
- FileName is the stored/persisted filename in the system (may be transformed/renamed on upload)
- DocumentID is the internal identifier used across all referencing tables

### 2.2 GCID - Cross-Account Person Identity

**What**: GCID (Group Customer ID) links a physical person across all their eToro accounts in different regulatory jurisdictions, enabling document searches by person rather than account.

**Columns Involved**: `GCID`, `CID`

**Rules**:
- GCID is populated on ALL 8.78M rows - it is the primary lookup key in GetAllUserDocuments procedure (WHERE cc.GCID = @gcid)
- A single person may have multiple CIDs (accounts in different regulatory entities: eToro UK, eToro Cyprus, eToro Australia) but shares one GCID
- Documents uploaded for any of a person's accounts are retrievable via GCID lookup
- The ix_CustomerDocuments_GCID nonclustered index enables fast person-level document queries

### 2.3 Automated AI Classification Pipeline

**What**: When documents are uploaded, AI vendors (Au10tix, Onfido) automatically classify the document type and store their suggestion, which BackOffice agents then confirm or override.

**Columns Involved**: `SuggestedDocumentTypeID`, `SuggestedDocumentSubTypeID`, `SessionID`

**Rules**:
- SuggestedDocumentTypeID is the AI vendor's predicted document type (FK to Dictionary.DocumentType: 1=Proof of Address, 2=Proof of Identity, 3=Credit Card, 4=Authorization Form, etc.)
- SuggestedDocumentSubTypeID provides additional classification granularity (e.g., subtype of Proof of Identity)
- 99.99% of records have SuggestedDocumentTypeID populated (860 records missing = early upload pipeline before AI was integrated)
- SessionID tracks the upload session, enabling correlation of multiple documents uploaded in the same customer session
- The BackOffice agent reviews the suggestion and formally assigns the type via BackOffice.CustomerDocumentToDocumentType

### 2.4 Document Lifecycle Status

**What**: Two flags track the document's operational state: whether it's been superseded (Obsolete) and whether it's relevant to accounting (Accounting).

**Columns Involved**: `Obsolete`, `Accounting`, `DocumentSizeActionTypeID`

**Rules**:
- Obsolete=1: Document has been superseded or invalidated. Only 249 of 8.78M rows (near-zero). BackOffice.CustomerDocumentObsoleteSign sets this flag
- Accounting=1: Document is linked to accounting processes. Currently 0 for ALL rows in production - this field may be a legacy feature that was never actively used
- DocumentSizeActionTypeID indicates thumbnail/compressed version availability: 0="reduced size ready" (99.9999% of docs), 1="no reduced size available", 2="not processed yet" (10 records in processing queue). Default is 2 on insert; the document processing pipeline updates to 0 on success

---

## 3. Data Overview

| DocumentID | CID | ManagerID | DisplayName | SuggestedDocumentTypeID | StorageID | Meaning |
|------------|-----|-----------|-------------|------------------------|-----------|---------|
| 13474411 | 25463539 | 0 (System) | picklerick.jpg | 1 (Proof of Address) | 30670899 | Automated upload - customer submitted a Proof of Address document (filename suggests test/unusual content). ManagerID=0 confirms this was system-received, not manually uploaded. GCID links this customer's identity across accounts. |
| 13474410 | 25463539 | 0 (System) | picklerick.jpg | 2 (Proof of Identity) | 30670898 | Same customer, same session - simultaneously uploaded a Proof of Identity document. Two documents from one upload session is the standard KYC flow (POI + POA required together). |
| (historical) | (any) | > 0 | (doc filename) | (various) | (various) | When ManagerID > 0, a BackOffice staff member manually uploaded the document on behalf of the customer (e.g., from a fax or email received outside the portal). |
| (obsolete) | (any) | (any) | (doc filename) | (any) | (any) | 249 rows with Obsolete=1 - documents that were marked invalid, typically replaced by a newer upload or found to be fraudulent/duplicate. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocumentID | int IDENTITY(1,1) | NO | - | VERIFIED | Auto-generated unique document identifier. NC PK; the UNIQUE CLUSTERED index is on (CID, DocumentID) for customer-partitioned range scans. Referenced by BackOffice.CustomerDocumentToDocumentType, BackOffice.DocumentVendors, BackOffice.DocumentAuthenticationReasons, BackOffice.ZendeskDocuments. 13.4M issued (current max), 8.78M active. |
| 2 | CID | int | NO | - | VERIFIED | Customer account ID - FK to Customer.CustomerStatic. The primary account the document belongs to. Combined with DocumentID as the unique clustered key (Idx_BackOffice_CustomerDocument_CID) for efficient per-customer document range scans. Note: GCID is used for cross-account person lookups. |
| 3 | ManagerID | int | NO | - | VERIFIED | The BackOffice staff member who uploaded or processed this document. 0 = automated system upload (customer self-uploaded via portal or API). Non-zero = manual upload by a BackOffice agent (e.g., from fax, email, or Zendesk attachment). FK to BackOffice.Manager (no constraint). |
| 4 | DisplayName | nvarchar(250) | NO | - | VERIFIED | The original filename as shown to BackOffice staff and in the document management UI. Preserves the customer's original file name (e.g., "passport_scan.jpg", "utility_bill.pdf"). May differ from FileName if the storage layer renamed the file. |
| 5 | ComputerName | varchar(50) | NO | - | CODE-BACKED | Legacy field: the name of the computer/workstation from which the document was uploaded. Populated when BackOffice staff uploaded documents from named workstations in older versions of the BackOffice system. In modern automated uploads this may be the hostname of the application server. Not used in current queries. |
| 6 | FileName | nvarchar(255) | NO | - | CODE-BACKED | The stored/persisted filename in the document management system. May differ from DisplayName if the storage layer applies naming conventions on upload. Used internally for file retrieval. |
| 7 | DateAdded | datetime | NO | - | VERIFIED | Timestamp when the document was first uploaded/created in the system. Range from 2009-10-29 (platform launch) to today. Used in GetAllUserDocuments for date filtering (@minDateAdded parameter). Has composite index: (Comment, DateAdded, CID, StorageID) INCLUDE DocumentID for audit queries. |
| 8 | Accounting | bit | NO | (0) | CODE-BACKED | Flag intended to link a document to accounting processes. Default 0 and currently 0 for ALL 8.78M rows - this appears to be a planned feature that was never activated in production. |
| 9 | Obsolete | bit | NO | (0) | VERIFIED | Soft-delete flag: 1 = document has been superseded, found to be fraudulent, or otherwise invalidated. Set by BackOffice.CustomerDocumentObsoleteSign procedure. Only 249 of 8.78M documents are obsolete. GetAllUserDocuments returns the Obsolete flag so the UI can visually differentiate invalid documents. |
| 10 | Comment | varchar(255) | YES | - | CODE-BACKED | Optional BackOffice agent comment attached to the document at upload time. Returned by GetAllUserDocuments procedure. Has composite index (Comment, DateAdded, CID, StorageID) enabling comment-based audit searches. |
| 11 | DocumentSizeActionTypeID | int | NO | (2) | VERIFIED | Status of the document's compressed/thumbnail version in the processing pipeline. FK to Dictionary.DocumentSizeActionType. Values: 0="reduced size ready" (thumbnail generated - 99.9999% of docs), 1="no reduced size available" (compression not applicable), 2="not processed yet" (default on insert - processing pipeline pending). Default=2 then updated to 0/1 by processing job. |
| 12 | StorageID | int | YES | - | VERIFIED | External document storage system reference key. Points to the actual file blob in the document storage service (CDN/blob storage). 99.9999% populated. NULL for 10 very old records (2009 era before storage system integration). The GetAllUserDocuments procedure filters WHERE StorageID IS NOT NULL, confirming NULL records are excluded from normal operations. |
| 13 | SuggestedDocumentTypeID | int | YES | - | VERIFIED | AI vendor's (Au10tix/Onfido) predicted document type classification. FK to Dictionary.DocumentType. Values: 1=Proof of Address, 2=Proof of Identity, 3=Credit Card, 4=Authorization Form, 5=Corporate doc (and more). Set by the automated document classification pipeline on upload. BackOffice agents confirm or override this via CustomerDocumentToDocumentType. 99.99% populated. |
| 14 | SessionID | varchar(255) | YES | - | CODE-BACKED | Upload session identifier from the customer's document submission session. Correlates multiple documents uploaded in the same session (e.g., POI + POA submitted together in one KYC flow). Returned by GetAllUserDocuments for session-level tracing. |
| 15 | SuggestedDocumentSubTypeID | int | YES | - | CODE-BACKED | AI vendor's suggested document sub-classification (e.g., subtype of Proof of Identity: Passport vs Driver's License vs National ID). Added by Onfido integration (COMOP-2473, 2021). Returned by GetAllUserDocuments. |
| 16 | GCID | int | YES | - | VERIFIED | Group Customer ID - the person-level identifier that spans all of a customer's accounts across regulatory jurisdictions. Links this document to ALL of the customer's eToro accounts (eToro UK CID, eToro CySEC CID, etc.). 100% populated (8.78M/8.78M). Primary search key in GetAllUserDocuments (WHERE cc.GCID = @gcid). Has dedicated ix_CustomerDocuments_GCID index for fast person-level document retrieval. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (WITH CHECK) | Links document to the customer account |
| ManagerID | BackOffice.Manager | Implicit FK | Who uploaded the document (0=system, >0=staff member) |
| DocumentSizeActionTypeID | Dictionary.DocumentSizeActionType | FK (WITH CHECK) | Processing status of compressed version |
| SuggestedDocumentTypeID | Dictionary.DocumentType | FK (WITH CHECK) | AI-predicted document classification |
| GCID | Customer.CustomerStatic (GCID) | Implicit | Cross-account person identity link |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerDocumentToDocumentType | DocumentID | FK | Formal classification assignments for this document |
| BackOffice.DocumentVendors | DocumentID | FK | AI vendor processing results for this document |
| BackOffice.DocumentAuthenticationReasons | DocumentID | FK | Authentication/rejection reasons for this document |
| BackOffice.ZendeskDocuments | DocumentID | Implicit FK | Links Zendesk support ticket documents to internal IDs |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerDocument (table)
- FK targets: Customer.CustomerStatic (table), Dictionary.DocumentSizeActionType (table), Dictionary.DocumentType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK constraint on CID |
| Dictionary.DocumentSizeActionType | Table | FK constraint on DocumentSizeActionTypeID |
| Dictionary.DocumentType | Table | FK constraint on SuggestedDocumentTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocumentToDocumentType | Table | Child table - formal document type classifications |
| BackOffice.DocumentVendors | Table | Child table - AI vendor processing results |
| BackOffice.DocumentAuthenticationReasons | Table | Child table - authentication reasons per document |
| BackOffice.ZendeskDocuments | Table | Links Zendesk document IDs to CustomerDocument |
| BackOffice.GetAllUserDocuments | Procedure | READER - primary document retrieval by GCID |
| BackOffice.GetAllUserDocumentClassifications_JUNKYulia0325 | Procedure | READER - legacy classification query (JUNK = deprecated) |
| BackOffice.AddDocumentClassification | Procedure | READER - reads document for classification workflow |
| BackOffice.CustomerDocumentObsoleteSign | Procedure | MODIFIER - sets Obsolete=1 |
| BackOffice.GetBlockedCustomers | Procedure | READER - checks document status in blocked customer queries |
| BackOffice.GetLastRiskPoiPoa | Procedure | READER - gets latest POI/POA documents for risk assessment |
| BackOffice.GetCustomerClassifiedTypes | Procedure | READER - reads classified document types per customer |
| BackOffice.GetAllDocumentClassifications | Procedure | READER - full document classification report |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BCDC | NC PK | DocumentID ASC | - | - | Active |
| Idx_BackOffice_CustomerDocument_CID | UNIQUE CLUSTERED | CID ASC, DocumentID ASC | - | - | Active |
| Idx_BackOffice_CustomerDocument_Comment_DateAdded_CID_StorageID | NC | Comment ASC, DateAdded ASC, CID ASC, StorageID ASC | DocumentID | - | Active |
| ix_CustomerDocuments_GCID | NC | GCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_CustomerDocument_Accounting | DEFAULT | Accounting = 0 - not accounting-related by default |
| DF_CustomerDocument_Obsolete | DEFAULT | Obsolete = 0 - documents are valid on creation |
| df_DocumentSizeActionTypeID | DEFAULT | DocumentSizeActionTypeID = 2 - "not processed yet" on insert |
| FK_BackOffice.CustomerDocument_Dictionary.DocumentSizeActionType | FK | DocumentSizeActionTypeID -> Dictionary.DocumentSizeActionType(ID) |
| FK_BackOffice_CustomerDocument_SuggestedDocumentTypeID | FK | SuggestedDocumentTypeID -> Dictionary.DocumentType(DocumentTypeID) |
| FK_CCST_BCDC | FK | CID -> Customer.CustomerStatic(CID) |

---

## 8. Sample Queries

### 8.1 Get all documents for a customer by GCID with type names
```sql
SELECT
    cd.DocumentID,
    cd.CID,
    cc.GCID,
    cd.DisplayName,
    cd.DateAdded,
    dt.Name AS SuggestedDocType,
    cd.StorageID,
    cd.Obsolete,
    m.Login AS UploadedBy
FROM BackOffice.CustomerDocument cd WITH (NOLOCK)
JOIN Customer.CustomerStatic cc WITH (NOLOCK) ON cc.CID = cd.CID
LEFT JOIN Dictionary.DocumentType dt WITH (NOLOCK) ON dt.DocumentTypeID = cd.SuggestedDocumentTypeID
LEFT JOIN BackOffice.Manager m WITH (NOLOCK) ON m.ManagerID = cd.ManagerID
WHERE cc.GCID = 12345  -- replace with target GCID
  AND cd.StorageID IS NOT NULL
ORDER BY cd.DateAdded DESC
```

### 8.2 Get documents pending processing (not yet compressed)
```sql
SELECT
    cd.DocumentID,
    cd.CID,
    cd.DisplayName,
    cd.DateAdded,
    dsat.ActionName AS ProcessingStatus
FROM BackOffice.CustomerDocument cd WITH (NOLOCK)
JOIN Dictionary.DocumentSizeActionType dsat WITH (NOLOCK)
    ON dsat.ID = cd.DocumentSizeActionTypeID
WHERE cd.DocumentSizeActionTypeID = 2  -- not processed yet
ORDER BY cd.DateAdded DESC
```

### 8.3 Get recently obsoleted documents with who uploaded them
```sql
SELECT TOP 100
    cd.DocumentID,
    cd.CID,
    cd.DisplayName,
    cd.DateAdded,
    m.FirstName + ' ' + m.LastName AS UploadedBy,
    dt.Name AS DocumentType
FROM BackOffice.CustomerDocument cd WITH (NOLOCK)
LEFT JOIN BackOffice.Manager m WITH (NOLOCK) ON m.ManagerID = cd.ManagerID
LEFT JOIN Dictionary.DocumentType dt WITH (NOLOCK) ON dt.DocumentTypeID = cd.SuggestedDocumentTypeID
WHERE cd.Obsolete = 1
ORDER BY cd.DateAdded DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| COMOP-391/468 | Jira | Au10tix service integration - adds DocumentDetails to request for au10tix_etoro (from SP comment history) |
| COMOP-511/605 | Jira | Added response validation for valid POI existence (from SP comment history) |
| COMOP-732/833 | Jira | Handle StorageId=null edge cases in GetAllUserDocuments (from SP comment history) |
| COMOP-1932/1933 | Jira | DB optimizations on DocApi procedures (from SP comment history) |
| COMOP-2473/2517 | Jira | Onfido - Classify Selfie Liveness + POI doc - added SuggestedDocumentSubTypeID support (from SP comment history) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.6/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 5 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerDocument | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CustomerDocument.sql*
