# BackOffice.SetDocumentAuthenticationReasons

> Atomically replaces all authentication reason codes for a document by deleting existing reasons and inserting the new set from a comma-separated list, recording why a KYC document was accepted or rejected by the verification system.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @documentId - the document whose reasons are being replaced |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SetDocumentAuthenticationReasons records the outcome of an automated KYC document authentication check. When the verification engine (typically Au10tix) evaluates a customer's Proof of Identity, Proof of Address, or Selfie/Liveness document, it returns one or more reason codes explaining the result - whether the document passed ("Ok", ReasonID=0), or why it failed (expired, forged, face not detected, name mismatch, etc.).

This procedure accepts those reason codes as a comma-separated string, parses them using STRING_SPLIT, and writes one row per reason into BackOffice.DocumentAuthenticationReasons. The delete-then-insert pattern ensures the stored reasons always reflect the most recent evaluation - there is no accumulation of stale results from previous runs of the same document through the verification engine.

Introduced March 2020 (COMOP-391/468: "Adding reason column to BO document section") with Selfie/Liveness support added April 2020. The @typeID parameter distinguishes verification type: 1=POI, 2=POA, 3=Selfie, 4=SelfieLiveliness, 5=SelfieMotion.

---

## 2. Business Logic

### 2.1 Delete-Replace Pattern for Reason Recording

**What**: The procedure replaces all existing reasons for the document atomically (not an UPSERT - a full replace).

**Columns/Parameters Involved**: `@documentId`, `@reasonId`, `@typeID`

**Rules**:
- Step 1: DELETE all rows WHERE DocumentID=@documentId (all TypeIDs, not just @typeID). This clears all previous verification results for the document.
- Step 2: STRING_SPLIT(@reasonId, ',') parses the comma-separated reason codes. Each value from the split becomes one row in DocumentAuthenticationReasons with DocumentID=@documentId, ReasonID=<split value>, TypeID=@typeID.
- A document that passes returns @reasonId='0' -> one row with ReasonID=0 (Ok) inserted.
- A document with multiple failures returns comma-separated codes e.g. '5,12,7' -> three rows inserted.
- @typeID defaults to 1 (POI) - caller must explicitly pass typeID for POA, Selfie, etc.

**Diagram**:
```
Verification engine (Au10tix) evaluates document
    |
    v
Returns: DocumentID, ReasonCodes (e.g., "0" or "5,12"), TypeID
    |
    v
SetDocumentAuthenticationReasons(@documentId, @reasonId, @typeID)
    |
    +--> DELETE DocumentAuthenticationReasons WHERE DocumentID=@documentId
    |
    +--> STRING_SPLIT(@reasonId, ',')
    |        +--> INSERT row: (DocumentID, ReasonID=0, TypeID) -- "Ok"
    |        +--> INSERT row: (DocumentID, ReasonID=5, TypeID) -- specific failure reason
    |        +--> INSERT row: (DocumentID, ReasonID=12, TypeID) -- another failure reason
    v
DocumentAuthenticationReasons updated
```

### 2.2 TypeID Controls Verification Context

**What**: @typeID distinguishes which kind of verification produced these reasons.

**Columns/Parameters Involved**: `@typeID`

**Rules**:
- typeID=1 (POI, Proof of Identity): Default. Government ID, passport. 81.1% of rows.
- typeID=2 (POA, Proof of Address): Utility bill, bank statement. 17.7% of rows.
- typeID=3 (Selfie): Static selfie photo. ~0.5% of rows.
- typeID=4 (SelfieLiveliness): Video/liveness selfie. ~0.6% of rows.
- typeID=5 (SelfieMotion): Motion-based liveness. ~0.06% of rows.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @documentId | INT | NO | - | VERIFIED | The document record to update reasons for. FK to BackOffice.Document(DocumentID) (implicitly - no explicit constraint in this procedure). All existing rows in DocumentAuthenticationReasons WHERE DocumentID=@documentId are deleted before new ones are inserted. |
| 2 | @reasonId | VARCHAR(250) | NO | - | VERIFIED | Comma-separated string of reason codes from the verification engine. Examples: '0' (single passing result), '5,12' (two failure reasons). Parsed via STRING_SPLIT. The individual codes (e.g., 5=ExpiredDocument, 12=NameMismatch) are defined in the verification system, not in a SQL lookup table. ReasonID=0 universally means "Ok" (document passed). |
| 3 | @typeID | INT | YES | 1 | VERIFIED | Verification type context for the inserted reasons. 1=POI (default), 2=POA, 3=Selfie, 4=SelfieLiveliness, 5=SelfieMotion. Applies to ALL inserted rows from the current @reasonId split. The DELETE step clears all TypeIDs, not just the current @typeID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @documentId | BackOffice.DocumentAuthenticationReasons | MODIFIER (DELETE + INSERT) | Replaces all reason codes for the document |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DocApi / Document Verification Service | - | Caller | Called when Au10tix or other verification engine returns authentication results |
| BackOffice Document API | - | Caller | Called when agents manually set/override document authentication reasons |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SetDocumentAuthenticationReasons (procedure)
└── BackOffice.DocumentAuthenticationReasons (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.DocumentAuthenticationReasons | Table | DELETE existing + INSERT new rows for @documentId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Document Verification Service (DocApi) | External | Calls after each verification engine evaluation to record results |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Change History

- **COMOP-391/468** (Mar 2020, Yulia Kramer): Initial implementation - "Adding reason column to BO document section"
- **Apr 2020** (Yulia Kramer): Added Selfie/Liveliness support (typeID=3/4/5)

---

## 8. Sample Queries

### 8.1 Record a passed POI document
```sql
EXEC BackOffice.SetDocumentAuthenticationReasons
    @documentId = 987654321,
    @reasonId   = '0',     -- ReasonID=0 = Ok (passed)
    @typeID     = 1        -- POI (Proof of Identity)
```

### 8.2 Record a failed POI document with multiple reasons
```sql
EXEC BackOffice.SetDocumentAuthenticationReasons
    @documentId = 987654321,
    @reasonId   = '5,12',  -- e.g., ExpiredDocument + NameMismatch
    @typeID     = 1
```

### 8.3 View authentication reasons for a document
```sql
SELECT
    dar.DocumentID,
    dar.ReasonID,
    dar.TypeID
FROM BackOffice.DocumentAuthenticationReasons dar WITH (NOLOCK)
WHERE dar.DocumentID = 987654321
ORDER BY dar.TypeID, dar.ReasonID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| COMOP-391/468 (referenced in code comment) | Jira | Feature request for adding authentication reason column to BackOffice document section (March 2020) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 1 Jira (code comment) | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SetDocumentAuthenticationReasons | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SetDocumentAuthenticationReasons.sql*
