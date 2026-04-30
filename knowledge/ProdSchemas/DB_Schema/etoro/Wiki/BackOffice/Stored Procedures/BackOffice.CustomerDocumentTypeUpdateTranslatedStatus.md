# BackOffice.CustomerDocumentTypeUpdateTranslatedStatus

> Updates the Translated status flag on a document-type classification record in BackOffice.CustomerDocumentToDocumentType. Used in the KYC translation workflow to mark foreign-language documents as translated.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DocumentToDocumentTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure updates the `Translated` column on a `BackOffice.CustomerDocumentToDocumentType` record to reflect the current translation state of a KYC document.

When customers submit identity documents in a non-English language (e.g., a passport issued in Arabic, Chinese, or Russian), the document must be translated before a BackOffice agent can review it for KYC/AML compliance. This SP is called to record that translation progress: when translation is complete (or when its status changes), the `Translated` flag is updated via this procedure.

The procedure is intentionally minimal - no validation, no error handling beyond SET NOCOUNT ON. If the supplied @DocumentToDocumentTypeID does not exist, the UPDATE silently affects 0 rows with no error.

Created by Geri Reshef (July 2017, OPS0244 - Translation and Update of Verification Info). This SP does NOT carry a JUNK suffix - it is part of the active translation workflow (unlike its sibling `CustomerDocumentTypeAdd_JUNKYulia0325` and `CustomerDocumentTypeRemove_JUNKYulia0325`).

---

## 2. Business Logic

### 2.1 Simple Flag Update - No Validation

**What**: Updates Translated on a single classification row. Fully idempotent.

**Columns/Parameters Involved**: @DocumentToDocumentTypeID, @Translated

**Rules**:
- UPDATE BackOffice.CustomerDocumentToDocumentType SET Translated=@Translated WHERE DocumentToDocumentTypeID=@DocumentToDocumentTypeID
- SET NOCOUNT ON: row count messages suppressed
- @Translated=NULL: clears the translation status (resets to unset state)
- @Translated=1: document has been translated (typical success value)
- No TRY/CATCH: any SQL errors propagate to the caller as unhandled exceptions
- Silent no-op if @DocumentToDocumentTypeID does not exist

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DocumentToDocumentTypeID | INT | NO | - | CODE-BACKED | Primary key of the document-type classification row to update. FK to BackOffice.CustomerDocumentToDocumentType.DocumentToDocumentTypeID. |
| 2 | @Translated | SMALLINT | YES | NULL | CODE-BACKED | New translation status value. SMALLINT allows multi-state translation flags. NULL = clear/reset translation status. Typical values: NULL=not set, 1=translated. Written directly to BackOffice.CustomerDocumentToDocumentType.Translated. |

**Return Value**: No result set, no return value. Success = no exception.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DocumentToDocumentTypeID | BackOffice.CustomerDocumentToDocumentType | UPDATE | Sets the Translated flag on the matching classification row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice KYC translation workflow | External | Direct call | Called when a document translation is completed or its status changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerDocumentTypeUpdateTranslatedStatus (procedure)
|- BackOffice.CustomerDocumentToDocumentType (table) [UPDATE: Translated flag]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocumentToDocumentType | Table | UPDATE target: sets Translated column for the given DocumentToDocumentTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice translation workflow | External | Calls this SP to mark documents as translated for KYC review |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages (no @@ROWCOUNT feedback to caller) |
| No error handling | Design | No TRY/CATCH - SQL errors propagate unhandled to the caller |
| No existence check | Design | Silent no-op if @DocumentToDocumentTypeID does not exist |
| Not JUNK | Lifecycle | Active SP - not marked for deprecation (unlike sibling CustomerDocumentTypeAdd/Remove JUNK variants) |

---

## 8. Sample Queries

### 8.1 Mark a document classification as translated

```sql
EXEC BackOffice.CustomerDocumentTypeUpdateTranslatedStatus
    @DocumentToDocumentTypeID = 67890,
    @Translated = 1;
```

### 8.2 Clear translation status

```sql
EXEC BackOffice.CustomerDocumentTypeUpdateTranslatedStatus
    @DocumentToDocumentTypeID = 67890,
    @Translated = NULL;
```

### 8.3 Verify the update

```sql
SELECT DocumentToDocumentTypeID, DocumentTypeID, Translated
FROM BackOffice.CustomerDocumentToDocumentType WITH (NOLOCK)
WHERE DocumentToDocumentTypeID = 67890;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Created per OPS0244 (Translation and Update of Verification Info DB Changes, July 2017).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerDocumentTypeUpdateTranslatedStatus | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerDocumentTypeUpdateTranslatedStatus.sql*
