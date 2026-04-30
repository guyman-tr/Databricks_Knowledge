# BackOffice.TncDocumentUpdateIsActive

> Updates the IsActive flag on a single Terms & Conditions document, marking it as the current valid version or as superseded by a newer one.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @documentId - targets BackOffice.TncDocument.DocumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.TncDocumentUpdateIsActive` controls the lifecycle state of a specific T&C document. When a new T&C document is uploaded for a regulatory jurisdiction, the previously active document(s) must be marked as superseded so that customers are only shown the most current version. This SP performs that atomic flag flip: `IsActive = @isActive WHERE DocumentID = @documentId`.

The procedure is required because eToro maintains historical T&C versions (for audit and regulatory compliance) - documents are never deleted. Instead, the `IsActive` flag distinguishes the current version from archived/superseded ones. Without this procedure, old T&C documents would continue appearing alongside the new version in `GetAllLatestTncDocuments` queries.

This SP is part of the T&C document upload workflow. When a new document is inserted via `BackOffice.InsertTncDocument`, any previous documents for the same regulation should be deactivated by calling this SP. The `@isActive` parameter defaults to `1`, making the SP bidirectional: it can both deactivate (pass `0`) and re-activate (omit the parameter or pass `1`) a document as needed.

---

## 2. Business Logic

### 2.1 Document Activation State Management

**What**: Controls whether a T&C document is considered the current valid version or an archived/superseded one.

**Columns/Parameters Involved**: `@documentId`, `@isActive`, `BackOffice.TncDocument.IsActive`

**Rules**:
- Pass `@isActive = 0` to supersede a document when uploading a newer version of the same regulation's T&C.
- Pass `@isActive = 1` (or omit, since default = 1) to re-activate a previously deactivated document (e.g., rolling back an accidental deactivation).
- Only the `IsActive` flag is modified - `Enabled` and all other columns remain untouched. This allows independent control: a document can be re-activated without changing its `Enabled` state.
- The SP targets one specific document by `DocumentID`. Callers are responsible for identifying the correct `DocumentID` (typically via `GetTncDocument` or `GetAllLatestTncDocuments` first).

**Diagram**:
```
New T&C upload workflow:
  1. BackOffice.GetAllLatestTncDocuments -> find current DocumentID for regulation
  2. BackOffice.TncDocumentUpdateIsActive @documentId=<old>, @isActive=0
     -> marks old version as superseded (IsActive=0)
  3. BackOffice.InsertTncDocument -> creates new document row (IsActive=1 by default)

Re-activation (rollback):
  BackOffice.TncDocumentUpdateIsActive @documentId=<doc>, @isActive=1
  -> re-activates a mistakenly deactivated document
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @documentId | int | NO | - | CODE-BACKED | DocumentID of the T&C document to update. Must match an existing `BackOffice.TncDocument.DocumentID`. Identifies exactly which document row receives the IsActive change. |
| 2 | @isActive | bit | YES | 1 | CODE-BACKED | New value for the `IsActive` flag: 0 = mark this document as superseded/archived (replaced by a newer version), 1 = mark as current and valid (default). The default of 1 supports re-activation scenarios without requiring the caller to pass the parameter explicitly. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @documentId | BackOffice.TncDocument.DocumentID | FK (implicit) | Targets the document record whose IsActive flag is being updated |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| T&C upload workflow | - | Caller | Called after inserting a new T&C document to deactivate the previous version for the same regulation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.TncDocumentUpdateIsActive (procedure)
+-- BackOffice.TncDocument (table)
      +-- Dictionary.TncDocType (table) [FK: TncDocTypeID]
      +-- Dictionary.Country (table) [FK: CountryID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [BackOffice.TncDocument](../Tables/BackOffice.TncDocument.md) | Table | UPDATE target - sets IsActive flag for the specified DocumentID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No direct callers found in repo. | - | Called as part of the T&C document upload workflow alongside BackOffice.InsertTncDocument. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Deactivate a specific T&C document (supersede with new version)

```sql
-- Step 1: Find the current active document for CySEC regulation
SELECT DocumentID, DisplayName, DateAdded, IsActive
FROM BackOffice.TncDocument WITH (NOLOCK)
WHERE RegulationID = 1 AND IsActive = 1 AND Enabled = 1
ORDER BY DateAdded DESC;

-- Step 2: Deactivate the old document
EXEC BackOffice.TncDocumentUpdateIsActive
    @documentId = 42,   -- DocumentID from step 1
    @isActive   = 0;
```

### 8.2 Re-activate a document (rollback an accidental deactivation)

```sql
-- Re-activate a mistakenly deactivated document
EXEC BackOffice.TncDocumentUpdateIsActive
    @documentId = 42,
    @isActive   = 1;    -- explicit; same as omitting (default=1)
```

### 8.3 Verify the IsActive state change

```sql
-- Before and after verification
SELECT DocumentID, RegulationID, DisplayName, IsActive, Enabled, DateAdded
FROM BackOffice.TncDocument WITH (NOLOCK)
WHERE DocumentID = 42;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Originating ticket COMOP-1392 is in an unavailable Jira project.)

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Caller Scan, Dependency Inheritance, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.TncDocumentUpdateIsActive | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.TncDocumentUpdateIsActive.sql*
