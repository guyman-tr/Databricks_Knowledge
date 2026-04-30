# Customer.GetDocumentDetails

> Retrieves KYC document verification details for a customer - checks whether a passport or utility bill document exists, whether it is expired, and what document type it is.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns HasDocument, Expired, DocumentTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetDocumentDetails checks the verification document status for a customer's KYC (Know Your Customer) process. It determines whether a customer has submitted a required document (passport or utility bill), whether that document has expired, and what document type it is. This is critical for regulatory compliance - customers must provide valid identity documents to trade.

This procedure exists because the verification system needs a quick status check on document validity without loading the full document data. It answers three binary questions: Does the document exist? Is it expired? What type is it?

The procedure uses CTEs to find the most recent matching document (by comment tags like 'newkyc-passport', 'newkyc-bill'), check its expiry date against UTC time or max age rules, and extract the document type. It reads from dbo.CustomerDocument, dbo.Real_Customer, dbo.CustomerDocumentToDocumentType, and dbo.DocumentType.

---

## 2. Business Logic

### 2.1 Document Type Detection by Comment Tag

**What**: Documents are classified by their comment field values, not by an explicit type column.

**Columns/Parameters Involved**: `@documentType`, `cd.Comment`

**Rules**:
- @documentType = 'passport': matches comments 'newkyc-passport', 'newkyc-ie-passport', 'newkyc-idCard', 'newkyc-ie-idCard'
- @documentType = 'utility': matches comments 'newkyc-bill', 'newkyc-ie-bill'
- Documents with DocumentTypeID = 6 (Rejected) are excluded from results
- The 'ie-' prefix indicates Ireland-specific document variants

### 2.2 Document Expiry Logic

**What**: A document is considered expired based on either its explicit expiry date or its age relative to the document type's maximum age.

**Columns/Parameters Involved**: `ExpiryDate`, `IssueDate`, `MaxAgeInMonths`

**Rules**:
- If ExpiryDate < GETUTCDATE() -> document is expired
- If ExpiryDate IS NULL AND DATEDIFF(Month, IssueDate, GETUTCDATE()) > MaxAgeInMonths -> document is expired (age-based expiry from dbo.DocumentType)
- Otherwise -> document is valid

**Diagram**:
```
Input: @gcid, @documentType ('passport' or 'utility')
  |
  v
CTE: LastCustomerDocument
  Find MAX(DocumentID) matching comment tags
  Exclude DocumentTypeID = 6 (Rejected)
  |
  v
CTE: Expired
  Check: ExpiryDate < UTC now?
  OR: No expiry date AND age > MaxAgeInMonths?
  |
  v
CTE: LastDocumentType
  Get MAX(DocumentTypeID) for the document
  |
  v
Output: HasDocument (1/0), Expired (1/NULL), DocumentTypeID
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID to check document status for. |
| 2 | @documentType | varchar(20) | NO | - | CODE-BACKED | Document category to check: 'passport' (ID documents) or 'utility' (proof of address/bills). |
| 3 | HasDocument (output) | int | YES | - | CODE-BACKED | 1 if a matching document exists (DocumentID > 0), 0 otherwise. |
| 4 | Expired (output) | int | YES | - | CODE-BACKED | 1 if the document is expired (by date or age), NULL if not expired or no document found. |
| 5 | DocumentTypeID (output) | int | YES | - | CODE-BACKED | The document type classification from dbo.CustomerDocumentToDocumentType. Value 6 = Rejected (excluded from results). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | dbo.Real_Customer | JOIN | Links GCID to CID for document lookup |
| CID | dbo.CustomerDocument | JOIN | The customer's uploaded documents |
| DocumentID | dbo.CustomerDocumentToDocumentType | LEFT JOIN | Document type classification and expiry dates |
| DocumentTypeID | dbo.DocumentType | JOIN | Document type rules including MaxAgeInMonths |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Called during KYC verification status checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetDocumentDetails (procedure)
+-- dbo.CustomerDocument (table)
+-- dbo.Real_Customer (table)
+-- dbo.CustomerDocumentToDocumentType (table)
+-- dbo.DocumentType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.CustomerDocument | Table | CTE - finds matching documents by comment tags |
| dbo.Real_Customer | Table | JOIN - resolves GCID to CID |
| dbo.CustomerDocumentToDocumentType | Table | LEFT JOIN - document type and expiry data |
| dbo.DocumentType | Table | JOIN - max age rules for age-based expiry |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called directly by application code |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check passport document status
```sql
EXEC Customer.GetDocumentDetails @gcid = 12345, @documentType = 'passport'
```

### 8.2 Check utility bill status
```sql
EXEC Customer.GetDocumentDetails @gcid = 12345, @documentType = 'utility'
```

### 8.3 Manual check for latest passport document
```sql
SELECT MAX(cd.DocumentID) AS LastDocumentID
FROM dbo.CustomerDocument cd WITH (NOLOCK)
JOIN dbo.Real_Customer rc WITH (NOLOCK) ON rc.CID = cd.CID
LEFT JOIN dbo.CustomerDocumentToDocumentType cdd WITH (NOLOCK) ON cdd.DocumentID = cd.DocumentID
WHERE rc.GCID = @gcid
    AND (cd.Comment = 'newkyc-passport' OR cd.Comment = 'newkyc-ie-passport'
         OR cd.Comment = 'newkyc-idCard' OR cd.Comment = 'newkyc-ie-idCard')
    AND ISNULL(cdd.DocumentTypeID, 1) <> 6
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetDocumentDetails | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetDocumentDetails.sql*
