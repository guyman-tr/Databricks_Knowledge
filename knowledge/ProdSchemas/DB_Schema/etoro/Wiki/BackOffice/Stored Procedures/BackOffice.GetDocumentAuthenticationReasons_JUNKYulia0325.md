# BackOffice.GetDocumentAuthenticationReasons_JUNKYulia0325

> **DEPRECATED (JUNK)** - Returns authentication reason records for a specific document by type; functionality superseded by BackOffice.GetDocument with @includeAuthResults=1.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns rows from BackOffice.DocumentAuthenticationReasons for (DocumentID, TypeID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetDocumentAuthenticationReasons_JUNKYulia0325 is a **deprecated** stored procedure (marked JUNK) that returns the authentication reason records from `BackOffice.DocumentAuthenticationReasons` for a specific document and authentication type. It was created in April 2020 (Yulia Kramer) to support the DocAPI's selfie authentication reasons feature, allowing the API to retrieve which authentication issues were flagged for a given document type (e.g., selfie vs passport authentication reasons).

The `_JUNKYulia0325` suffix indicates this procedure has been scheduled for decommissioning as of March 2025. Its functionality is fully covered by `BackOffice.GetDocument` with `@includeAuthResults=1`, which returns authentication reasons inline with all other document metadata. This procedure should no longer be called by new code.

---

## 2. Business Logic

### 2.1 Authentication Type Filtering

**What**: The @typeID parameter filters to a specific category of authentication reason (e.g., selfie reasons vs document reasons).

**Columns/Parameters Involved**: `@typeID`, `BackOffice.DocumentAuthenticationReasons.TypeID`

**Rules**:
- Default `@typeID=1`: selfie authentication reasons (was the primary use case when created for Selfie Reasons SP)
- Other TypeID values correspond to different document authentication categories defined in BackOffice.DocumentAuthenticationReasons
- The procedure returns raw ReasonIDs - callers must join to Dictionary.AuthenticationReason separately for reason names

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @documentId | INT | NO | - | CODE-BACKED | The DocumentID of the document whose authentication reasons are requested. FK to BackOffice.CustomerDocument. |
| 2 | @typeID | INT | NO | 1 | CODE-BACKED | Authentication category type filter. Default 1 = selfie authentication reasons (original use case). Other values filter to different authentication reason categories. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | DocumentID | int | NO | - | CODE-BACKED | Document identifier. Matches @documentId. |
| R2 | ReasonID | int | NO | - | CODE-BACKED | Authentication reason identifier. FK to Dictionary.AuthenticationReason. The reason flagged by the authentication vendor for this document. |
| R3 | TypeID | int | NO | - | CODE-BACKED | Authentication reason category. Matches @typeID filter. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | BackOffice.DocumentAuthenticationReasons | SELECT | Source of authentication reason records per document and type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. JUNK status indicates no active callers. Superseded by BackOffice.GetDocument.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetDocumentAuthenticationReasons_JUNKYulia0325 (procedure - DEPRECATED)
└── BackOffice.DocumentAuthenticationReasons (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.DocumentAuthenticationReasons | Table | SELECT filtered by DocumentID and TypeID |

### 6.2 Objects That Depend On This

No dependents found. JUNK status - marked for decommissioning.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get selfie authentication reasons for a document (default behavior)
```sql
EXEC BackOffice.GetDocumentAuthenticationReasons_JUNKYulia0325
    @documentId = 12345
-- Returns ReasonIDs for TypeID=1 (selfie reasons)
```

### 8.2 Preferred replacement - use GetDocument with @includeAuthResults=1
```sql
EXEC BackOffice.GetDocument
    @documentId = 12345,
    @includeAuthResults = 1
-- Returns full document details + AuthenticationReasons (all types, comma-separated)
```

### 8.3 Ad-hoc equivalent with reason names
```sql
SELECT dar.DocumentID, dar.ReasonID, dar.TypeID, ar.Reason AS ReasonName
FROM BackOffice.DocumentAuthenticationReasons dar WITH (NOLOCK)
JOIN Dictionary.AuthenticationReason ar WITH (NOLOCK) ON ar.ReasonID = dar.ReasonID
WHERE dar.DocumentID = 12345
  AND dar.TypeID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Created April 2020 per DDL comment: "DocApi Support for Selfie Reasons SP".

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers (JUNK) | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetDocumentAuthenticationReasons_JUNKYulia0325 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetDocumentAuthenticationReasons_JUNKYulia0325.sql*
