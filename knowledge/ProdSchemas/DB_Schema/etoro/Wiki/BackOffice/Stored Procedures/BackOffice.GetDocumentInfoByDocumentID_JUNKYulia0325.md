# BackOffice.GetDocumentInfoByDocumentID_JUNKYulia0325

> **DEPRECATED (JUNK)** - Returns minimal document identity info (CID, GCID, StorageID, FileName) for a single DocumentID; superseded by BackOffice.GetDocument which returns this data plus full metadata.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Single DocumentID lookup; returns one row (CID, GCID, StorageID, FileName) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetDocumentInfoByDocumentID_JUNKYulia0325 is a **deprecated** stored procedure (marked JUNK) that returns the five core identity fields for a KYC document given its DocumentID: the document's own ID, the customer account (CID), the group customer ID (GCID), the external storage reference (StorageID), and the stored filename (FileName).

It was created in December 2017 by Geri Reshef (ticket 49530) as part of the "W-8BEN DocAPI & BackOffice implementation" - a US tax compliance initiative allowing eToro to collect W-8BEN forms (IRS certificate of foreign status) from non-US customers trading US securities. The W-8BEN workflow required looking up a document's storage location and associating it with the correct customer identity (CID/GCID) for the tax form processing pipeline.

The `_JUNKYulia0325` suffix indicates this procedure was scheduled for decommissioning as of March 2025. Its output is a strict subset of `BackOffice.GetDocument`, which returns the same five fields plus DateAdded, DisplayName, AddedBy, Comment, SuggestedDocumentTypeID, Obsolete, and vendor authentication data. Any caller can be migrated directly to `BackOffice.GetDocument @documentId = @DocumentID` with no behavioral change for these five fields.

---

## 2. Business Logic

### 2.1 Minimal Document Identity Lookup

**What**: Returns only the fields needed to identify a document and locate it in storage - no classification data, no manager info, no vendor results.

**Columns/Parameters Involved**: `@DocumentID`, `cd.StorageID`, `cd.FileName`, `cc.GCID`

**Rules**:
- No WHERE filter on `StorageID IS NOT NULL` - unlike GetDocument, this will return rows where StorageID is NULL (legacy pre-2009 documents)
- No Obsolete filter - returns the document regardless of whether it has been superseded
- JOIN to `Customer.Customer` is INNER - if the CID from CustomerDocument has no matching Customer record, no row is returned (should not occur for valid documents)
- Returns exactly one row for a valid DocumentID (DocumentID is the PK of CustomerDocument)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DocumentID | INT | NO | - | CODE-BACKED | The DocumentID of the document to retrieve. PK of BackOffice.CustomerDocument. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | DocumentID | int | NO | - | CODE-BACKED | The document's unique identifier. Echoed from @DocumentID parameter. |
| R2 | CID | int | NO | - | CODE-BACKED | Customer account ID that owns this document. From BackOffice.CustomerDocument.CID. |
| R3 | GCID | int | YES | - | CODE-BACKED | Group Customer ID - identifies the person across all regulatory accounts. From Customer.Customer.GCID via CID join. |
| R4 | StorageID | uniqueidentifier | YES | - | CODE-BACKED | External storage system reference key (blob storage / CDN) used to retrieve the document file. May be NULL for legacy pre-2009 documents (unlike GetDocument which filters these out). From BackOffice.CustomerDocument.StorageID. |
| R5 | FileName | nvarchar | YES | - | CODE-BACKED | The stored filename in the system. From BackOffice.CustomerDocument.FileName. May differ from DisplayName if the file was renamed on upload. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| cd | BackOffice.CustomerDocument | SELECT | Primary source - document identity fields |
| cc | Customer.Customer | INNER JOIN | Resolves CID to GCID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. JUNK status indicates no active callers. Superseded by BackOffice.GetDocument.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetDocumentInfoByDocumentID_JUNKYulia0325 (procedure - DEPRECATED)
├── BackOffice.CustomerDocument (table)
└── Customer.Customer (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocument | Table | SELECT DocumentID, CID, StorageID, FileName WHERE DocumentID = @DocumentID |
| Customer.Customer | Table | INNER JOIN on CID to get GCID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No active dependents | - | JUNK status - marked for decommissioning |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Note: unlike BackOffice.GetDocument, this procedure does NOT filter `WHERE StorageID IS NOT NULL`, so it can return the ~10 legacy documents from 2009 that have a NULL StorageID.

---

## 8. Sample Queries

### 8.1 Get minimal document identity (deprecated - use GetDocument instead)
```sql
EXEC BackOffice.GetDocumentInfoByDocumentID_JUNKYulia0325 @DocumentID = 12345
-- Returns: DocumentID, CID, GCID, StorageID, FileName
```

### 8.2 Preferred replacement - use GetDocument
```sql
EXEC BackOffice.GetDocument @documentId = 12345
-- Returns same fields PLUS DateAdded, DisplayName, AddedBy, Comment,
-- SuggestedDocumentTypeID, Obsolete, Vendors, AuthenticationReasons
```

### 8.3 Ad-hoc equivalent
```sql
SELECT cd.DocumentID, cd.CID, cc.GCID, cd.StorageID, cd.FileName
FROM BackOffice.CustomerDocument cd WITH (NOLOCK)
INNER JOIN Customer.Customer cc WITH (NOLOCK) ON cc.CID = cd.CID
WHERE cd.DocumentID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Created December 2017 (ticket 49530): "W-8BEN docapi & backoffice implementation - DB Changes" by Geri Reshef.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers (JUNK) | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetDocumentInfoByDocumentID_JUNKYulia0325 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetDocumentInfoByDocumentID_JUNKYulia0325.sql*
