# BackOffice.DeleteUserDocument

> Performs a full GDPR-compliant cascading delete of a customer document and all its dependent records across four BackOffice tables, in a single atomic transaction.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DocumentID - the document to delete |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.DeleteUserDocument is the GDPR Document API's primary deletion procedure, removing a customer's uploaded identity document and all related records from the BackOffice system. It implements a dependency-aware cascade: the records are deleted in strict child-before-parent order across four tables, all within a single transaction with rollback on any failure.

This procedure was built for the GDPR "right to erasure" API (RD-2131, 2019) that allows customers to request deletion of their identity documents. A follow-up change (COMOP-2937, 2021) addressed deletion errors appearing in Splunk, likely improving the CATCH block's diagnostics. The procedure is called exclusively through the SQL_UserDocAPI and PROD_SQL_DocAPI_2 database users (dedicated API service accounts), not by human BackOffice agents.

Note: Deleting a document here removes the metadata record. The actual document file stored in the external storage system (referenced by StorageID in BackOffice.CustomerDocument) must be deleted separately by the calling application.

---

## 2. Business Logic

### 2.1 Four-Table Cascade Delete (Child-Before-Parent Order)

**What**: Deletes all records related to a document in the correct dependency order to avoid FK constraint violations.

**Columns/Parameters Involved**: `@DocumentID`, `BackOffice.DocumentVendors.DocumentID`, `BackOffice.CustomerDocumentToDocumentType.DocumentID`, `BackOffice.CustomerTranslationDetails.DocumentToDocumentTypeID`, `BackOffice.CustomerDocument.DocumentID`

**Rules**:
- Step 1: DELETE BackOffice.DocumentVendors WHERE DocumentID = @DocumentID (vendor processing records).
- Step 2: DELETE BackOffice.CustomerTranslationDetails WHERE DocumentToDocumentTypeID IN (SELECT from CustomerDocumentToDocumentType WHERE DocumentID = @DocumentID) - translation records, identified via subquery through the classification junction table.
- Step 3: DELETE BackOffice.CustomerDocumentToDocumentType WHERE DocumentID = @DocumentID - removes the document-type classification records.
- Step 4: DELETE BackOffice.CustomerDocument WHERE DocumentID = @DocumentID - removes the master document record.
- All four steps run in a single BEGIN TRAN / COMMIT - atomic; any step failure triggers full ROLLBACK.

**Diagram**:
```
BEGIN TRAN
  DELETE DocumentVendors WHERE DocumentID = @DocumentID
  DELETE CustomerTranslationDetails WHERE DocumentToDocumentTypeID IN
    (SELECT DocumentToDocumentTypeID FROM CustomerDocumentToDocumentType WHERE DocumentID = @DocumentID)
  DELETE CustomerDocumentToDocumentType WHERE DocumentID = @DocumentID
  DELETE CustomerDocument WHERE DocumentID = @DocumentID
COMMIT

On error:
  ROLLBACK all four deletes
  THROW (re-raise original exception)
```

### 2.2 Error Handling - Diagnostic CATCH with Rollback

**What**: Full diagnostic context is PRINTed and the exception is re-thrown after rollback.

**Columns/Parameters Involved**: @@ServerName, DB_Name(), Object_Name(), Error_Line(), Error_Message(), @@TranCount

**Rules**:
- CATCH block PRINTs a detailed diagnostic string including server, DB, procedure, line, message, severity, transaction count, and timestamp.
- `WHILE @@TranCount > 0 ROLLBACK` - loops to ensure any nested transaction levels are all rolled back.
- `THROW` - re-raises the original exception to the caller with original error number/message preserved.
- This pattern (PRINT + loop ROLLBACK + THROW) is from the COMOP-2937 fix for tracking errors in Splunk.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DocumentID | INT | NO | - | CODE-BACKED | The document to delete. PK of BackOffice.CustomerDocument. All dependent records (in DocumentVendors, CustomerTranslationDetails, CustomerDocumentToDocumentType) are identified via this ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DocumentID | BackOffice.DocumentVendors | Deleter | Step 1: Removes vendor processing records for this document (Au10tix, Onfido, etc.). |
| @DocumentID (via subquery) | BackOffice.CustomerTranslationDetails | Deleter | Step 2: Removes translation/annotation records linked to this document's classification entries. |
| @DocumentID | BackOffice.CustomerDocumentToDocumentType | Deleter | Step 3: Removes the document-type classification junction records. |
| @DocumentID | BackOffice.CustomerDocument | Deleter | Step 4: Removes the master document metadata record. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| GDPR Document API (SQL_UserDocAPI, PROD_SQL_DocAPI_2) | EXEC | Caller | Called by the dedicated GDPR document erasure API service when processing a customer's right-to-erasure request. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.DeleteUserDocument (procedure)
├── BackOffice.DocumentVendors (table) - DELETE vendor records
├── BackOffice.CustomerTranslationDetails (table) - DELETE translation records
├── BackOffice.CustomerDocumentToDocumentType (table) - DELETE type classification records
└── BackOffice.CustomerDocument (table) - DELETE master document record
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.DocumentVendors | Table | DELETE WHERE DocumentID = @DocumentID |
| BackOffice.CustomerTranslationDetails | Table | DELETE via subquery through CustomerDocumentToDocumentType |
| BackOffice.CustomerDocumentToDocumentType | Table | DELETE WHERE DocumentID = @DocumentID + subquery source for CustomerTranslationDetails |
| BackOffice.CustomerDocument | Table | DELETE WHERE DocumentID = @DocumentID - the parent record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| GDPR Document API | External | EXEC - called for right-to-erasure requests (RD-2131, COMOP-2937) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Child-before-parent delete order | Design | Steps 1-4 must execute in this sequence to avoid FK constraint violations between the four tables. |
| Atomic transaction | Safety | All four deletes are in one transaction. Any failure rolls back all changes - no partial document deletion. |
| WHILE @@TranCount > 0 ROLLBACK | Safety | Handles nested transactions - ensures any savepoints or nested transactions are all rolled back. |
| THROW (not RAISERROR) | Convention | Re-throws the original exception, preserving the original error code and message for the caller. |
| External storage not deleted | Limitation | StorageID (the file in blob/CDN storage) is NOT deleted by this procedure - the calling application must handle external file deletion separately. |

---

## 8. Sample Queries

### 8.1 Delete a document and all its related records
```sql
EXEC BackOffice.DeleteUserDocument @DocumentID = 98765432
```

### 8.2 Check if a document still exists after deletion attempt
```sql
SELECT
    cd.DocumentID,
    cd.CID,
    cd.FileName,
    cd.StorageID
FROM BackOffice.CustomerDocument cd WITH (NOLOCK)
WHERE cd.DocumentID = 98765432
```

### 8.3 Find all documents for a customer (to identify which to delete)
```sql
SELECT
    cd.DocumentID,
    cd.CID,
    cd.FileName,
    cd.DisplayName,
    cd.UploadDate
FROM BackOffice.CustomerDocument cd WITH (NOLOCK)
WHERE cd.CID = 12345678
ORDER BY cd.UploadDate DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| RD-2131 (referenced in proc comment) | Jira | GDPR DOC API ticket that originated this procedure in 2019 |
| COMOP-2937 (referenced in proc comment) | Jira | Delete Document errors in Splunk - fix applied 2021-08-02 improving CATCH diagnostics |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 2 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 2 Jira (from inline comments) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.DeleteUserDocument | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.DeleteUserDocument.sql*
