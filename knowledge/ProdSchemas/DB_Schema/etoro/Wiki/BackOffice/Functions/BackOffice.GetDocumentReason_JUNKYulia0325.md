# BackOffice.GetDocumentReason_JUNKYulia0325

> DEPRECATED scalar function returning a comma-separated string of human-readable authentication rejection reason names for a KYC document, routing to the appropriate reason dictionary (POI or Selfie) based on the document's verification type.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns VARCHAR(MAX) - comma-separated Reason name list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetDocumentReason_JUNKYulia0325` retrieves the human-readable authentication rejection reason names for a KYC document. Unlike its companion `BackOffice.GetDocumentReasonID_JUNKYulia0325` which returns numeric IDs, this function returns text names like "Expired Document,Face Not Detected," making results directly displayable in the BackOffice UI without additional lookup joins.

The function type-routes reason lookups: TypeID=1 (POI/Proof of Identity) uses `Dictionary.AuthenticationReasonPOI`, while TypeID=3 and TypeID=4 (Selfie/SelfieLiveliness) use `Dictionary.AuthenticationReasonSelfie`. This routing reflects the separate reason dictionaries maintained for different document verification pipelines (Au10tix POI check vs. Au10tix Selfie check).

**DEPRECATED**: The "JUNK" prefix and Jira history (COMOP-517/COMOP-646, April 2020) confirm this is a legacy function from the DocAPI migration. No active BackOffice stored procedures call this function. It was part of the selfie authentication support feature created by Yulia Kramer on 01/04/2020.

The preferred pattern for reading document authentication reasons is to query `BackOffice.DocumentAuthenticationReasons` directly with JOINs to `Dictionary.AuthenticationReasonPOI` or `Dictionary.AuthenticationReasonSelfie` as appropriate.

---

## 2. Business Logic

### 2.1 Type-Routed Reason Name Retrieval

**What**: The function uses the document's TypeID to select the appropriate reason dictionary (POI vs. Selfie), then concatenates the matching reason names.

**Columns/Parameters Involved**: `@documentID`, TypeID (intermediate), Reason (output)

**Rules**:
- Step 1: SELECT TypeID from `BackOffice.DocumentAuthenticationReasons` WHERE DocumentID = @documentID. Defaults to @typeID=1 (POI) if no record exists.
- Step 2: CASE on @typeID to JOIN to the right dictionary:
  - @typeID=1 (POI): JOIN `Dictionary.AuthenticationReasonPOI` ON ReasonID=arp.ReasonID AND TypeID=1; use arp.Reason
  - @typeID=3 (Selfie) or @typeID=4 (SelfieLiveliness): JOIN `Dictionary.AuthenticationReasonSelfie` ON ReasonID=ars.ReasonID AND TypeID IN (3,4); use ars.Reason
  - Other TypeIDs: returns empty string (ELSE @r branch)
- The string is built by concatenation with trailing commas.
- LEFT JOINs to both dictionaries are applied, CASE selects which name to use.

**Diagram**:
```
@documentID
     |
     v
BackOffice.DocumentAuthenticationReasons
SELECT TypeID WHERE DocumentID = @documentID
     |
     +--> TypeID=1 (POI)? --> Dictionary.AuthenticationReasonPOI.Reason
     +--> TypeID=3/4 (Selfie)? --> Dictionary.AuthenticationReasonSelfie.Reason
     +--> Other? --> empty string
     |
     v
Concatenated reason names: "Expired Document,Name Mismatch,"
```

### 2.2 TypeID to Reason Dictionary Mapping

**What**: Each verification type has a dedicated reason dictionary capturing the distinct failure modes of each Au10tix check type.

**Columns/Parameters Involved**: TypeID (drives routing)

**Rules**:
- TypeID=1 (POI): Identity document checks. Reasons include document expiry, name mismatch, forgery detection, address mismatch. Source: `Dictionary.AuthenticationReasonPOI`
- TypeID=3 (Selfie): Selfie photo checks. Reasons include face not detected, liveness failure, identity mismatch. Source: `Dictionary.AuthenticationReasonSelfie`
- TypeID=4 (SelfieLiveliness): Same dictionary as TypeID=3 (handled by same CASE branch)
- TypeID=2 (POA) and TypeID=5: Not supported by this function - returns empty string

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @documentID | INT | NO | - | CODE-BACKED | The DocumentID from BackOffice.CustomerDocument identifying the KYC document whose authentication reason names to retrieve. Filters BackOffice.DocumentAuthenticationReasons and drives the TypeID lookup. |

