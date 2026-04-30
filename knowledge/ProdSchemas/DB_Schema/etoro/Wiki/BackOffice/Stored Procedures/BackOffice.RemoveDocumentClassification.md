# BackOffice.RemoveDocumentClassification

> Removes a document classification by deleting the dependent CustomerTranslationDetails rows first (EXISTS guard), then deleting the CustomerDocumentToDocumentType mapping row, inside a transaction. Returns the row count of deleted mapping rows.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | DELETE BackOffice.CustomerTranslationDetails (EXISTS guard) + DELETE BackOffice.CustomerDocumentToDocumentType; SELECT @@ROWCOUNT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.RemoveDocumentClassification` removes a document classification assignment from the system. In eToro's KYC/compliance framework, documents submitted by customers are classified by type (passport, utility bill, etc.) and stored in a mapping structure. This procedure cleanly removes that classification by deleting in dependency order:

1. First deletes the translation/label records that depend on the classification mapping (`CustomerTranslationDetails`).
2. Then deletes the classification mapping itself (`CustomerDocumentToDocumentType`).

The dependency-order deletion prevents FK violations. A transaction wraps both deletes to ensure atomicity - either both delete or neither does. The procedure returns the count of deleted mapping rows via `SELECT @@ROWCOUNT` for caller confirmation.

Implemented as part of COMOP-2095/2097 (document classification management features in the compliance operations system).

---

## 2. Business Logic

### 2.1 Dependency-Order Delete in Transaction

**What**: Two-table delete in dependency order inside a transaction, with an EXISTS guard for the first delete.

**Rules**:
- `BEGIN TRANSACTION`: both deletes are atomic - if either fails, the transaction is rolled back.
- **Step 1**: `DELETE BackOffice.CustomerTranslationDetails WHERE EXISTS (SELECT ... FROM BackOffice.CustomerDocumentToDocumentType WHERE ...)`: deletes translation/label records that belong to the target document-to-type mapping. The EXISTS guard links the translation records to the specific classification being removed without requiring a JOIN on a potentially non-indexed column.
- **Step 2**: `DELETE BackOffice.CustomerDocumentToDocumentType WHERE [target condition]`: removes the primary mapping record after its dependents are gone.
- `SELECT @@ROWCOUNT`: returns the number of rows deleted from CustomerDocumentToDocumentType (the primary target), not from CustomerTranslationDetails.
- `COMMIT`: finalizes both deletes together.
- If the classification mapping does not exist: 0 rows deleted, 0 returned (silent no-op, no error).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DocumentClassificationID | int | NO | - | NAME-INFERRED | ID of the document classification mapping to remove. Targets BackOffice.CustomerDocumentToDocumentType. The EXISTS guard in the first DELETE uses this ID to find associated CustomerTranslationDetails records. |

Output: Single-column, single-row result set with the count of deleted CustomerDocumentToDocumentType rows (via SELECT @@ROWCOUNT after the second DELETE).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Step 1 | BackOffice.CustomerTranslationDetails | Writer (DELETE) | Removes dependent translation/label records for the classification (EXISTS guard) |
| Step 2 | BackOffice.CustomerDocumentToDocumentType | Writer (DELETE) | Removes the primary document-to-type classification mapping |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found. Called from BackOffice compliance/document management UI (COMOP-2095/2097 feature).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.RemoveDocumentClassification (procedure)
+-- BackOffice.CustomerTranslationDetails (table) [DELETE - dependent records, EXISTS guard]
+-- BackOffice.CustomerDocumentToDocumentType (table) [DELETE - primary classification mapping]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerTranslationDetails | Table | DELETE - removes translation/label records dependent on the classification |
| BackOffice.CustomerDocumentToDocumentType | Table | DELETE - removes the document-to-type classification mapping row |

### 6.2 Objects That Depend On This

No SQL-layer dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BEGIN/COMMIT TRANSACTION | Atomicity | Both deletes succeed or neither does. Prevents orphaned CustomerTranslationDetails if the second delete fails. |
| EXISTS guard | Dependency filter | CustomerTranslationDetails delete uses EXISTS on CustomerDocumentToDocumentType to avoid a direct JOIN, scoping the delete to exactly the records belonging to the target classification. |

---

## 8. Sample Queries

### 8.1 Remove a document classification

```sql
EXEC BackOffice.RemoveDocumentClassification
    @DocumentClassificationID = 42;
-- Returns count of deleted CustomerDocumentToDocumentType rows (0 or 1)
```

### 8.2 Verify classification is removed

```sql
SELECT * FROM BackOffice.CustomerDocumentToDocumentType WITH (NOLOCK)
WHERE DocumentClassificationID = 42;
-- Should return 0 rows after delete

SELECT * FROM BackOffice.CustomerTranslationDetails WITH (NOLOCK)
WHERE DocumentClassificationID = 42;  -- or equivalent link column
-- Should return 0 rows after delete
```

---

## 9. Atlassian Knowledge Sources

Linked to COMOP-2095 and COMOP-2097 (document classification management - compliance operations).

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 7/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 1 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 2 Jira (COMOP-2095, COMOP-2097) | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.RemoveDocumentClassification | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.RemoveDocumentClassification.sql*
