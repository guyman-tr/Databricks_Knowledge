# BackOffice.AddDocumentVendor

> Records which third-party KYC verification vendor processed a customer document by inserting a row into BackOffice.DocumentVendors.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @documentId (DocumentVendors.DocumentID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the write path for recording which external identity verification vendor (Onfido, Sumsub, Au10tix, IDnow, etc.) processed a customer's KYC document. Each time eToro submits a document to an external verification service and receives a result, this procedure is called to create an audit trail of the vendor decision.

The procedure exists to maintain a vendor audit trail alongside document records. Without this, there would be no way to know which vendor made an accept/reject decision for a specific document - critical for support resolution, analytics, and vendor performance measurement. The free-text vendor name (no FK constraint) allows new verification providers to be onboarded without DDL changes.

Data flows as follows: when an identity verification service processes a document, the calling application invokes this procedure with the DocumentID and vendor name. The DocumentVendors table accumulates one row per vendor per document; a document processed by multiple vendors will have multiple rows. Known vendors: "100" (legacy code, 60.8%), "Onfido" (31.8%), "Sumsub" (5.2%), "Au10tix" (1.5%), "IDnow" (0.8%).

---

## 2. Business Logic

### 2.1 Vendor Audit Trail

**What**: Minimal insert - no validation, no transaction, allows multiple vendors per document.

**Columns/Parameters Involved**: `@documentId`, `@vendor`

**Rules**:
- Simple INSERT with no existence check - multiple vendor entries per document are allowed (9,105 documents have 2 entries in production)
- No transaction wrapper - if the insert fails, the error propagates to the caller
- Vendor is free-text (varchar 1024) - no FK to a vendor list table - new vendors require no DDL change
- Deletion handled by BackOffice.DeleteUserDocument (deletes from DocumentVendors before CustomerDocument)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @documentId | INT | NO | - | CODE-BACKED | DocumentID from BackOffice.CustomerDocument - the document that was processed by the verification vendor. Maps to DocumentVendors.DocumentID. |
| 2 | @vendor | varchar(1024) | NO | - | VERIFIED | Name of the third-party KYC vendor that processed the document. Known values: "100" (legacy), "Onfido", "Sumsub", "Au10tix", "IDnow". Free-text with no FK constraint. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @documentId | BackOffice.DocumentVendors | WRITER | Inserts a new vendor record for the document |
| @documentId | BackOffice.CustomerDocument | Implicit | DocumentID references the uploaded document |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found in BackOffice schema. Called from external identity verification integration layer when a vendor processes a document.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AddDocumentVendor (procedure)
+-- BackOffice.DocumentVendors (table) [INSERT target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.DocumentVendors | Table | INSERT target for (DocumentID, Vendor) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Identity verification integration | External | Called to record vendor processing of customer documents |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No validation | Design choice | No check for valid DocumentID or known vendor value - simple insert with no guards |

---

## 8. Sample Queries

### 8.1 Record Onfido as the processing vendor for a document

```sql
EXEC BackOffice.AddDocumentVendor
    @documentId = 999999,
    @vendor = 'Onfido'
```

### 8.2 Check all vendors for a document

```sql
SELECT DocumentID, Vendor
FROM BackOffice.DocumentVendors WITH (NOLOCK)
WHERE DocumentID = 999999
```

### 8.3 Vendor distribution across all documents

```sql
SELECT Vendor, COUNT(*) AS DocumentCount
FROM BackOffice.DocumentVendors WITH (NOLOCK)
GROUP BY Vendor
ORDER BY DocumentCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AddDocumentVendor | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.AddDocumentVendor.sql*
