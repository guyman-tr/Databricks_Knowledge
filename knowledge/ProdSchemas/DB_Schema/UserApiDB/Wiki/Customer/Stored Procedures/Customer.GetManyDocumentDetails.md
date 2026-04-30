# Customer.GetManyDocumentDetails

> Variant of GetDocumentDetails that returns both passport AND utility bill document statuses in a single call, with a DocKind column to distinguish them.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns HasDocument, Expired, DocumentTypeID, DocKind |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetManyDocumentDetails is an enhanced version of Customer.GetDocumentDetails. While the original returns document status for a single document type (passport OR utility), this procedure returns both types in one call. Each row includes a DocKind column ('passport' or 'utility') to identify the document category.

This procedure serves callers that need a complete KYC document overview without making two separate calls. It uses the same CTE pattern with LastCustomerDocument, Expired, and LastDocumentType.

---

## 2. Business Logic

### 2.1 Combined Document Type Detection

**What**: Groups documents by kind (passport vs utility) using IIF on comment tags, returning both in one result.

**Columns/Parameters Involved**: `cd.Comment`, `DocKind`

**Rules**:
- Documents with comments 'newkyc-bill' or 'newkyc-ie-bill' are classified as 'utility'
- All other matching documents are classified as 'passport'
- GROUP BY DocKind produces separate MAX(DocumentID) per kind
- Expiry check is shared across both kinds (checks all documents in one pass)
- DocumentTypeID = 6 (Rejected) excluded

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID to check document status for. |
| 2 | HasDocument (output) | int | YES | - | CODE-BACKED | 1 if a matching document exists, 0 otherwise. |
| 3 | Expired (output) | int | YES | - | CODE-BACKED | 1 if expired (by date or age), NULL if valid. |
| 4 | DocumentTypeID (output) | int | YES | - | CODE-BACKED | Document type classification. |
| 5 | DocKind (output) | varchar | YES | - | CODE-BACKED | Document category: 'passport' or 'utility'. Distinguishes the two document groups. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | dbo.Real_Customer | JOIN | GCID to CID resolution |
| CID | dbo.CustomerDocument | JOIN | Customer documents |
| DocumentID | dbo.CustomerDocumentToDocumentType | LEFT JOIN | Document type/expiry |
| DocumentTypeID | dbo.DocumentType | JOIN | Max age rules |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | KYC document overview |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetManyDocumentDetails (procedure)
+-- dbo.CustomerDocument (table)
+-- dbo.Real_Customer (table)
+-- dbo.CustomerDocumentToDocumentType (table)
+-- dbo.DocumentType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.CustomerDocument | Table | CTE - document lookup |
| dbo.Real_Customer | Table | JOIN - GCID to CID |
| dbo.CustomerDocumentToDocumentType | Table | LEFT JOIN - type/expiry |
| dbo.DocumentType | Table | JOIN - max age rules |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called directly by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get both document statuses
```sql
EXEC Customer.GetManyDocumentDetails @gcid = 12345
-- Returns up to 2 rows: one for 'passport', one for 'utility'
```

### 8.2 Check which documents are missing
```sql
-- If result has only 'passport' row, utility bill is missing
-- If result has only 'utility' row, passport/ID is missing
-- If result is empty, no KYC documents submitted
```

### 8.3 Compare with single-type version
```sql
-- GetDocumentDetails: takes @documentType param, returns one type
-- GetManyDocumentDetails: returns both types with DocKind column
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetManyDocumentDetails | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetManyDocumentDetails.sql*
