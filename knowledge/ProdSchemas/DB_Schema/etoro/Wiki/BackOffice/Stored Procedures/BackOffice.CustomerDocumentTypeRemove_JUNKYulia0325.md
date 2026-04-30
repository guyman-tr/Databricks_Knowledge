# BackOffice.CustomerDocumentTypeRemove_JUNKYulia0325

> Deletes a document-type classification record and all its associated translation details in a single transaction. Marked JUNK by Yulia (March 2025) - superseded by the newer document classification pipeline.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DocumentToDocumentTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure removes a document-type classification from `BackOffice.CustomerDocumentToDocumentType` and cascades the delete to any associated translation detail rows in `BackOffice.CustomerTranslationDetails`. Both deletes execute within a single explicit transaction so either both succeed or both roll back.

The procedure is the inverse of `BackOffice.CustomerDocumentTypeAdd_JUNKYulia0325`: when a BackOffice agent removes a previously applied document classification (e.g., incorrectly typed a document, or undoing a Not Accepted classification), this SP is called. All translation annotations for that classification are also removed because they are only meaningful in the context of the classification row.

The delete order is intentional: `BackOffice.CustomerTranslationDetails` holds a foreign key to `BackOffice.CustomerDocumentToDocumentType` via `DocumentToDocumentTypeID`. The child rows (translation details) must be deleted before the parent row (classification) to avoid FK constraint violations.

No existence check is performed - if @DocumentToDocumentTypeID does not exist, both DELETE statements execute with 0 rows affected (no error, no-op).

The JUNK suffix (`_JUNKYulia0325`) indicates this procedure was marked for deprecation by Yulia in March 2025. Created by Geri Reshef (July 2017, OPS0244 - Translation and Update of Verification Info).

---

## 2. Business Logic

### 2.1 Ordered Transactional Delete (Child Before Parent)

**What**: Deletes translation details before the classification row to satisfy FK dependency. Both are wrapped in an explicit transaction.

**Columns/Parameters Involved**: @DocumentToDocumentTypeID

**Rules**:
1. BEGIN TRAN
2. DELETE FROM BackOffice.CustomerTranslationDetails WHERE DocumentToDocumentTypeID = @DocumentToDocumentTypeID
3. DELETE FROM BackOffice.CustomerDocumentToDocumentType WHERE DocumentToDocumentTypeID = @DocumentToDocumentTypeID
4. COMMIT
5. On any error: ROLLBACK, PRINT diagnostic, THROW (re-raise)

**Delete order rationale**: CustomerTranslationDetails references CustomerDocumentToDocumentType (FK on DocumentToDocumentTypeID). Attempting to delete the classification before its translation details would raise a FK violation. Child-first order is required.

**No existence check**: If @DocumentToDocumentTypeID does not exist in CustomerDocumentToDocumentType, no rows are deleted and no error is raised. Callers cannot distinguish "deleted successfully" from "did not exist" based on SP behavior alone.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DocumentToDocumentTypeID | INT | NO | - | CODE-BACKED | Primary key of the document-type classification row to delete. Drives deletes from both BackOffice.CustomerTranslationDetails (child) and BackOffice.CustomerDocumentToDocumentType (parent). If this ID does not exist, operation is a silent no-op. |

**Return Value**: No result set or return value. Success = no exception thrown. Failure = exception re-thrown after rollback.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DocumentToDocumentTypeID | BackOffice.CustomerTranslationDetails | DELETE | Removes all translation annotation rows for this classification (child table deleted first) |
| @DocumentToDocumentTypeID | BackOffice.CustomerDocumentToDocumentType | DELETE | Removes the document-type classification row itself (parent table deleted second) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Legacy BackOffice KYC classification UI | External | Direct call | Called when a document classification is removed by a BackOffice agent |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerDocumentTypeRemove_JUNKYulia0325 (procedure)
|- BackOffice.CustomerTranslationDetails (table) [DELETE: child rows removed first]
|- BackOffice.CustomerDocumentToDocumentType (table) [DELETE: parent row removed second]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerTranslationDetails | Table | DELETE: removes all translation details for the given DocumentToDocumentTypeID (child-first to satisfy FK) |
| BackOffice.CustomerDocumentToDocumentType | Table | DELETE: removes the classification row itself |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Legacy BackOffice document classification pipeline | External | Calls this SP to remove document type classifications |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Explicit transaction | Design | BEGIN TRAN / COMMIT wraps both DELETEs - atomicity guaranteed |
| FK-safe delete order | Design | CustomerTranslationDetails deleted before CustomerDocumentToDocumentType to satisfy FK constraint |
| TRY/CATCH + ROLLBACK + THROW | Design | On any error: ROLLBACK, detailed PRINT diagnostic (server, DB, proc, line, message, severity), THROW to re-raise |
| No existence check | Design | Silent no-op if @DocumentToDocumentTypeID does not exist - no error raised |
| JUNK designation | Lifecycle | Marked for deprecation by Yulia March 2025; do not use for new development |

---

## 8. Sample Queries

### 8.1 Remove a document-type classification

```sql
EXEC BackOffice.CustomerDocumentTypeRemove_JUNKYulia0325
    @DocumentToDocumentTypeID = 67890;
-- No result set. No exception = success.
```

### 8.2 Verify removal (check both tables)

```sql
-- Confirm classification removed
SELECT DocumentToDocumentTypeID FROM BackOffice.CustomerDocumentToDocumentType WITH (NOLOCK)
WHERE DocumentToDocumentTypeID = 67890;
-- Should return 0 rows

-- Confirm translation details also removed
SELECT TranslationDetailID FROM BackOffice.CustomerTranslationDetails WITH (NOLOCK)
WHERE DocumentToDocumentTypeID = 67890;
-- Should return 0 rows
```

### 8.3 Look up classifications for a document before removing

```sql
SELECT DocumentToDocumentTypeID, DocumentID, DocumentTypeID, IssueDate, ExpiryDate,
       FundingID, ManagerID, Comment, RejectReasonID
FROM BackOffice.CustomerDocumentToDocumentType WITH (NOLOCK)
WHERE DocumentID = 12345
ORDER BY DocumentToDocumentTypeID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Created per OPS0244 (Translation and Update of Verification Info DB Changes, July 2017).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerDocumentTypeRemove_JUNKYulia0325 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerDocumentTypeRemove_JUNKYulia0325.sql*
