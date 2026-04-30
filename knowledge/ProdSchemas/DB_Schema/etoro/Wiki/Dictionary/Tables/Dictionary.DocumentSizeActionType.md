# Dictionary.DocumentSizeActionType

> Lookup table defining the processing states of document image size reduction — whether the reduced-size version is ready, unavailable, or not yet processed.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

When customers upload KYC documents, the original images can be very large (high-resolution photos from phone cameras). The platform creates reduced-size versions of these images for efficient display in the BackOffice review UI and for bandwidth-sensitive operations. This table tracks the state of that size reduction process for each document: whether the reduced version is ready to use, whether no reduced version exists (original too small to reduce, or reduction failed), or whether the file hasn't been processed yet.

Without this table, the BackOffice document review system would have no way to know whether to serve the original or reduced image. The `BackOffice.CustomerDocument` table stores the size action type for each document, and the `BackOffice.InsertCustomerDocument` / `BackOffice.InsertDocument` / `BackOffice.CustomerDocumentAdd` procedures set it during document upload.

---

## 2. Business Logic

### 2.1 Document Size Processing Pipeline

**What**: Uploaded document images go through a size reduction pipeline with tracked processing states.

**Columns/Parameters Involved**: `ID`, `ActionName`

**Rules**:
- "the reduced size is ready to be used" (0) — processing complete, the BackOffice UI can display the smaller version for faster loading
- "no reduced size version is available" (1) — either the original is already small enough, the reduction failed, or the file type doesn't support resizing
- "the file was not processed yet" (2) — the document was recently uploaded and the async size reduction job hasn't run yet. The original will be served until processing completes

---

## 3. Data Overview

| ID | ActionName | Meaning |
|---|---|---|
| 0 | the reduced size is ready to be used | The document image has been successfully resized — a smaller version is available for the BackOffice UI, improving page load times during KYC review sessions |
| 1 | no reduced size version is available | No reduced version exists for this document — either the original file was already small enough, the reduction service encountered an error, or the file format doesn't support resizing |
| 2 | the file was not processed yet | The document was recently uploaded and is queued for size reduction — the asynchronous processing job has not yet picked up this file. The full-size original is served in the meantime |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key identifying the size action state. 0=ready, 1=unavailable, 2=not yet processed. Referenced by BackOffice.CustomerDocument.DocumentSizeActionTypeID and set by document insertion procedures. |
| 2 | ActionName | varchar(50) | NO | - | CODE-BACKED | Descriptive text explaining the current size processing state. Written as full sentences (unusual for a dictionary table) — used directly in UI or logs without transformation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerDocument | DocumentSizeActionTypeID | Implicit | Stores the size processing state for each uploaded document |
| BackOffice.InsertCustomerDocument | @DocumentSizeActionTypeID | Implicit | Sets the initial size action type when a document is uploaded |
| BackOffice.InsertDocument | @DocumentSizeActionTypeID | Implicit | Alternative document insertion procedure |
| BackOffice.CustomerDocumentAdd | @DocumentSizeActionTypeID | Implicit | Another document creation procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.DocumentSizeActionType (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocument | Table | References — stores size action state per document |
| BackOffice.InsertCustomerDocument | Procedure | Writer — sets initial state on upload |
| BackOffice.InsertDocument | Procedure | Writer — sets initial state on upload |
| BackOffice.CustomerDocumentAdd | Procedure | Writer — sets initial state on upload |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.DocumentSizeActionType | CLUSTERED | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all size action types
```sql
SELECT  ID,
        ActionName
FROM    Dictionary.DocumentSizeActionType WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Find documents pending size reduction
```sql
SELECT  cd.DocumentID,
        cd.CID,
        dsat.ActionName AS SizeStatus
FROM    BackOffice.CustomerDocument cd WITH (NOLOCK)
        JOIN Dictionary.DocumentSizeActionType dsat WITH (NOLOCK) ON cd.DocumentSizeActionTypeID = dsat.ID
WHERE   cd.DocumentSizeActionTypeID = 2  -- not processed yet
```

### 8.3 Size processing state distribution
```sql
SELECT  dsat.ActionName AS SizeStatus,
        COUNT(*) AS DocumentCount
FROM    BackOffice.CustomerDocument cd WITH (NOLOCK)
        JOIN Dictionary.DocumentSizeActionType dsat WITH (NOLOCK) ON cd.DocumentSizeActionTypeID = dsat.ID
GROUP BY dsat.ActionName
ORDER BY DocumentCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.DocumentSizeActionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.DocumentSizeActionType.sql*
