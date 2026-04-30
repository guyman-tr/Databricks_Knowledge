# History.KYPAffiliateKYPDocs

> SQL Server temporal history table storing all historical versions of KYP document submissions by affiliates.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | AffiliateID + DocID (composite - identifies a specific document submission for an affiliate across versions) |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.KYPAffiliateKYPDocs is the system-versioned temporal history table for KYP.AffiliateKYPDocs. It captures every historical version of document submissions made by affiliates as part of the Know Your Partner verification process. Each row represents one document submitted by an affiliate at a specific point in time, including the document name and type classification.

This table is critical for compliance auditing and document lifecycle tracking. When affiliates resubmit documents (e.g., replacing an expired passport, uploading a corrected tax form, or providing a clearer ID scan), each prior submission is preserved here. Compliance teams can reconstruct the complete document submission timeline - what was submitted, when it was replaced, and what type of document it was - for any affiliate at any point in history.

Data flows in automatically via SQL Server's temporal mechanism whenever rows in the base table KYP.AffiliateKYPDocs are updated or deleted. With 1,675 historical rows, document resubmissions are moderately frequent as affiliates iterate through the verification process. Both AffiliateID and DocID are protected with dynamic data masking.

---

## 2. Business Logic

### 2.1 Document Submission Lifecycle

**What**: Tracks the history of KYP document submissions, including replacements and type reclassifications.

**Columns/Parameters Involved**: `AffiliateID`, `DocID`, `DocName`, `DocTypeID`, `ValidFrom`, `ValidTo`

**Rules**:
- AffiliateID + DocID together identify a specific document submission record
- DocTypeID references Dictionary.KYPDocType: 1=ID_Front, 2=ID_Back, 3=Passport, 4=Tax Form, 5=Wallet Screenshot, 6=Company Proof Of Address, 7=147C IRS Letter
- See [KYP Doc Type](../../Dictionary/Tables/Dictionary.KYPDocType.md) for the full document type dictionary
- DocName stores the original filename or descriptive name of the submitted document
- AffiliateID and DocID are MASKED to protect document identification details
- Historical rows accumulate as affiliates replace or update their submitted documents

---

## 3. Data Overview

The table contains 1,675 historical rows representing superseded versions of KYP document submissions. Document resubmissions are common during the KYP verification lifecycle as compliance teams request corrections or affiliates update expired identity documents.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | CODE-BACKED | The affiliate who submitted the document (MASKED). References dbo.tblaff_Affiliates.AffiliateID. |
| 2 | DocID | int | NO | - | CODE-BACKED | Unique identifier for the document submission (MASKED). |
| 3 | DocName | nvarchar(50) | NO | - | CODE-BACKED | Original filename or descriptive name of the submitted document. |
| 4 | DocTypeID | int | NO | - | CODE-BACKED | Document type classification. See [KYP Doc Type](../../Dictionary/Tables/Dictionary.KYPDocType.md): 1=ID_Front, 2=ID_Back, 3=Passport, 4=Tax Form, 5=Wallet Screenshot, 6=Company Proof Of Address, 7=147C IRS Letter. |
| 5 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON session context. |
| 6 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | When this version became active. |
| 7 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | When this version was superseded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | KYP.AffiliateKYPDocs | Temporal History | Stores historical versions of the base table |
| AffiliateID | dbo.tblaff_Affiliates | Implicit FK | The affiliate who submitted the document |
| DocTypeID | Dictionary.KYPDocType | Implicit FK | Document type classification |

### 5.2 Referenced By (other objects point to this)

Accessed implicitly via temporal queries on KYP.AffiliateKYPDocs.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.KYPAffiliateKYPDocs (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYP.AffiliateKYPDocs | Table | SYSTEM_VERSIONING |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_KYPAffiliateKYPDocs | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

None. Uses PAGE compression.

---

## 8. Sample Queries

### 8.1 View full document submission history for an affiliate
```sql
SELECT AffiliateID, DocID, DocName, DocTypeID, ValidFrom, ValidTo
FROM KYP.AffiliateKYPDocs FOR SYSTEM_TIME ALL WITH (NOLOCK)
WHERE AffiliateID = 12345
ORDER BY DocID, ValidFrom
```

### 8.2 Check which documents an affiliate had submitted at a specific date
```sql
SELECT AffiliateID, DocID, DocName, DocTypeID
FROM KYP.AffiliateKYPDocs FOR SYSTEM_TIME AS OF '2025-06-01' WITH (NOLOCK)
WHERE AffiliateID = 12345
ORDER BY DocTypeID
```

### 8.3 Find recently superseded document submissions
```sql
SELECT AffiliateID, DocID, DocName, DocTypeID, ValidFrom, ValidTo
FROM History.KYPAffiliateKYPDocs WITH (NOLOCK)
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.KYPAffiliateKYPDocs | Type: Table | Source: fiktivo/History/Tables/History.KYPAffiliateKYPDocs.sql*
