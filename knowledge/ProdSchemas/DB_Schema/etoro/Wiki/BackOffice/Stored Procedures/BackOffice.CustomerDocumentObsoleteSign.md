# BackOffice.CustomerDocumentObsoleteSign

> Marks a specific KYC/AML customer document as obsolete by setting BackOffice.CustomerDocument.Obsolete=1, indicating the document has been superseded or is no longer valid.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DocumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure marks a customer KYC/AML document as obsolete - indicating it is no longer the active, valid document for compliance purposes. Documents become obsolete when a customer submits a newer version (e.g., a renewed passport), when the document expires, or when it is replaced by a higher-quality submission.

Obsolete documents are not deleted from `BackOffice.CustomerDocument` - they are retained for regulatory audit trail purposes. The Obsolete flag enables BackOffice and compliance systems to distinguish between the currently-active document (Obsolete=0) and superseded versions (Obsolete=1) when displaying a customer's document portfolio or running compliance checks.

BackOffice.CustomerDocument holds 8.78M documents across all customers since 2009; the Obsolete flag is a key filter for surfacing only the relevant current documents.

---

## 2. Business Logic

### 2.1 Soft-Delete via Obsolete Flag

**What**: Sets Obsolete=1 on a specific document; does not delete the record.

**Columns/Parameters Involved**: `@DocumentID`, `BackOffice.CustomerDocument.Obsolete`

**Rules**:
- UPDATE BackOffice.CustomerDocument SET Obsolete=1 WHERE DocumentID=@DocumentID
- Obsolete is a hard set to 1 - no toggle; there is no "un-obsolete" operation via this procedure
- Document record remains in the table for audit trail
- Returns @@ERROR: 0 on success; non-zero on DB error

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DocumentID | INT | NO | - | CODE-BACKED | The identifier of the document to mark as obsolete. PK of BackOffice.CustomerDocument. The document record is retained; only the Obsolete flag is set to 1. |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 2 | RETURN | INT | @@ERROR: 0 on success; non-zero on SQL error. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DocumentID | BackOffice.CustomerDocument | MODIFIER | Sets Obsolete=1 WHERE DocumentID=@DocumentID |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. Called from BackOffice KYC document management UI.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerDocumentObsoleteSign (procedure)
+-- BackOffice.CustomerDocument (table) [UPDATE target - Obsolete flag]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocument | Table | UPDATE: sets Obsolete=1 WHERE DocumentID=@DocumentID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice KYC document management UI | External | Calls this when superseding a customer document with a newer submission |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Soft delete only | Design | Records are never deleted - Obsolete=1 is a soft-delete; documents retained for regulatory audit |
| One-way operation | Design | Sets Obsolete=1 only; no inverse operation in this procedure (re-activating requires direct UPDATE) |

---

## 8. Sample Queries

### 8.1 Mark a document as obsolete

```sql
DECLARE @Result INT
EXEC @Result = BackOffice.CustomerDocumentObsoleteSign @DocumentID = 99001
SELECT @Result AS Result -- 0 = success
```

### 8.2 Find a customer's active (non-obsolete) documents

```sql
SELECT DocumentID, DocumentTypeID, FileName, DisplayName, Created
FROM BackOffice.CustomerDocument WITH (NOLOCK)
WHERE CID = 12345 AND ISNULL(Obsolete, 0) = 0
ORDER BY Created DESC
```

### 8.3 View all documents for a customer including obsolete

```sql
SELECT DocumentID, ISNULL(Obsolete, 0) AS IsObsolete, DocumentTypeID, Created
FROM BackOffice.CustomerDocument WITH (NOLOCK)
WHERE CID = 12345
ORDER BY Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerDocumentObsoleteSign | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerDocumentObsoleteSign.sql*
