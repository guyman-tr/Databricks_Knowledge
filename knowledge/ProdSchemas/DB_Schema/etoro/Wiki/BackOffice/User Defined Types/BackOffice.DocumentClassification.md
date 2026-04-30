# BackOffice.DocumentClassification

> Table-valued parameter type that defines the schema for passing a batch of document classification records when classifying a customer document across one or more document types.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | User Defined Type |
| **Key Identifier** | DocumentClassificationID (classification row key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.DocumentClassification` is a Table-Valued Type (TVT) that defines the schema contract for bulk-passing document classification data into BackOffice stored procedures. Each row in this type represents one classification of a customer document against a specific document type - capturing the issue date, expiry date, funding link, classifying manager, rejection reason, and other metadata required to record what type of document was submitted and its outcome.

This type exists to allow a back-office agent to classify a single customer document against multiple document types simultaneously in a single atomic transaction. Without it, each classification row would require a separate round-trip. The type documents the complete schema contract expected by `BackOffice.AddDocumentClassification` and related procedures.

Data flows into this type from the DocAPI or back-office application. The caller populates rows matching this structure and passes the table as a READONLY parameter to `BackOffice.AddDocumentClassification`, which then INSERTs each row into `BackOffice.CustomerDocumentToDocumentType`. The TVT acts as a staging transport - it is never persisted itself.

---

## 2. Business Logic

### 2.1 Document Classification Batch Insert Pattern

**What**: The TVT transports multiple document type classifications for a single document in one call, enabling atomic multi-type document processing.

**Columns/Parameters Involved**: `DocumentTypeID`, `DocumentClassificationID`, `IssueDate`, `ExpiryDate`, `FundingID`, `ClassifiedBy`, `Comment`, `RejectReasonID`, `RejectEmailSent`, `SignedDate`, `SideID`, `VisaTypeID`

**Rules**:
- One row per document type being classified (a passport might be classified as both POI and address proof).
- `ClassifiedBy` maps to `BackOffice.CustomerDocumentToDocumentType.ManagerID` - it records which BO manager performed the classification.
- `RejectReasonID` being non-NULL signals a rejection; `RejectEmailSent` tracks whether the rejection notification was sent.
- `ExpiryDate` drives document expiry checks used in KYC status evaluation.
- Added `VisaTypeID` per COMOP-4557 to support Visa type classification on POI documents.

**Diagram**:
```
Caller (DocAPI)
  -> passes @classifications AS BackOffice.DocumentClassification
        |
        v
  BackOffice.AddDocumentClassification(@documentId, @classifications)
        |
        v
  INSERT INTO BackOffice.CustomerDocumentToDocumentType
  (DocumentID, DocumentTypeID, IssueDate, ExpiryDate, FundingID,
   ManagerID=ClassifiedBy, Comment, RejectReasonID, RejectEmailSent,
   DocumentClassificationID, SignedDate, SideID, VisaTypeID)
  SELECT ... FROM @classifications
```

---

## 3. Data Overview

N/A for User Defined Type. This is a type definition used as a transient parameter container, not a persistent table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocumentClassificationTypeID | int | YES | - | NAME-INFERRED | Classification type category identifier. Present in the DDL but not mapped in the primary consuming procedure AddDocumentClassification - may be used by other classification procedures or reserved for future filtering. Likely references a classification type lookup. |
| 2 | DocumentTypeID | int | YES | - | CODE-BACKED | Document type being classified (e.g., 1=POA, 2=POI). Maps to BackOffice.CustomerDocumentToDocumentType.DocumentTypeID and Dictionary.DocumentType. Determines which category of document this classification record belongs to. |
| 3 | DocumentClassificationID | int | YES | - | CODE-BACKED | Identifier of an existing classification record within BackOffice.CustomerDocumentToDocumentType. Used when updating or referencing an existing classification row (maps to CustomerDocumentToDocumentType.DocumentClassificationID which is the auto-identity). |
| 4 | IssueDate | datetime | YES | - | CODE-BACKED | Date the document was issued by the issuing authority. Maps to BackOffice.CustomerDocumentToDocumentType.IssueDate. Used in document age checks against Dictionary.DocumentType.MaxAgeInMonths to determine if a POA document is still valid. |
| 5 | ExpiryDate | datetime | YES | - | CODE-BACKED | Date on which the document expires. Maps to BackOffice.CustomerDocumentToDocumentType.ExpiryDate. Critical for POI documents - a future ExpiryDate marks the document as currently valid for KYC status evaluation. |
| 6 | SignedDate | datetime | YES | - | CODE-BACKED | Date the document was signed by the customer. Maps to BackOffice.CustomerDocumentToDocumentType.SignedDate. Relevant for TnC and agreement documents where the signature date has legal significance. |
| 7 | FundingID | int | YES | - | CODE-BACKED | Funding method linked to this document classification (e.g., a credit card statement used as proof of address). Maps to BackOffice.CustomerDocumentToDocumentType.FundingID. NULL if the document is not linked to a specific funding method. |
| 8 | ClassifiedBy | int | YES | - | CODE-BACKED | ManagerID of the BackOffice agent who performed this classification. Maps to BackOffice.CustomerDocumentToDocumentType.ManagerID. References BackOffice.Manager.ManagerID. |
| 9 | Comment | varchar(1024) | YES | - | CODE-BACKED | Free-text note from the classifying manager. Maps to BackOffice.CustomerDocumentToDocumentType.Comment. Used to record reasons for rejection, special instructions, or additional context about the classification decision. |
| 10 | RejectReasonID | int | YES | - | CODE-BACKED | Rejection reason code when the document classification is denied. Maps to BackOffice.CustomerDocumentToDocumentType.RejectReasonID. NULL indicates approved/pending. Non-NULL triggers rejection notification logic. |
| 11 | RejectEmailSent | bit | YES | - | CODE-BACKED | Flag indicating whether the rejection notification email was sent to the customer. Maps to BackOffice.CustomerDocumentToDocumentType.RejectEmailSent. 1=email sent, 0 or NULL=not yet sent. Used to prevent duplicate rejection emails. |
| 12 | SideID | int | YES | - | CODE-BACKED | Side of the document being classified (e.g., front vs. back for ID cards). Maps to BackOffice.CustomerDocumentToDocumentType.SideID. Allows separate classification records for multi-sided documents. |
| 13 | VisaTypeID | int | YES | - | CODE-BACKED | Visa type identifier for POI documents containing a visa. Added per COMOP-4557. Maps to BackOffice.CustomerDocumentToDocumentType.VisaTypeID. NULL for non-visa documents. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DocumentTypeID | Dictionary.DocumentType.DocumentTypeID | Implicit | Document category (POI, POA, etc.) |
| FundingID | Billing.Funding.FundingID | Implicit | Funding method linked to the document |
| ClassifiedBy | BackOffice.Manager.ManagerID | Implicit | BO manager who performed the classification |
| RejectReasonID | BackOffice.CustomerDocumentToDocumentType.RejectReasonID | Implicit | Rejection reason lookup |
| VisaTypeID | Dictionary.VisaType (implied) | Implicit | Visa type classification for POI documents |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.AddDocumentClassification | @classifications parameter | Schema contract | Receives a batch of classification rows and INSERTs into CustomerDocumentToDocumentType |
| BackOffice.UpdateDocumentClassification | @classifications parameter (likely) | Schema contract | Used when updating existing classification metadata |
| BackOffice.RemoveDocumentClassification | (likely uses classification IDs subset) | Schema contract | May use this type to identify which classifications to remove |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.AddDocumentClassification | Stored Procedure | READONLY parameter @classifications - inserts rows into BackOffice.CustomerDocumentToDocumentType |
| BackOffice.UpdateDocumentClassification | Stored Procedure | READONLY parameter - updates existing classification metadata |
| BackOffice.RemoveDocumentClassification | Stored Procedure | May use classification row data to identify records to delete |
| BackOffice.GetDocumentClassifications | Stored Procedure | Likely uses for batch retrieval queries |
| BackOffice.GetAllDocumentClassifications | Stored Procedure | Likely uses for batch retrieval queries |
| BackOffice.GetDocumentMaxAge | Stored Procedure | May filter on document type using this schema |
| BackOffice.UpdateDocumentClassificationsExpiryDate | Stored Procedure | Related classification update (uses DocumentClassificationsExpiry sibling type) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None. All columns are nullable with no constraints. The type is designed for flexible input.

---

## 8. Sample Queries

### 8.1 Declare and pass a single POI document classification

```sql
DECLARE @classifications BackOffice.DocumentClassification;

INSERT INTO @classifications
    (DocumentTypeID, IssueDate, ExpiryDate, ClassifiedBy, Comment)
VALUES
    (2, '2020-01-15', '2030-01-15', 1001, 'Passport - valid, front and back provided');

EXEC BackOffice.AddDocumentClassification
    @documentId = 98765,
    @classifications = @classifications;
```

### 8.2 Reject a document classification with reason

```sql
DECLARE @classifications BackOffice.DocumentClassification;

INSERT INTO @classifications
    (DocumentTypeID, RejectReasonID, RejectEmailSent, ClassifiedBy, Comment)
VALUES
    (1, 5, 0, 1001, 'Document too old - exceeds MaxAgeInMonths limit');

EXEC BackOffice.AddDocumentClassification
    @documentId = 98765,
    @classifications = @classifications;
```

### 8.3 Classify a credit card document linked to a funding method

```sql
DECLARE @classifications BackOffice.DocumentClassification;

INSERT INTO @classifications
    (DocumentTypeID, FundingID, IssueDate, ExpiryDate, ClassifiedBy, SideID)
VALUES
    (3, 44567, '2022-06-01', '2027-06-01', 1002, 1); -- Side 1 = front

SELECT * FROM @classifications WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Doc Api DB Migration Mapping](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/1782906896) | Confluence | DB migration mapping for DocAPI - context on document classification schema evolution |
| [HLD: AutoAppeal on suspended and rejected status](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/8599372352) | Confluence | Business context for rejection processing and notification flows |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 3/11 (DDL, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.DocumentClassification | Type: User Defined Type | Source: etoro/etoro/BackOffice/User Defined Types/BackOffice.DocumentClassification.sql*
