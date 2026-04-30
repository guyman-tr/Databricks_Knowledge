# BackOffice.GetDocumentInfoByStorageID_JUNKYulia0325

> **DEPRECATED (JUNK)** - Returns document identity info (DocumentID, CID, GCID, FileName) by StorageID; created for the Au10tix KYC integration in 2017 but contains a type mismatch bug (@StorageID declared INT vs uniqueidentifier column) and is superseded by BackOffice.GetDocument.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | StorageID lookup; returns one row per matching document |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetDocumentInfoByStorageID_JUNKYulia0325 is a **deprecated** stored procedure (marked JUNK) that returns the four identity fields for a KYC document given its StorageID: the DocumentID, the customer account (CID), the group customer ID (GCID), and the stored filename (FileName). The StorageID parameter is echoed back as a return column.

It was created in March 2017 by Geri Reshef (ticket 44152) as part of the initial "Au10tix scripts for eToroDB" - the integration with the Au10tix document authentication vendor. The Au10tix workflow needed to reverse-look up which document a StorageID corresponded to, in order to associate vendor authentication results with the correct customer and document record.

The `_JUNKYulia0325` suffix indicates this procedure was scheduled for decommissioning as of March 2025. There is also a notable technical defect: the `@StorageID` parameter is declared as `INT`, but the `BackOffice.CustomerDocument.StorageID` column is `uniqueidentifier`. This type mismatch would cause a runtime implicit conversion error in modern SQL Server, meaning the procedure is unlikely to execute successfully as written. This is likely a contributing reason for its JUNK status.

Any active caller should use an ad-hoc query or a GCID/CID lookup via `BackOffice.GetDocument` instead.

---

## 2. Business Logic

### 2.1 Reverse StorageID Lookup

**What**: Given an external storage reference (StorageID), identifies which customer document it belongs to.

**Columns/Parameters Involved**: `@StorageID`, `cd.StorageID`, `cd.DocumentID`, `cc.GCID`

**Rules**:
- WHERE filter is on `cd.StorageID = @StorageID` - finds the document by its external storage key
- StorageID is not guaranteed unique in CustomerDocument (though typically unique per document); multiple rows possible for unusual data states
- JOIN to Customer.Customer is INNER - customer must have a record in Customer schema
- `@StorageID` is declared as `INT` but `CustomerDocument.StorageID` is `uniqueidentifier` - this is a type mismatch that would cause a runtime conversion error in SQL Server; the procedure was likely functional in an early state where StorageID was an integer, before being changed to a GUID/uniqueidentifier type

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StorageID | INT | NO | - | CODE-BACKED | **Type mismatch**: declared as INT but BackOffice.CustomerDocument.StorageID is uniqueidentifier. The procedure will fail at runtime due to implicit conversion failure. Originally the external storage reference of the document to look up. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | DocumentID | int | NO | - | CODE-BACKED | The document's unique identifier. From BackOffice.CustomerDocument.DocumentID. |
| R2 | CID | int | NO | - | CODE-BACKED | Customer account ID that owns this document. From BackOffice.CustomerDocument.CID. |
| R3 | GCID | int | YES | - | CODE-BACKED | Group Customer ID - identifies the person across all regulatory accounts. From Customer.Customer.GCID via CID join. |
| R4 | StorageID | int | NO | - | CODE-BACKED | Echoed from @StorageID parameter. Note: the actual StorageID on the row (cd.StorageID) is not returned - the parameter value is returned instead. |
| R5 | FileName | nvarchar | YES | - | CODE-BACKED | The stored filename of the document. From BackOffice.CustomerDocument.FileName. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| cd | BackOffice.CustomerDocument | SELECT | Primary source - document lookup by StorageID |
| cc | Customer.Customer | INNER JOIN | Resolves CID to GCID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. JUNK status indicates no active callers. Likely broken due to INT/uniqueidentifier type mismatch.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetDocumentInfoByStorageID_JUNKYulia0325 (procedure - DEPRECATED)
├── BackOffice.CustomerDocument (table)
└── Customer.Customer (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocument | Table | SELECT DocumentID, CID, StorageID, FileName WHERE StorageID = @StorageID |
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

N/A for Stored Procedure. **Critical defect**: `@StorageID INT` vs `BackOffice.CustomerDocument.StorageID uniqueidentifier` - type mismatch causes runtime conversion failure. The procedure contains a commented-out `--Select *` line (line 14 of DDL), indicating experimental origin.

---

## 8. Sample Queries

### 8.1 Deprecated call (will fail due to type mismatch)
```sql
-- THIS WILL FAIL - @StorageID is INT but StorageID column is uniqueidentifier
EXEC BackOffice.GetDocumentInfoByStorageID_JUNKYulia0325 @StorageID = 12345
```

### 8.2 Correct ad-hoc replacement (using proper uniqueidentifier type)
```sql
SELECT cd.DocumentID, cd.CID, cc.GCID, cd.StorageID, cd.FileName
FROM BackOffice.CustomerDocument cd WITH (NOLOCK)
INNER JOIN Customer.Customer cc WITH (NOLOCK) ON cc.CID = cd.CID
WHERE cd.StorageID = '3E6A8B5C-1234-5678-ABCD-000000000001'  -- uniqueidentifier
```

### 8.3 If you have DocumentID - use GetDocument
```sql
EXEC BackOffice.GetDocument @documentId = 12345
-- Returns full document details including StorageID, FileName, CID, GCID, and more
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Created March 2017 (ticket 44152): "au10tix scripts For eToroDB" by Geri Reshef - part of the initial Au10tix document authentication vendor integration.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8.5/10, Logic: 8.0/10, Relationships: 7.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers (JUNK) | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetDocumentInfoByStorageID_JUNKYulia0325 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetDocumentInfoByStorageID_JUNKYulia0325.sql*
