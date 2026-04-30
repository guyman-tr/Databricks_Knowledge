# BackOffice.GetDocumentClassifications

> Returns all classification records for a specific KYC document - each row represents one type assignment (document type, issue/expiry dates, rejection reason, side, visa type) made by a BackOffice agent or automated system.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from BackOffice.CustomerDocumentToDocumentType for a DocumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetDocumentClassifications is a DocAPI read procedure that retrieves the complete classification history for a specific KYC document. When a BackOffice agent or the DocAPI service opens a document, this procedure returns all type assignments recorded for it - which document type it was classified as, who classified it, validity dates, any rejection reasons, translation status, and (for US visa documents) the visa type.

A single document can have multiple classification records if it was reclassified, if multiple sides were classified separately (front and back), or if it was accepted for one type and rejected for another. All rows in `BackOffice.CustomerDocumentToDocumentType` for the given DocumentID are returned.

Created in 2017 (OPS0346 - Proof of Identity Classifications) and extended multiple times: front/back side support (COMOP-508/509, 2020), additional fields (COMOP-533, 2020), and US visa type support (COMOP-4557, 2022).

---

## 2. Business Logic

### 2.1 Multi-Row Classification Records

**What**: A document may have multiple classification rows for different reasons; this procedure returns all of them.

**Columns/Parameters Involved**: `DocumentTypeID`, `SideID`, `DocumentClassificationID`, `RejectReasonID`

**Rules**:
- Multiple rows per DocumentID are normal: e.g., DocumentTypeID=2 (POI, front) + DocumentTypeID=2 (POI, back) as separate rows with SideID=1 and SideID=2
- DocumentTypeID=6 (Not Accepted) marks a rejected classification attempt - RejectReasonID explains why
- The most recent valid classification (non-rejected) determines the document's current type
- Caller is responsible for applying business logic to determine the "active" classification from the returned rows

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @documentId | INT | NO | - | CODE-BACKED | The DocumentID of the document whose classifications are to be retrieved. FK to BackOffice.CustomerDocument. |

**Return Columns (from BackOffice.CustomerDocumentToDocumentType):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | DocumentToDocumentTypeID | int | NO | - | CODE-BACKED | Surrogate PK of the classification record. From BackOffice.CustomerDocumentToDocumentType. |
| R2 | DocumentID | int | NO | - | CODE-BACKED | Document identifier. Matches @documentId. |
| R3 | DocumentTypeID | int | NO | - | VERIFIED | The assigned document type. FK to Dictionary.DocumentType. Values: 1=Proof of Address, 2=Proof of Identity, 3=Credit Card, 4=Authorization Form, 5=Corporate Doc, 6=Not Accepted (rejection), 7=Proof of Income, 8=Proof of MOP, 9=Client Forms, 10=Financial Reference Letter, etc. |
| R4 | ClassifiedBy | int | YES | - | CODE-BACKED | ManagerID of the BackOffice agent who created this classification. 0 or NULL = automated (Au10tix/Onfido). Aliased from ManagerID. |
| R5 | Comment | nvarchar | YES | - | CODE-BACKED | Free-text comment on this classification. May contain notes about why the document was accepted/rejected. |
| R6 | IssueDate | date | YES | - | VERIFIED | Issue date of the document (e.g., passport issue date). NULL for documents where issue date is not applicable or not captured. |
| R7 | ExpiryDate | date | YES | - | VERIFIED | Expiry date of the document. Drives compliance alerts for expired documents (see BackOffice.GetExpiredIdentityDocuments). NULL if not applicable (e.g., some POA types). |
| R8 | FundingID | int | YES | - | VERIFIED | For credit card documents (DocumentTypeID=3), the FundingID of the specific credit card this document verifies. NULL for other document types. Filtered NC index exists on this column in the source table. |
| R9 | RejectReasonID | int | YES | - | VERIFIED | Rejection reason when DocumentTypeID=6 (Not Accepted). FK to Dictionary.DocumentRejectReason. NULL for accepted classifications. Top reasons: 15=POA cannot be accepted, 4=POI expired, 38=SSN cannot be accepted. |
| R10 | RejectEmailSent | bit | YES | - | VERIFIED | 1 if a rejection notification email was sent to the customer. NULL/0 if not sent. NULL for 96.9% of rows. |
| R11 | Translated | bit | YES | - | CODE-BACKED | 1 if translation details have been recorded in BackOffice.CustomerTranslationDetails for this classification. For non-English documents. |
| R12 | DocumentClassificationID | int | YES | - | VERIFIED | Sub-classification refining the DocumentTypeID. E.g., DocumentTypeID=2 (POI) + DocumentClassificationID=1 (Passport) or 3 (Driving License). FK to Dictionary.DocumentClassification. |
| R13 | SignedDate | date | YES | - | CODE-BACKED | Date the document was signed (e.g., authorization forms). NULL for unsigned document types. |
| R14 | Occurred | datetime | YES | - | CODE-BACKED | When this classification event occurred (timestamp of classification act). |
| R15 | SideID | tinyint | YES | - | VERIFIED | Which side(s) of the document: 0=NotRecognizable, 1=Front, 2=Back, 3=Front & Back. NULL for older records predating this field (40.3% of rows). Added for separate front/back POI classification (COMOP-508/509, 2020). |
| R16 | VisaTypeID | int | YES | - | VERIFIED | For US visa documents (DocumentClassificationID=65 "US Visa"): the visa type (H1B, F1, G4, etc.). NULL for 99.9% of rows. Added May 2022 (COMOP-4557). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| dt | BackOffice.CustomerDocumentToDocumentType | SELECT | Primary source - all classification records for the given DocumentID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from the DocAPI service for document detail retrieval. No stored procedure callers found within BackOffice schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetDocumentClassifications (procedure)
└── BackOffice.CustomerDocumentToDocumentType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocumentToDocumentType | Table | SELECT of all classification columns, filtered by DocumentID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DocAPI service | External | READER - loads classification data for a document in BackOffice UI and document workflows |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. The underlying table has a UNIQUE constraint on (DocumentID, DocumentTypeID, IssueDate, ExpiryDate, FundingID, SideID) preventing exact duplicates, but the same document can have multiple rows with different date/side metadata.

---

## 8. Sample Queries

### 8.1 Get all classifications for a document
```sql
EXEC BackOffice.GetDocumentClassifications @documentId = 12345
```

### 8.2 Equivalent ad-hoc query with type names
```sql
SELECT
    dt.DocumentToDocumentTypeID,
    dt.DocumentTypeID,
    dty.Name AS DocumentType,
    dt.DocumentClassificationID,
    dt.IssueDate,
    dt.ExpiryDate,
    dt.SideID,
    dt.RejectReasonID,
    dt.VisaTypeID
FROM BackOffice.CustomerDocumentToDocumentType dt WITH (NOLOCK)
JOIN Dictionary.DocumentType dty WITH (NOLOCK) ON dty.DocumentTypeID = dt.DocumentTypeID
WHERE dt.DocumentID = 12345
ORDER BY dt.Occurred DESC
```

### 8.3 Find all accepted POI classifications for a document
```sql
SELECT * FROM BackOffice.CustomerDocumentToDocumentType WITH (NOLOCK)
WHERE DocumentID = 12345
  AND DocumentTypeID = 2   -- Proof of Identity
  AND DocumentTypeID <> 6  -- Not rejected
ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Change history from DDL: OPS0346 (POI Classifications, 2017), COMOP-508/509 (front/back sides, 2020), COMOP-533 (additional fields, 2020), COMOP-4557 (US visa type, 2022).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetDocumentClassifications | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetDocumentClassifications.sql*
