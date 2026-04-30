# BackOffice.GetCustomerDocumentDetails

> Returns POI and POA approval flags plus a count of unclassified uploaded documents for a batch of customer IDs, used by compliance and onboarding workflows.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cids (TVP of CIDs) - one row per customer regardless of document count |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a fast compliance-readiness summary for a batch of customers: does each customer have a valid Proof of Identity (POI) document, a valid Proof of Address (POA) document, and how many documents have been uploaded but not yet classified by a BackOffice agent?

The POI and POA flags are the two primary KYC (Know Your Customer) gates in eToro's onboarding and ongoing compliance process. A customer cannot reach full verification without both. This procedure lets callers quickly check those gates for multiple customers at once without querying document tables directly.

The `NumberofNewUploadedFiles` counter surfaces the work queue for document classification agents: documents uploaded by the customer that exist in `BackOffice.CustomerDocument` but have no entry in `BackOffice.CustomerDocumentToDocumentType` (unclassified/unreviewed).

---

## 2. Business Logic

### 2.1 POI Validity Rule (DocumentTypeID=2)

**What**: POIApproved is 1 when the customer has a non-expired, non-obsolete POI document.

**Columns/Parameters Involved**: `POIApproved`, `BackOffice.CustomerDocumentToDocumentType.ExpiryDate`, `BackOffice.CustomerDocument.Obsolete`

**Rules**:
- DocumentTypeID = 2 (Proof of Identity)
- BCD.Obsolete != 1 (document not marked obsolete/superseded)
- BCDTD.ExpiryDate IS NOT NULL (an explicit expiry date must be set)
- BCDTD.ExpiryDate > GETDATE() (expiry is in the future)
- If any such document exists: POIApproved = 1; otherwise 0

### 2.2 POA Validity Rule (DocumentTypeID=1)

**What**: POAApproved is 1 when the customer has a non-expired POA document within its maximum age window.

**Columns/Parameters Involved**: `POAApproved`, `BackOffice.CustomerDocumentToDocumentType.IssueDate`, `Dictionary.DocumentType.MaxAgeInMonths`

**Rules**:
- DocumentTypeID = 1 (Proof of Address)
- BCD.Obsolete != 1
- BCDTD.IssueDate IS NOT NULL (issue date must be recorded)
- DDT.MaxAgeInMonths >= DATEDIFF(MM, IssueDate, GETDATE()) - the document is not older than the type's maximum valid age in months
- POA validity is age-based (from IssueDate), not expiry-date-based: utility bills, bank statements, etc. have no explicit expiry but are only accepted if recent enough
- MaxAgeInMonths is defined per document type in Dictionary.DocumentType

### 2.3 New Uploaded Files Counter

**What**: Counts documents that have been uploaded but not yet reviewed/classified.

**Columns/Parameters Involved**: `NumberofNewUploadedFiles`, `BackOffice.CustomerDocument`, `BackOffice.CustomerDocumentToDocumentType`

**Rules**:
- LEFT JOIN BackOffice.CustomerDocumentToDocumentType ON DocumentID
- WHERE BCDTD.DocumentID IS NULL: no classification record exists for this document
- Excludes obsolete documents (Obsolete != 1)
- This count represents the agent review queue: documents pending classification

### 2.4 TRY/CATCH Error Handling

**What**: The entire SELECT is wrapped in TRY/CATCH with detailed error re-throw.

**Rules**:
- CATCH block prints a diagnostic string including ServerName, DB, procedure name, error line, message, severity, and transaction count
- After printing, `THROW` re-raises the original error to the caller
- This pattern ensures errors are logged in SQL Server error log before propagating

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @cids | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Table-valued parameter of Customer IDs (CIDs). One output row per input CID, regardless of document count. |
| **Output Columns** | | | | | | |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID. From C.ID (the TVP row value). |
| 3 | POIApproved | BIT | NO | 0 | CODE-BACKED | 1 if the customer has at least one non-obsolete Proof of Identity document (DocumentTypeID=2) with a future ExpiryDate. 0 otherwise. |
| 4 | POAApproved | BIT | NO | 0 | CODE-BACKED | 1 if the customer has at least one non-obsolete Proof of Address document (DocumentTypeID=1) whose IssueDate is within the type's MaxAgeInMonths limit. 0 otherwise. |
| 5 | NumberofNewUploadedFiles | INT | NO | 0 | CODE-BACKED | Count of non-obsolete documents in BackOffice.CustomerDocument with no classification record in BackOffice.CustomerDocumentToDocumentType. These are pending agent review. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | BackOffice.CustomerDocument | Subquery / EXISTS | Document records filtered by CID and Obsolete flag |
| DocumentID | BackOffice.CustomerDocumentToDocumentType | Subquery / EXISTS | Document-to-type mapping with ExpiryDate, IssueDate |
| DocumentTypeID | Dictionary.DocumentType | Subquery / INNER JOIN | MaxAgeInMonths for POA age-based validity check |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Compliance readiness check for customer lists; onboarding review queues |
| UAPI or downstream services | N/A | Application call | Batch document status check for compliance APIs |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerDocumentDetails (procedure)
|- BackOffice.CustomerDocument (document records + obsolete flag)
|- BackOffice.CustomerDocumentToDocumentType (type, expiry, issue dates)
+-- Dictionary.DocumentType (MaxAgeInMonths for POA)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocument | Table | Source of document records; filtered by CID and Obsolete |
| BackOffice.CustomerDocumentToDocumentType | Table | Source of DocumentTypeID, ExpiryDate, IssueDate for POI/POA checks; LEFT JOINed for unclassified count |
| Dictionary.DocumentType | Table | MaxAgeInMonths used in POA age-based validity check |
| BackOffice.IDs | User Defined Type | TVP type for @cids |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Document compliance status in customer profile and batch views |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `SET NOCOUNT ON`: Suppresses row-count messages.
- `BEGIN TRY / END TRY / BEGIN CATCH`: Full error handling with diagnostic PRINT + THROW rethrow.
- `WITH(NOLOCK)` on all BackOffice tables: consistent with read-only compliance check context.

---

## 8. Sample Queries

### 8.1 Check POI/POA status for a batch of customers

```sql
DECLARE @cids BackOffice.IDs;
INSERT @cids VALUES (12345678), (87654321), (11223344);

EXEC BackOffice.GetCustomerDocumentDetails @cids = @cids;
-- Returns: CID | POIApproved | POAApproved | NumberofNewUploadedFiles
```

### 8.2 Find customers with unclassified documents

```sql
DECLARE @cids BackOffice.IDs;
-- Populate from a list...

DECLARE @Results TABLE (CID INT, POIApproved BIT, POAApproved BIT, NumberofNewUploadedFiles INT);
INSERT @Results EXEC BackOffice.GetCustomerDocumentDetails @cids = @cids;

SELECT * FROM @Results WHERE NumberofNewUploadedFiles > 0;
```

### 8.3 Direct POI check

```sql
SELECT COUNT(*) AS HasValidPOI
FROM BackOffice.CustomerDocumentToDocumentType BCDTD WITH(NOLOCK)
INNER JOIN BackOffice.CustomerDocument BCD WITH(NOLOCK) ON BCD.DocumentID = BCDTD.DocumentID
WHERE BCD.CID = 12345678
    AND BCDTD.DocumentTypeID = 2
    AND BCD.Obsolete != 1
    AND BCDTD.ExpiryDate IS NOT NULL
    AND BCDTD.ExpiryDate > GETDATE();
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira records found for this procedure.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerDocumentDetails | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerDocumentDetails.sql*
