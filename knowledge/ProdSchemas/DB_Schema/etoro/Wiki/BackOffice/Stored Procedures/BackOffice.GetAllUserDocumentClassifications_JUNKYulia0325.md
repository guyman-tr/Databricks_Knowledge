# BackOffice.GetAllUserDocumentClassifications_JUNKYulia0325

> DEPRECATED/JUNK: Returns only the latest classification per customer document (by max DocumentToDocumentTypeID), resolved from GCID via Customer.Customer. Marked for removal by Yulia, March 2025.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid - global customer identifier; returns one row per document (latest classification only) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

> **DEPRECATED**: This procedure is tagged JUNK (suffix `_JUNKYulia0325`) indicating it was marked for decommissioning by Yulia in March 2025. It should not be used in new code. The recommended replacement is `BackOffice.GetAllDocumentClassifications` (documented separately), which returns all classifications per document and uses Customer.CustomerStatic for GCID resolution.

`BackOffice.GetAllUserDocumentClassifications_JUNKYulia0325` returns the single most recent classification record per customer document, determined by MAX(DocumentToDocumentTypeID). Unlike `GetAllDocumentClassifications` which returns every classification row (all attempts - accepted, rejected, reclassified), this procedure collapses the history to show only the final/latest state of each document.

Two key differences from `GetAllDocumentClassifications`:
1. **Only latest per document**: Uses MAX(DocumentToDocumentTypeID) GROUP BY DocumentID - one output row per document
2. **Customer.Customer vs CustomerStatic**: Resolves GCID via `Customer.Customer` (the full customer table) rather than `Customer.CustomerStatic` (the static profile table)

The procedure was updated in January 2021 to use temp tables for performance (Ran Ovadia), and VisaTypeID was added in May 2022 per COMOP-4557.

---

## 2. Business Logic

### 2.1 Latest-Classification-Only via MAX(DocumentToDocumentTypeID)

**What**: For each customer document, only the most recently assigned classification record is returned.

**Columns/Parameters Involved**: `DocumentToDocumentTypeID`, `DocumentID`

**Rules**:
- First pass: GROUP BY DocumentID, taking MAX(DocumentToDocumentTypeID) into temp table #docs.
- Since DocumentToDocumentTypeID is an IDENTITY column, the maximum value is always the most recently inserted classification.
- Second pass: joins #docs back to CustomerDocumentToDocumentType to retrieve full row details for only the max record.
- A customer who submitted a document that was rejected and then resubmitted will show only the latest (re-submitted) classification - the rejection is hidden.
- Contrast: `GetAllDocumentClassifications` returns ALL rows including the rejection history.

### 2.2 GCID Resolution via Customer.Customer

**What**: GCID is resolved to CID using Customer.Customer instead of Customer.CustomerStatic.

**Columns/Parameters Involved**: `@gcid`, `Customer.Customer.GCID`

