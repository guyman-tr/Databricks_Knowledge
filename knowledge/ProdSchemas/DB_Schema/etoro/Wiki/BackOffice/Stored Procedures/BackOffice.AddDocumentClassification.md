# BackOffice.AddDocumentClassification

> Bulk-inserts one or more KYC document classification records for a customer document using a table-valued parameter, then returns the document's storage metadata.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @documentId (CustomerDocument.DocumentID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary write path for classifying customer KYC documents in the eToro platform. When a BackOffice agent or automated system (Au10tix) determines what type a submitted document is (e.g., Passport, Driver's License, Proof of Address), this procedure records that classification as one or more rows in `BackOffice.CustomerDocumentToDocumentType`. The table-valued parameter design allows multiple classification types to be assigned to a single document in one atomic transaction.

The procedure exists because document classification is a multi-row operation: a single document upload may need to be simultaneously classified as both front and back of a passport, or as multiple types (POI + tax form). Before COMOP-2095/2097 (2021-01-07), this required multiple individual inserts. The TVP approach ensures atomicity - either all classifications are added or none are, preventing partial classification states.

Data flows as follows: the DocApi service calls this procedure when an agent classifies a document in the KYC review UI, or when Au10tix returns an automated classification result. The procedure bulk-inserts into `CustomerDocumentToDocumentType` in a transaction, captures the SCOPE_IDENTITY() for the last inserted row, then returns document metadata from `CustomerDocument` joined to `dbo.StorageDocuments` - giving the caller the new classification ID plus the document's storage application identifier for downstream processing.

---

## 2. Business Logic

### 2.1 Bulk Classification via Table-Valued Parameter

**What**: Multiple classification rows are inserted atomically using the BackOffice.DocumentClassification TVP.

**Columns/Parameters Involved**: `@classifications`, `BackOffice.CustomerDocumentToDocumentType` (target)

**Rules**:
- All rows from the TVP are inserted in a single INSERT...SELECT within a BEGIN TRAN / COMMIT block
- On error: ROLLBACK + THROW re-raises; error context is PRINT-logged with server, DB, procedure, line, and message details
- `ClassifiedBy` (TVP column) maps to `ManagerID` in the target table: 0 = automated Au10tix classification, >0 = manual BackOffice agent
- VisaTypeID (added COMOP-4557, 2022-05-10) is only non-NULL for US visa documents (DocumentClassificationID=65)

### 2.2 Result Set: Post-Insert Document Metadata

**What**: After the INSERT, the procedure returns metadata about the document from CustomerDocument and StorageDocuments.

**Columns/Parameters Involved**: `ClassificationId`, `ApplicationIdentifier`, `DocumentAddDate`, `SuggestedDocumentTypeID`

**Rules**:
- `ClassificationId` = SCOPE_IDENTITY() of the last inserted classification row (used by caller to reference the new record)
- `ApplicationIdentifier` from `dbo.StorageDocuments` JOIN on DocumentID WHERE `FileVariantId <> 1`: FileVariantId=1 is excluded (likely the original/primary file variant); non-1 variants provide the downstream system's reference ID
- If no StorageDocuments row exists, ApplicationIdentifier returns 'NotSpecified'
- The SELECT uses TOP 1 and NOLOCK

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @documentId | INT | NO | - | CODE-BACKED | DocumentID from BackOffice.CustomerDocument - the uploaded document being classified. Foreign key to CustomerDocumentToDocumentType.DocumentID. |
| 2 | @classifications | BackOffice.DocumentClassification | NO | - | CODE-BACKED | Table-Valued Parameter containing one or more classification records to insert. ReadOnly. Columns map to CustomerDocumentToDocumentType fields. See BackOffice.DocumentClassification UDT for full column list. |