### Return Value

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (return value) | VARCHAR(MAX) | YES | '' (empty string) | CODE-BACKED | Comma-separated list of human-readable reason names for the document's primary TypeID, with trailing comma. Examples: "Ok," for a passing document (ReasonID=0), "Expired Document,Face Not Detected," for a rejected selfie. Returns '' for unsupported TypeIDs (2, 5) or documents with no reasons. Names sourced from Dictionary.AuthenticationReasonPOI (TypeID=1) or Dictionary.AuthenticationReasonSelfie (TypeID=3,4). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @documentID | BackOffice.DocumentAuthenticationReasons | Table read | Read twice WITH (NOLOCK): (1) to determine TypeID, (2) LEFT JOIN as source of ReasonID values per document. |
| (TypeID=1 routing) | Dictionary.AuthenticationReasonPOI | Lookup | LEFT JOIN on ReasonID AND TypeID=1 to get Reason name for POI documents. |
| (TypeID=3/4 routing) | Dictionary.AuthenticationReasonSelfie | Lookup | LEFT JOIN on ReasonID AND TypeID IN (3,4) to get Reason name for Selfie/SelfieLiveliness documents. |

### 5.2 Referenced By (other objects point to this)

No active callers found. Function is deprecated (JUNK prefix).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetDocumentReason_JUNKYulia0325 (function)
├── BackOffice.DocumentAuthenticationReasons (table)
├── Dictionary.AuthenticationReasonPOI (table) [cross-schema]
└── Dictionary.AuthenticationReasonSelfie (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.DocumentAuthenticationReasons | Table | Read WITH (NOLOCK) twice: to find TypeID and as source of reason rows. |
| Dictionary.AuthenticationReasonPOI | Table | LEFT JOIN on (ReasonID, TypeID=1) to resolve reason name for POI document types. |
| Dictionary.AuthenticationReasonSelfie | Table | LEFT JOIN on (ReasonID, TypeID IN (3,4)) to resolve reason name for Selfie document types. |

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

### 8.1 Get reason names for a specific document

```sql
SELECT BackOffice.GetDocumentReason_JUNKYulia0325(12345) AS ReasonNames;
-- Returns: "Ok," or "Expired Document,Name Mismatch,"
```

### 8.2 Compare ID-based vs. name-based outputs for the same document

```sql
SELECT
    BackOffice.GetDocumentReasonID_JUNKYulia0325(12345) AS ReasonIDs,
    BackOffice.GetDocumentReason_JUNKYulia0325(12345) AS ReasonNames;
```

### 8.3 Modern alternative - direct query with joins (preferred over this deprecated function)

```sql
SELECT
    dar.DocumentID,
    dar.TypeID,
    dar.ReasonID,
    COALESCE(arp.Reason, ars.Reason) AS ReasonName
FROM BackOffice.DocumentAuthenticationReasons dar WITH (NOLOCK)
LEFT JOIN Dictionary.AuthenticationReasonPOI arp WITH (NOLOCK)
    ON dar.ReasonID = arp.ReasonID AND dar.TypeID = 1
LEFT JOIN Dictionary.AuthenticationReasonSelfie ars WITH (NOLOCK)
    ON dar.ReasonID = ars.ReasonID AND dar.TypeID IN (3,4)
WHERE dar.DocumentID = 12345;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [COMOP-517: Selfie classification fields in BO](https://etoro-jira.atlassian.net/browse/COMOP-517) | Jira Story | Parent story for selfie authentication support in BackOffice (March 2020). Function created as part of this initiative to support selfie/POI reason display. |
| [COMOP-646: Support for Selfie Reasons](https://etoro-jira.atlassian.net/browse/COMOP-646) | Jira Sub-task | Direct ticket for selfie reason support (Done). Function author Yulia Kramer, created 01/04/2020. The TypeID=3/4 routing to AuthenticationReasonSelfie was the key change introduced here. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetDocumentReason_JUNKYulia0325 | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetDocumentReason_JUNKYulia0325.sql*
