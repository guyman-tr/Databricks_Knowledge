# BackOffice.GetDocumentReasonID_JUNKYulia0325

> DEPRECATED scalar function that returns a comma-separated string of authentication reason IDs for a KYC document, filtered to the document's primary verification type (POI/POA/Selfie).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns VARCHAR(MAX) - comma-separated ReasonID list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetDocumentReasonID_JUNKYulia0325` retrieves the authentication reason codes (IDs) associated with a specific KYC document, returning them as a comma-separated string. The function first determines the document's verification type (TypeID) by looking up any existing reason record, then fetches all ReasonIDs for that document/type combination. The result is a string like "0," or "3,7,12," representing reason code IDs that explain why a document was accepted or rejected.

**DEPRECATED**: The "JUNK" prefix in the name and Jira history (COMOP-517, COMOP-646 from April 2020 - "Selfie classification fields in BO / Support for Selfie Reasons") indicate this function was created as part of the DocAPI migration and is now considered legacy. No active stored procedures in the BackOffice schema call this function.

This function is the ID-returning companion to `BackOffice.GetDocumentReason_JUNKYulia0325`, which returns human-readable reason names instead of IDs. Both were created by Yulia Kramer on 01/04/2020 for the selfie authentication support project (COMOP-517/646).

The BackOffice UI used these functions to display document rejection reasons in the document review screen. The newer `BackOffice.SetDocumentAuthenticationReasons` procedure handles the write side with a delete-replace pattern (see `BackOffice.DocumentAuthenticationReasons` documentation for full lifecycle).

---

## 2. Business Logic

### 2.1 Type-First Reason ID Retrieval

**What**: The function uses a two-step lookup: first determine the document's TypeID (verification category), then collect all ReasonIDs for that type.

**Columns/Parameters Involved**: `@documentID`, TypeID (intermediate), ReasonID (output)

**Rules**:
- Step 1: SELECT TypeID from `BackOffice.DocumentAuthenticationReasons` WHERE DocumentID = @documentID. This finds the primary verification type for the document (defaulting to @typeID=1 POI if no row exists).
- Step 2: Concatenate all ReasonIDs as VARCHAR(10) with comma separators, filtered to DocumentID = @documentID AND TypeID = @typeID.
- The string-building pattern uses variable concatenation: `SET @rID = @rID + CAST(ReasonID AS varchar(10)) + ','`.
- Result includes a trailing comma (e.g., "0," or "3,7,").
- TypeID=1 is the default (POI - Proof of Identity). If no rows exist for the document, @typeID remains 1.

**Diagram**:
```
@documentID
     |
     v
BackOffice.DocumentAuthenticationReasons
SELECT TypeID WHERE DocumentID = @documentID
     |
     v (determines primary TypeID)
BackOffice.DocumentAuthenticationReasons
SELECT all ReasonIDs WHERE DocumentID = @documentID AND TypeID = @typeID
     |
     v (concatenate)
"0,"  or  "3,7,12,"
```

### 2.2 TypeID Semantics

**What**: TypeID determines which verification category's reasons to retrieve, reflecting the Au10tix multi-check pipeline.

**Columns/Parameters Involved**: TypeID (intermediate variable)

**Rules**:
- TypeID=1: POI (Proof of Identity) - dominates at 81.1% of DocumentAuthenticationReasons rows
- TypeID=2: POA (Proof of Address) - 17.7% of rows
- TypeID=3: Selfie - ~0.5%
- TypeID=4: SelfieLiveliness - ~0.6%
- TypeID=5: SelfieMotion - ~0.06%
- See `BackOffice.DocumentAuthenticationReasons` for full TypeID distribution.

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @documentID | INT | NO | - | CODE-BACKED | The DocumentID from BackOffice.CustomerDocument identifying the KYC document whose authentication reason IDs to retrieve. Filters BackOffice.DocumentAuthenticationReasons by DocumentID. |

### Return Value

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (return value) | VARCHAR(MAX) | YES | '' (empty string) | CODE-BACKED | Comma-separated list of ReasonID values (integers) for the document's primary TypeID, with a trailing comma. Example: "0," for a document that passed (ReasonID=0 means OK). Example: "3,7," for a document with two rejection reasons. Returns '' (empty string) if no reasons exist for the document. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @documentID | BackOffice.DocumentAuthenticationReasons | Table read | Read twice: once to determine TypeID, once to collect all ReasonIDs for that TypeID. Both queries are WITH (NOLOCK). |

### 5.2 Referenced By (other objects point to this)

No active callers found. Function is deprecated (JUNK prefix).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetDocumentReasonID_JUNKYulia0325 (function)
└── BackOffice.DocumentAuthenticationReasons (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.DocumentAuthenticationReasons | Table | Read WITH (NOLOCK) twice: (1) to find TypeID for the document, (2) to collect all ReasonIDs filtered to that TypeID. |

### 6.2 Objects That Depend On This

No dependents found. Deprecated function - no active callers in BackOffice schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function.

---

## 8. Sample Queries

### 8.1 Get reason IDs for a specific document

```sql
SELECT BackOffice.GetDocumentReasonID_JUNKYulia0325(12345) AS ReasonIDs;
-- Returns: "0," if document passed, or "3,7," if two rejection reasons
```

### 8.2 Compare reason IDs and names for a document

```sql
SELECT
    12345 AS DocumentID,
    BackOffice.GetDocumentReasonID_JUNKYulia0325(12345) AS ReasonIDs,
    BackOffice.GetDocumentReason_JUNKYulia0325(12345) AS ReasonNames;
-- Shows both IDs and human-readable names for the same document
```

### 8.3 View raw DocumentAuthenticationReasons for a document (preferred over this deprecated function)

```sql
SELECT dar.DocumentID, dar.ReasonID, dar.TypeID,
    arp.Reason AS POIReason
FROM BackOffice.DocumentAuthenticationReasons dar WITH (NOLOCK)
LEFT JOIN Dictionary.AuthenticationReasonPOI arp WITH (NOLOCK)
    ON dar.ReasonID = arp.ReasonID AND dar.TypeID = 1
WHERE dar.DocumentID = 12345;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [COMOP-517: Selfie classification fields in BO](https://etoro-jira.atlassian.net/browse/COMOP-517) | Jira Story | Parent story for selfie authentication support in BackOffice. Created March 2020. This function was part of the DocAPI migration to support selfie reason codes. |
| [COMOP-646: Support for Selfie Reasons](https://etoro-jira.atlassian.net/browse/COMOP-646) | Jira Sub-task | Direct ticket for selfie reason support (Done). Function created by Yulia Kramer 01/04/2020 as part of this feature. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.9/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetDocumentReasonID_JUNKYulia0325 | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetDocumentReasonID_JUNKYulia0325.sql*