**Result Set - Document Metadata (one row):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | ClassificationId | INT | YES | - | CODE-BACKED | SCOPE_IDENTITY() of the last inserted row in CustomerDocumentToDocumentType. The new classification's primary key (DocumentToDocumentTypeID). Used by caller to reference the classification record. |
| 4 | ApplicationIdentifier | VARCHAR | YES | 'NotSpecified' | CODE-BACKED | External storage system reference from dbo.StorageDocuments WHERE FileVariantId <> 1. Identifies the document in the downstream DocApi/storage system. Returns 'NotSpecified' if no matching StorageDocuments row. |
| 5 | DocumentAddDate | datetime | YES | - | CODE-BACKED | BackOffice.CustomerDocument.DateAdded - timestamp when the original document was uploaded to the platform. |
| 6 | SuggestedDocumentTypeID | INT | YES | - | CODE-BACKED | BackOffice.CustomerDocument.SuggestedDocumentTypeID - the document type suggested by the upload source (e.g., auto-detected from file or user-submitted type). Used by the caller to pre-populate classification UI. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @documentId | BackOffice.CustomerDocument | FK (implicit) | Document being classified; also read for result set |
| @documentId -> DocumentID | BackOffice.CustomerDocumentToDocumentType | WRITER | Inserts classification rows for the document |
| @classifications.DocumentClassificationID | BackOffice.DocumentClassification (UDT) | Type reference | TVP type defines the classification row structure |
| DocumentID | dbo.StorageDocuments | Lookup (LEFT JOIN) | Gets ApplicationIdentifier for return set; FileVariantId<>1 filter |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found in the BackOffice schema. Called from the DocApi service (per Confluence: DocApi DB Migration Mapping, CR space) as the primary document classification write endpoint.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AddDocumentClassification (procedure)
|- BackOffice.CustomerDocumentToDocumentType (table) [INSERT - classification records]
|- BackOffice.CustomerDocument (table) [SELECT - document metadata for result set]
+-- dbo.StorageDocuments (table) [LEFT JOIN - ApplicationIdentifier]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocumentToDocumentType | Table | INSERT target for classification rows from TVP |
| BackOffice.DocumentClassification | User Defined Type | Parameter type for @classifications TVP |
| BackOffice.CustomerDocument | Table | SELECT for result set (DateAdded, SuggestedDocumentTypeID) |
| dbo.StorageDocuments | Table | LEFT JOIN for ApplicationIdentifier; FileVariantId <> 1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DocApi Service | External | Calls to classify customer KYC documents after agent review or Au10tix automated result |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction atomicity | Explicit | All TVP rows inserted under BEGIN TRAN; rolled back on any error |
| Error logging | Application | On error: PRINT with full context (server, DB, proc, line, message, severity, TranCount, UTC time) before rollback |

---

## 8. Sample Queries

### 8.1 Classify a document as Passport (front side)

```sql
-- Declare and populate the TVP
DECLARE @classifications AS BackOffice.DocumentClassification
INSERT INTO @classifications
    (DocumentTypeID, DocumentClassificationID, IssueDate, ExpiryDate, SideID,
     ClassifiedBy, Comment, RejectReasonID, RejectEmailSent, FundingID, SignedDate, VisaTypeID)
VALUES
    (2,              1,                        '2020-01-01', '2030-01-01', 1,
     742,           NULL,              NULL,            NULL,             NULL,      NULL,        NULL)
-- DocumentTypeID=2=POI, DocumentClassificationID=1=Passport, SideID=1=Front

EXEC BackOffice.AddDocumentClassification
    @documentId = 999999,
    @classifications = @classifications
```

### 8.2 Check recent classifications for a document

```sql
SELECT
    cddt.DocumentToDocumentTypeID,
    cddt.DocumentTypeID,
    cddt.DocumentClassificationID,
    cddt.IssueDate,
    cddt.ExpiryDate,
    cddt.ManagerID,
    cddt.RejectReasonID
FROM BackOffice.CustomerDocumentToDocumentType cddt WITH (NOLOCK)
WHERE cddt.DocumentID = 999999
ORDER BY cddt.DocumentToDocumentTypeID DESC
```

### 8.3 Find unclassified documents awaiting classification

```sql
SELECT
    cd.DocumentID,
    cd.CID,
    cd.DateAdded,
    cd.SuggestedDocumentTypeID
FROM BackOffice.CustomerDocument cd WITH (NOLOCK)
LEFT JOIN BackOffice.CustomerDocumentToDocumentType cddt WITH (NOLOCK)
    ON cd.DocumentID = cddt.DocumentID
WHERE cddt.DocumentID IS NULL
ORDER BY cd.DateAdded DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [DocApi DB Migration - Mapping (new)](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/12158895004) | Confluence | AddDocumentClassification is used by the DocApi service as the primary classification write endpoint; doc migration planning context |
| [Doc Api DB Migration Mapping](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/1782906896) | Confluence | Documents CustomerDocument table migration planning; confirms AddDocumentClassification is a dependency of DocApi |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AddDocumentClassification | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.AddDocumentClassification.sql*