**Rules**:
- `SELECT @CID = CID FROM Customer.Customer WHERE GCID = @gcid`
- Customer.Customer is the primary customer record table; Customer.CustomerStatic holds supplementary profile data.
- No explicit TOP 1 - scalar assignment returns the last matching row if multiple exist (one GCID should map to one CID in the same DB context).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | INT | NO | - | CODE-BACKED | Global Customer ID (GCID). Resolved to CID via Customer.Customer.GCID. |
| 2 | DocumentToDocumentTypeID | INT | NO | - | VERIFIED | The MAX (most recent) classification record ID for this document from BackOffice.CustomerDocumentToDocumentType. |
| 3 | DocumentID | INT | NO | - | VERIFIED | Primary key of the BackOffice.CustomerDocument record - one row per physical document upload. |
| 4 | DocumentTypeID | INT | NO | - | VERIFIED | Document type for this classification. FK to Dictionary.DocumentType (1=POA, 2=POI, 6=Not Accepted, 12=W-8BEN, 14=W9). |
| 5 | ClassifiedBy | INT | YES | - | CODE-BACKED | ManagerID of the agent who performed the latest classification (alias of CustomerDocumentToDocumentType.ManagerID). 0=automated. |
| 6 | Comment | VARCHAR(1024) | YES | - | VERIFIED | Agent note or automation message for this classification. |
| 7 | IssueDate | DATETIME | YES | - | CODE-BACKED | Document issue date. |
| 8 | ExpiryDate | DATETIME | YES | - | CODE-BACKED | Document expiry date. |
| 9 | FundingID | INT | YES | - | CODE-BACKED | Associated payment instrument for card-related documents. FK to Billing.Funding. |
| 10 | RejectReasonID | INT | YES | - | VERIFIED | Rejection reason when DocumentTypeID=6. FK to Dictionary.DocumentRejectReason. NULL for approvals. |
| 11 | RejectEmailSent | BIT | YES | - | VERIFIED | Whether rejection notification was sent (1=sent, 0/NULL=not sent). |
| 12 | DocumentClassificationID | INT | YES | - | VERIFIED | Sub-classification of DocumentTypeID. FK to Dictionary.DocumentClassification (1=Passport, 3=Driving License, 65=US Visa, etc.). |
| 13 | SignedDate | DATETIME | YES | - | CODE-BACKED | Date the document was signed. For Authorization Forms and Client Forms. |
| 14 | SideID | INT | YES | - | VERIFIED | Document side: 0=NotRecognizable, 1=Front, 2=Back, 3=Front & Back. FK to Dictionary.DocumentSide. |
| 15 | Translated | SMALLINT | YES | - | CODE-BACKED | Whether a translation was provided for non-English documents (1=translated, NULL=not applicable). |
| 16 | Occurred | DATETIME | YES | - | CODE-BACKED | UTC timestamp when this classification record was created. |
| 17 | VisaTypeID | INT | YES | - | CODE-BACKED | US visa type when DocumentClassificationID=65 (US Visa). FK to Dictionary.VisaType. Values: 1=E1, 2=E2, 3=E3, 4=F1, 5=G4, 6=H1B, 7=L1, 8=O1, 9=TN1, 10=TN2. NULL for 99.9% of rows. Added COMOP-4557. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.Customer | GCID-to-CID resolution | Resolves global ID to account CID. |
| DocumentID | BackOffice.CustomerDocument | Grouping source | Groups to find MAX classification per document. |
| DocumentToDocumentTypeID | BackOffice.CustomerDocumentToDocumentType | Primary source | Returns full row for the max classification only. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. JUNK-tagged - not expected to have active callers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetAllUserDocumentClassifications_JUNKYulia0325 (procedure)
├── Customer.Customer (table) [cross-schema, GCID resolution]
├── BackOffice.CustomerDocument (table)
└── BackOffice.CustomerDocumentToDocumentType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | GCID-to-CID resolution (cross-schema). |
| BackOffice.CustomerDocument | Table | INNER JOIN to group by DocumentID and find MAX classification ID. |
| BackOffice.CustomerDocumentToDocumentType | Table | INNER JOIN to #docs on max DocumentToDocumentTypeID to return full classification details. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | JUNK-tagged - not expected to be actively called. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Internally creates temp table #docs with index on (DocumentID, MaxDocumentToDocumentTypeID) for JOIN efficiency.

### 7.2 Constraints

NOLOCK on all tables. Temp table #docs used for two-pass aggregation. No SET NOCOUNT. Note: Customer.Customer used for GCID resolution (vs CustomerStatic in GetAllDocumentClassifications).

---

## 8. Sample Queries

### 8.1 Get latest classification per document for a customer (DEPRECATED)
```sql
-- DEPRECATED: Use GetAllDocumentClassifications for production queries
EXEC BackOffice.GetAllUserDocumentClassifications_JUNKYulia0325 @gcid = 987654321;
```

### 8.2 Production equivalent (recommended)
```sql
-- Returns ALL classifications (full history) - use for production
EXEC BackOffice.GetAllDocumentClassifications @gcid = 987654321;
```

### 8.3 Inline equivalent: latest classification per document
```sql
SELECT dt.DocumentToDocumentTypeID, dt.DocumentID, dt.DocumentTypeID,
    dt.ManagerID AS ClassifiedBy, dt.IssueDate, dt.ExpiryDate,
    dt.RejectReasonID, dt.VisaTypeID, dt.Occurred
FROM BackOffice.CustomerDocumentToDocumentType dt WITH (NOLOCK)
INNER JOIN (
    SELECT bcd.DocumentID, MAX(bcdtt.DocumentToDocumentTypeID) AS MaxID
    FROM BackOffice.CustomerDocument bcd WITH (NOLOCK)
    INNER JOIN BackOffice.CustomerDocumentToDocumentType bcdtt WITH (NOLOCK)
        ON bcd.DocumentID = bcdtt.DocumentID
    WHERE bcd.CID = 12345678
    GROUP BY bcd.DocumentID
) docs ON docs.DocumentID = dt.DocumentID AND dt.DocumentToDocumentTypeID = docs.MaxID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [COMOP-4557](https://etoro-jira.atlassian.net/browse/COMOP-4557) | Jira | VisaTypeID added to POI Document Classification - May 2022, Michal Bogucki. US Visa holder onboarding initiative (COAKVU-172). |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetAllUserDocumentClassifications_JUNKYulia0325 | Type: Stored Procedure (DEPRECATED/JUNK) | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetAllUserDocumentClassifications_JUNKYulia0325.sql*
