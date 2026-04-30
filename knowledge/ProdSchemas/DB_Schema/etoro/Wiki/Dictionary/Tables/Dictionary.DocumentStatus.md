# Dictionary.DocumentStatus

> Lookup table defining the 5 review states for KYC/AML identity documents uploaded by users.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | DocumentStatusID (INT, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.DocumentStatus defines the review lifecycle of a document uploaded for KYC/AML compliance. Every document submitted by a user passes through these states as it is reviewed (automatically or manually) by the compliance team.

This table works together with Dictionary.DocumentType — DocumentType says WHAT the document is, DocumentStatus says WHERE it is in the review process. A user's account verification status depends on having key document types in Approved status.

DocumentStatusID is stored in customer document records and checked by onboarding and compliance procedures to determine whether a user has completed verification.

---

## 2. Business Logic

### 2.1 Document Review Lifecycle

**What**: Documents flow through a review pipeline with clear terminal states.

**Columns/Parameters Involved**: `DocumentStatusID`, `DocumentStatusName`

**Rules**:
- Uploaded (1) → Pending Review (2): Document submitted, awaiting review
- Pending Review (2) → Approved (3): Compliance accepted the document
- Pending Review (2) → Declined (4): Document was rejected (blurry, wrong type, expired, etc.)
- Pending Review (2) → Expired (5): Document aged out before review completed (stale queue item)
- Declined → user must re-upload a new document

---

## 3. Data Overview

| DocumentStatusID | DocumentStatusName | Meaning |
|---|---|---|
| 1 | Uploaded | Document has been submitted by the user but not yet entered the review queue. Very transient state. |
| 2 | PendingReview | Document is in the compliance review queue awaiting human or automated evaluation. Typical queue time varies by volume. |
| 3 | Approved | Document passed compliance review — identity/address confirmed. Terminal success. Contributes toward full account verification. |
| 4 | Declined | Document was rejected by compliance. Reasons: illegible, expired, wrong document type, name mismatch, suspected forgery. User must upload a replacement. |
| 5 | Expired | Document review was not completed within the required timeframe and is now stale. User must upload a fresh document. Prevents indefinite pending states. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocumentStatusID | int | NO | - | CODE-BACKED | Primary key identifying the document review state. 1=Uploaded, 2=PendingReview, 3=Approved, 4=Declined, 5=Expired. See [Document Status](_glossary.md#document-status). (Dictionary.DocumentStatus) |
| 2 | DocumentStatusName | varchar(50) | NO | - | CODE-BACKED | Human-readable status label. Used in compliance review UI, customer communications, and regulatory reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer document tables | DocumentStatusID | Implicit Lookup | Review status of uploaded documents |

---

## 6. Dependencies

This object has no dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.DocumentStatus | CLUSTERED PK | DocumentStatusID ASC | - | - | Active |

---

## 8. Sample Queries

### 8.1 List all document statuses
```sql
SELECT DocumentStatusID, DocumentStatusName
FROM [Dictionary].[DocumentStatus] WITH (NOLOCK) ORDER BY DocumentStatusID;
```

### 8.2 Count documents by review status
```sql
SELECT ds.DocumentStatusName, COUNT(*) AS DocCount
FROM [Customer].[Document] d WITH (NOLOCK)
JOIN [Dictionary].[DocumentStatus] ds WITH (NOLOCK) ON d.DocumentStatusID = ds.DocumentStatusID
GROUP BY ds.DocumentStatusName ORDER BY DocCount DESC;
```

---

*Generated: 2026-03-13 | Quality: 7.8/10*
*Object: Dictionary.DocumentStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.DocumentStatus.sql*
