# dbo.CustomerClassifiedDocumentsTable

> Inline table-valued function returning valid document type IDs as a single-row table with STRING_AGG (TVF version of CustomerClassifiedDocuments).

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE (docTypes column) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.CustomerClassifiedDocumentsTable is the inline TVF version of CustomerClassifiedDocuments. Uses STRING_AGG instead of variable concatenation for better performance. Returns a single row with a comma-separated docTypes string. Same document validity logic (ExpiryDate or MaxAgeInMonths check).

---

## 2. Business Logic

Same as CustomerClassifiedDocuments. Uses STRING_AGG for modern aggregation.

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int (IN) | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | docTypes | varchar (output) | YES | - | CODE-BACKED | Comma-separated list of valid document type IDs. NULL if no valid documents. |

---

## 5. Relationships

### 5.1 References To (this object points to)

Same as dbo.CustomerClassifiedDocuments - uses same 4 dbo synonyms.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

Same as dbo.CustomerClassifiedDocuments.

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

### 8.1 Get valid document types (TVF)
```sql
SELECT docTypes FROM dbo.CustomerClassifiedDocumentsTable(12345)
```

### 8.2 CROSS APPLY usage
```sql
SELECT b.GCID, b.UserName, d.docTypes FROM Customer.BasicUserInfo b WITH (NOLOCK)
CROSS APPLY dbo.CustomerClassifiedDocumentsTable(b.GCID) d WHERE b.GCID IN (12345, 67890)
```

### 8.3 Compare with scalar version
```sql
SELECT dbo.CustomerClassifiedDocuments(12345) AS ScalarResult,
       (SELECT docTypes FROM dbo.CustomerClassifiedDocumentsTable(12345)) AS TVFResult
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Object: dbo.CustomerClassifiedDocumentsTable | Type: Inline TVF | Source: UserApiDB/UserApiDB/dbo/Functions/dbo.CustomerClassifiedDocumentsTable.sql*
