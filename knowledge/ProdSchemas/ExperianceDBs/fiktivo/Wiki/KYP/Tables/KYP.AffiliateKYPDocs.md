# KYP.AffiliateKYPDocs

> Stores metadata for verification documents uploaded by affiliates during the KYP compliance process, linking each document to its type (ID, passport, tax form, etc.).

| Property | Value |
|----------|-------|
| **Schema** | KYP |
| **Object Type** | Table |
| **Key Identifier** | AffiliateID + DocID (composite PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK, PAGE compression) |

---

## 1. Business Meaning

KYP.AffiliateKYPDocs stores the metadata for verification documents that affiliates upload as part of their KYP submission. Each document has a type (ID front/back, passport, tax form, wallet screenshot, company proof of address, IRS 147C letter) and a name. The actual document files are stored externally - this table only tracks what was uploaded and its classification.

Document upload is a critical step in KYP verification. The compliance team reviews these documents to verify the affiliate's identity and corporate legitimacy. An affiliate's KYP Progress typically cannot reach 100% without the required document types being present.

Rows are managed by `KYP.UpdateAffiliateData` using a MERGE statement on the @Docs table-valued parameter (KypDocsTableType UDT). MERGE handles insert, update (DocName/DocTypeID changes), and delete. `KYP.GetAffiliateData` reads the document list for display. The table uses temporal versioning and data masking on AffiliateID and DocID.

---

## 2. Business Logic

### 2.1 Document Type Classification

**What**: Each uploaded document is classified by type for compliance review.

**Columns/Parameters Involved**: `DocTypeID`, `DocName`

**Rules**:
- DocTypeID maps to Dictionary.KYPDocType: 1=ID_Front, 2=ID_Back, 3=Passport, 4=Tax Form, 5=Wallet Screenshot, 6=Company Proof Of Address, 7=147C IRS Letter. See [KYP Doc Type](../../_glossary.md#kyp-doc-type).
- DocName is the original filename of the uploaded document
- DocID is a sequential identifier per affiliate (not auto-increment - application assigns)
- Multiple documents of the same type can exist (e.g., multiple passport pages)

---

## 3. Data Overview

N/A - 174 rows. Document metadata with masked AffiliateID/DocID fields. Would show (AffiliateID, DocID, DocName, DocTypeID) tuples.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | CODE-BACKED | FK to KYP.Affiliate. MASKED with default(). Part of composite PK. |
| 2 | DocID | int | NO | - | CODE-BACKED | Document sequence number within the affiliate's document set. MASKED with default(). Part of composite PK. Application-assigned (not IDENTITY). |
| 3 | DocName | nvarchar(50) | NO | - | CODE-BACKED | Original filename or descriptive name of the uploaded document. |
| 4 | DocTypeID | int | NO | - | VERIFIED | Document type classification. FK to Dictionary.KYPDocType: 1=ID_Front, 2=ID_Back, 3=Passport, 4=Tax Form, 5=Wallet Screenshot, 6=Company Proof Of Address, 7=147C IRS Letter. See [KYP Doc Type](../../_glossary.md#kyp-doc-type). |
| 5 | Trace | computed | NO | - | CODE-BACKED | Computed audit column. Inherited pattern from KYP.Affiliate. |
| 6 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Temporal versioning row start. |
| 7 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | Temporal versioning row end. History in History.KYPAffiliateKYPDocs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | KYP.Affiliate | FK | Parent affiliate's KYP record |
| DocTypeID | Dictionary.KYPDocType | FK | Document type classification (note: FK constraint named FK_KYP_AffiliateKYPMarketingMethods_DocTypeID - naming mismatch) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYP.GetAffiliateData | AffiliateID | SELECT (READER) | Reads document list |
| KYP.UpdateAffiliateData | AffiliateID, DocID | MERGE (WRITER) | Synchronizes documents via MERGE |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYP.AffiliateKYPDocs (table)
├── KYP.Affiliate (table)
└── Dictionary.KYPDocType (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYP.Affiliate | Table | FK on AffiliateID |
| Dictionary.KYPDocType | Table (cross-schema) | FK on DocTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYP.GetAffiliateData | SP | SELECT reader |
| KYP.UpdateAffiliateData | SP | MERGE writer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_KYP_AffiliateKYPDocs | CLUSTERED PK | AffiliateID ASC, DocID ASC | - | - | Active |

Data compression: PAGE.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_KYP_AffiliateKYPDocs | PRIMARY KEY | Composite (AffiliateID, DocID) |
| FK_KYP_AffiliateKYPDocs_KYP_Affiliate | FOREIGN KEY | AffiliateID -> KYP.Affiliate(AffiliateID) |
| FK_KYP_AffiliateKYPMarketingMethods_DocTypeID | FOREIGN KEY | DocTypeID -> Dictionary.KYPDocType(DocTypeID). Note: constraint name is a copy-paste artifact from MarketingMethods |

Temporal: SYSTEM_VERSIONING ON with History.KYPAffiliateKYPDocs.

---

## 8. Sample Queries

### 8.1 Get all documents for an affiliate
```sql
SELECT DocID, DocName, DocTypeID
FROM KYP.AffiliateKYPDocs WITH (NOLOCK)
WHERE AffiliateID = 60062
```

### 8.2 Document type distribution
```sql
SELECT d.DocTypeID, dt.Name AS DocTypeName, COUNT(*) AS DocCount
FROM KYP.AffiliateKYPDocs d WITH (NOLOCK)
JOIN Dictionary.KYPDocType dt WITH (NOLOCK) ON d.DocTypeID = dt.DocTypeID
GROUP BY d.DocTypeID, dt.Name
ORDER BY COUNT(*) DESC
```

### 8.3 Affiliates missing required document types
```sql
SELECT a.AffiliateID, a.KYPStatusID
FROM KYP.Affiliate a WITH (NOLOCK)
WHERE a.KYPStatusID IN (3, 4)
  AND NOT EXISTS (
    SELECT 1 FROM KYP.AffiliateKYPDocs d WITH (NOLOCK)
    WHERE d.AffiliateID = a.AffiliateID AND d.DocTypeID = 3
  )
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 9.3/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: KYP.AffiliateKYPDocs | Type: Table | Source: fiktivo/KYP/Tables/KYP.AffiliateKYPDocs.sql*
