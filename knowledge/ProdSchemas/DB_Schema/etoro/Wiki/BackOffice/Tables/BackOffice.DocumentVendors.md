# BackOffice.DocumentVendors

> Records which third-party KYC verification vendor processed each customer document. 902,884 rows covering 893,779 documents; 5 vendor values: Onfido (31.8%), Sumsub (5.2%), Au10tix (1.5%), IDnow (0.8%), and the legacy code "100" (60.8%).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | (DocumentID, Vendor) - NC PK |
| **Partition** | No (stored ON [MAIN] filegroup) |
| **Indexes** | 1 active (1 NC PK) |

---

## 1. Business Meaning

BackOffice.DocumentVendors records which external KYC (Know Your Customer) verification vendor processed a given customer document. When eToro submits a passport, utility bill, or selfie to a third-party identity verification service, the vendor is recorded here alongside the DocumentID.

This table supports:
- Audit trail: which vendor made the verification decision visible in BackOffice
- Analytics: measuring vendor performance, acceptance/rejection rates by vendor
- Support resolution: knowing which vendor to query when investigating a specific document's outcome

902,884 rows across 893,779 distinct documents as of 2026-03-17. Some documents have multiple vendor entries (9,105 documents appear twice - likely re-processed by a second vendor).

**Vendor distribution**:
- "100" (548,825 rows, 60.8%): Legacy numeric code, likely the initial vendor identifier used before named vendors were introduced. May represent an internal processing path or an early integration now superseded.
- "Onfido" (286,650 rows, 31.8%): UK-based identity verification provider. Onfido uses AI-powered document analysis and biometric checks.
- "Sumsub" (46,951 rows, 5.2%): Sum&Substance / Sumsub - identity verification and AML screening platform.
- "Au10tix" (13,373 rows, 1.5%): Israeli identity document verification company. Also referenced in CustomerDocumentToDocumentType (ManagerID=0 = Au10tix automated classification).
- "IDnow" (7,085 rows, 0.8%): German identity verification provider.

Deletion cascade: DeleteUserDocument deletes rows here before deleting CustomerDocument rows (maintaining FK integrity).

---

## 2. Business Logic

### 2.1 Vendor Recording on Document Processing

**What**: AddDocumentVendor records which vendor processed a document.

**Columns Involved**: `DocumentID`, `Vendor`

**Rules**:
- AddDocumentVendor(@documentId, @vendor): simple INSERT. No existence check - a document can have multiple vendor entries if processed by multiple services.
- Vendor is a free-text string (varchar 1024) with no FK constraint - new vendors can be added without DDL changes.
- Deletion: DeleteUserDocument deletes from DocumentVendors first (WHERE DocumentID=@DocumentID) before cascading to CustomerDocumentToDocumentType and CustomerDocument.

---

## 3. Data Overview

902,884 rows across 893,779 documents as of 2026-03-17:

| Vendor | Rows | Pct | Description |
|--------|------|-----|-------------|
| 100 | 548,825 | 60.8% | Legacy vendor code. Earliest documents; likely pre-named-vendor era or internal processing. |
| Onfido | 286,650 | 31.8% | AI-powered identity verification. Currently dominant named vendor. |
| Sumsub | 46,951 | 5.2% | Sum&Substance identity and AML screening platform. |
| Au10tix | 13,373 | 1.5% | Israeli document verification. Also used for automated classification (ManagerID=0 in CustomerDocumentToDocumentType). |
| IDnow | 7,085 | 0.8% | German video identification and document verification. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocumentID | int | NO | - | VERIFIED | The KYC document that was processed. FK (WITH CHECK) to BackOffice.CustomerDocument(DocumentID). Leading key of NC PK. 893,779 distinct values. Deletions cascade from DeleteUserDocument. |
| 2 | Vendor | varchar(1024) | NO | - | VERIFIED | The verification vendor name or code. Part of NC PK. Free-text, no FK constraint. Known values: "100" (legacy), "Onfido", "Sumsub", "Au10tix", "IDnow". Max 1024 chars - generous allocation for potentially long vendor identifiers or JSON-encoded metadata. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DocumentID | BackOffice.CustomerDocument | FK (WITH CHECK) | Parent document record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.AddDocumentVendor | DocumentID, Vendor | WRITER | Records vendor after document processing |
| BackOffice.DeleteUserDocument | DocumentID | DELETER (cascade) | GDPR document erasure cascade |
| BackOffice.GetDocument | DocumentID | READER | Returns document with vendor info |
| BackOffice.GetAllUserDocuments | DocumentID | READER | Returns all documents with vendor info |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.DocumentVendors (table)
- FK target: BackOffice.CustomerDocument (DocumentID)
- Written by: BackOffice.AddDocumentVendor
- Deleted by (cascade): BackOffice.DeleteUserDocument
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocument | Table | FK on DocumentID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.AddDocumentVendor | Procedure | WRITER |
| BackOffice.DeleteUserDocument | Procedure | DELETER (cascade before parent) |
| BackOffice.GetDocument | Procedure | READER |
| BackOffice.GetAllUserDocuments | Procedure | READER |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOffice_DocumentVendors | NC PK | DocumentID ASC, Vendor ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |

No clustered index - heap table with a NC PK. With 902K rows, a clustered index on DocumentID would improve GetDocument lookups but none is defined.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BackOffice_DocumentVendors | PK | Uniqueness of (DocumentID, Vendor) - one row per document per vendor |
| BODVDI | FK (WITH CHECK) | DocumentID -> BackOffice.CustomerDocument(DocumentID) |

---

## 8. Sample Queries

### 8.1 Get vendor(s) for a specific document
```sql
SELECT DocumentID, Vendor
FROM BackOffice.DocumentVendors WITH (NOLOCK)
WHERE DocumentID = @DocumentID
```

### 8.2 Vendor distribution analysis
```sql
SELECT Vendor, COUNT(*) AS DocumentCount,
       COUNT(DISTINCT DocumentID) AS DistinctDocuments
FROM BackOffice.DocumentVendors WITH (NOLOCK)
GROUP BY Vendor
ORDER BY DocumentCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.DocumentVendors | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.DocumentVendors.sql*
