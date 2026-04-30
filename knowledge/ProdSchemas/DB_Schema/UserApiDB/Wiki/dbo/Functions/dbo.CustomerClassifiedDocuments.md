# dbo.CustomerClassifiedDocuments

> Scalar function returning a comma-separated list of valid (non-expired) document type IDs for a user by GCID.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns NVARCHAR(500) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.CustomerClassifiedDocuments returns a comma-separated string of document type IDs that a user has uploaded and which are still valid (not expired). Checks expiry against ExpiryDate or MaxAgeInMonths from DocumentType. Uses dbo synonyms (CustomerDocumentToDocumentType, CustomerDocument, DocumentType, Real_Customer) pointing to external databases.

---

## 2. Business Logic

### 2.1 Document Validity Check

**What**: Filters to non-expired documents using two criteria.

**Columns/Parameters Involved**: `@gcid`, ExpiryDate, IssueDate, MaxAgeInMonths

**Rules**:
- Document is valid if: ExpiryDate > GETUTCDATE()
- OR if ExpiryDate is NULL: DATEDIFF(MONTH, IssueDate, GETUTCDATE()) <= MaxAgeInMonths
- Returns DISTINCT document type IDs as comma-separated string

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int (IN) | NO | - | CODE-BACKED | Global Customer ID to check documents for. |
| 2 | RETURN | nvarchar(500) | NO | - | CODE-BACKED | Comma-separated list of valid document type IDs. Empty string if no valid documents. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.CustomerDocumentToDocumentType | SELECT FROM (synonym) | Document-type mappings |
| - | dbo.CustomerDocument | JOIN (synonym) | User's documents |
| - | dbo.DocumentType | JOIN (synonym) | Document type definitions |
| - | dbo.Real_Customer | JOIN (synonym) | GCID-to-CID mapping |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.CustomerClassifiedDocuments (function)
  +-- dbo.CustomerDocumentToDocumentType (synonym, external)
  +-- dbo.CustomerDocument (synonym, external)
  +-- dbo.DocumentType (synonym, external)
  +-- dbo.Real_Customer (synonym, external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.CustomerDocumentToDocumentType | Synonym | SELECT FROM |
| dbo.CustomerDocument | Synonym | JOIN |
| dbo.DocumentType | Synonym | JOIN |
| dbo.Real_Customer | Synonym | JOIN |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get valid document types
```sql
SELECT dbo.CustomerClassifiedDocuments(12345) AS ValidDocTypes
```

### 8.2 Check if user has valid documents
```sql
SELECT CASE WHEN LEN(dbo.CustomerClassifiedDocuments(@GCID)) > 0 THEN 1 ELSE 0 END AS HasValidDocs
```

### 8.3 Use in a query
```sql
SELECT b.GCID, b.UserName, dbo.CustomerClassifiedDocuments(b.GCID) AS DocTypes
FROM Customer.BasicUserInfo b WITH (NOLOCK) WHERE b.GCID = @GCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Object: dbo.CustomerClassifiedDocuments | Type: Scalar Function | Source: UserApiDB/UserApiDB/dbo/Functions/dbo.CustomerClassifiedDocuments.sql*
