# dbo.KypDocsTableType

> Table-valued parameter type for passing KYP (Know Your Partner) compliance document metadata during affiliate onboarding verification.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | DocID (INT, no PK) |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

This table type supports the KYP (Know Your Partner) compliance document collection process. When affiliates submit identity or corporate documents for verification, this type allows a stored procedure to receive the metadata for multiple documents in a single parameter call.

Each row represents one compliance document with its classification. The DocTypeID links to the Dictionary.KYPDocType lookup table which defines document categories (e.g., proof of identity, proof of address, certificate of incorporation).

The Latin1_General_BIN collation on DocName ensures exact case-sensitive matching for document name verification.

---

## 2. Business Logic

### 2.1 KYP Document Classification

**What**: Each document is classified by type for compliance review workflows.

**Columns/Parameters Involved**: `DocID`, `DocName`, `DocTypeID`

**Rules**:
- DocID is a unique identifier for the document within the submission batch
- DocTypeID references Dictionary.KYPDocType to classify the document (proof of identity, proof of address, etc.)
- DocName is the filename or display name of the uploaded document
- The compliance review process requires specific document types based on the affiliate's entity type (individual vs corporate)

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocID | int | NO | - | CODE-BACKED | Unique identifier for the document within the KYP submission. Used to track individual documents through the compliance review pipeline. |
| 2 | DocName | nvarchar(50) | NO | - | CODE-BACKED | Display name or filename of the compliance document. Latin1_General_BIN collation for exact case-sensitive matching. Example: "Passport_JohnSmith.pdf". |
| 3 | DocTypeID | int | NO | - | CODE-BACKED | Classification of the document. References Dictionary.KYPDocType which defines categories like proof of identity, proof of address, certificate of incorporation, etc. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DocTypeID | Dictionary.KYPDocType | Implicit | Classifies the type of compliance document submitted |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in dbo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for a document submission
```sql
DECLARE @docs dbo.KypDocsTableType
INSERT INTO @docs (DocID, DocName, DocTypeID)
VALUES (1, 'Passport_Front.pdf', 1),
       (2, 'ProofOfAddress.pdf', 2),
       (3, 'IncorporationCert.pdf', 3)
```

### 8.2 Select documents with type names
```sql
DECLARE @docs dbo.KypDocsTableType
INSERT INTO @docs (DocID, DocName, DocTypeID) VALUES (1, 'Passport.pdf', 1)
SELECT d.DocID, d.DocName, dt.Name AS DocTypeName
FROM @docs d
JOIN Dictionary.KYPDocType dt WITH (NOLOCK) ON d.DocTypeID = dt.KYPDocTypeID
```

### 8.3 Count documents by type
```sql
DECLARE @docs dbo.KypDocsTableType
INSERT INTO @docs (DocID, DocName, DocTypeID)
VALUES (1, 'Doc1.pdf', 1), (2, 'Doc2.pdf', 1), (3, 'Doc3.pdf', 2)
SELECT DocTypeID, COUNT(*) AS DocCount FROM @docs GROUP BY DocTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.KypDocsTableType | Type: User Defined Type | Source: fiktivo/dbo/User Defined Types/dbo.KypDocsTableType.sql*
