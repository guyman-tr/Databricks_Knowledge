# BackOffice.GetDocument

> Returns complete metadata for a specific KYC document including uploader, AI vendor results, and optionally the authentication reasons assessed by document authentication vendors (Au10tix, Onfido).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Single DocumentID lookup; returns one row (or zero if StorageID IS NULL) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetDocument is the primary procedure for retrieving a KYC document's full metadata from the DocAPI (Document API). Given a DocumentID, it returns all information about that document: who uploaded it, when, where it is stored, AI vendor suggestions for its type, whether it is obsolete, and - optionally - the authentication reasons from document authentication vendors (Au10tix, Onfido) that analyzed the document.

The procedure exists as the single-document retrieval endpoint for the DocAPI service. BackOffice agents use it to inspect a specific document's details before classifying, approving, or rejecting it. The `@includeAuthResults` flag allows the caller to choose whether to include the vendor authentication analysis (expensive aggregation via STRING_AGG) or just the base document metadata (the default, for performance).

Documents without a StorageID (rare legacy edge cases) are excluded by the `WHERE StorageID IS NOT NULL` filter - a StorageID is required for the document to be retrievable from the storage system. Only 10 documents in 8.78M records have NULL StorageID, dating to early 2009.

The procedure has been enhanced extensively from 2016-2022: StorageAPI schema (2016), FTD email support (2017), authentication reasons (2020 COMOP-391), valid POI detection (2020 COMOP-511), Onfido vendor support (2021 COMOP-2473/2599), and cleanup of deprecated authentication reason types (2022).

---

## 2. Business Logic

### 2.1 Optional Authentication Results (@includeAuthResults)

**What**: The @includeAuthResults flag controls whether expensive vendor authentication data is included, allowing callers to trade completeness for performance.

**Columns/Parameters Involved**: `@includeAuthResults`, `BackOffice.DocumentAuthenticationReasons`, `Dictionary.AuthenticationReason`, `BackOffice.DocumentVendors`

**Rules**:
- `@includeAuthResults=0` (default): AuthenticationReasons and AuthenticationReasonsID columns are returned as empty strings (''). No JOIN to DocumentAuthenticationReasons or AuthenticationReason used in aggregation. Fast path.
- `@includeAuthResults=1`: `String_Agg(ar.Reason, ',')` produces comma-separated list of authentication reason names (e.g., "Expired,FaceNotVisible"). `String_Agg(cast(dar.ReasonID as varchar), ',')` produces comma-separated ReasonIDs.
- The LEFT JOINs to DocumentAuthenticationReasons and AuthenticationReason are always present but only contribute data to the output when `@includeAuthResults=1`
- Vendors (from OUTER APPLY on BackOffice.DocumentVendors) are always returned regardless of the flag

**Diagram**:
```
@includeAuthResults=0 (fast):
  AuthenticationReasons = ''
  AuthenticationReasonsID = ''
  Vendors = 'Au10tix,Onfido' (always returned)

@includeAuthResults=1 (full):
  AuthenticationReasons = 'Expired,FaceNotVisible'
  AuthenticationReasonsID = '3,7'
  Vendors = 'Au10tix,Onfido'
```

### 2.2 GROUP BY for Multi-Vendor Aggregation

**What**: A GROUP BY is required because a document may have multiple authentication reason entries (one per vendor/reason combination); STRING_AGG collapses these into a single row.

**Rules**:
- One document can have multiple rows in DocumentAuthenticationReasons (one per ReasonID per authentication vendor assessment)
- GROUP BY on all non-aggregated columns ensures one result row per DocumentID
- The GROUP BY includes `dar.TypeID` even though TypeID is not in the SELECT list - this was a legacy group key from when TypeID was selected; it remains to preserve existing aggregation behavior (Mikolaj 2022 COMOP cleanup removed TypeID from SELECT but left it in GROUP BY)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @documentId | INT | NO | - | CODE-BACKED | The DocumentID of the document to retrieve. PK of BackOffice.CustomerDocument. |
| 2 | @includeAuthResults | BIT | NO | 0 | CODE-BACKED | Whether to include authentication reason details from document vendors. 0=return empty strings (default, fast), 1=aggregate and return vendor authentication reasons and reason IDs. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | DocumentID | int | NO | - | CODE-BACKED | The document's unique identifier. From BackOffice.CustomerDocument. |
| R2 | GCID | int | YES | - | CODE-BACKED | Group Customer ID of the document owner - identifies the person across all regulatory accounts. From Customer.Customer.GCID via CID join. |
| R3 | DateAdded | datetime | NO | - | CODE-BACKED | When the document was uploaded. From BackOffice.CustomerDocument.DateAdded. |
| R4 | DisplayName | nvarchar | YES | - | CODE-BACKED | The filename shown to BackOffice staff and customers (original uploaded filename). From BackOffice.CustomerDocument.DisplayName. |
| R5 | FileName | nvarchar | YES | - | CODE-BACKED | The stored/persisted filename in the system (may differ from DisplayName if renamed on upload). From BackOffice.CustomerDocument.FileName. |
| R6 | AddedBy | nvarchar | YES | - | CODE-BACKED | Login name of the BackOffice manager who uploaded the document. NULL if uploaded by the customer (ManagerID=0 or not in BackOffice.Manager). From BackOffice.Manager.Login. |
| R7 | Comment | nvarchar | YES | - | CODE-BACKED | Free-text comment on the document. From BackOffice.CustomerDocument.Comment. |
| R8 | StorageID | uniqueidentifier | NO | - | CODE-BACKED | External storage system reference key (blob storage / CDN). The WHERE clause filters to `StorageID IS NOT NULL` so this is always populated in results. From BackOffice.CustomerDocument.StorageID. |
| R9 | SuggestedDocumentTypeID | int | YES | - | CODE-BACKED | Document type suggested by AI classification (Au10tix/Onfido). FK to Dictionary.DocumentType. Not the official classification - that is in BackOffice.CustomerDocumentToDocumentType. From BackOffice.CustomerDocument. |
| R10 | CID | int | NO | - | CODE-BACKED | Customer account ID. From BackOffice.CustomerDocument.CID. |
| R11 | SessionID | int | YES | - | CODE-BACKED | Session ID associated with the document upload event. From BackOffice.CustomerDocument.SessionID. |
| R12 | Obsolete | bit | NO | - | CODE-BACKED | 1 if the document has been marked obsolete (superseded by a newer submission). From BackOffice.CustomerDocument.Obsolete. Added Nov 2020 (David Z). |
| R13 | SuggestedDocumentSubTypeID | int | YES | - | CODE-BACKED | Document sub-type suggested by AI (e.g., passport vs driving license within Proof of Identity). From BackOffice.CustomerDocument.SuggestedDocumentSubTypeID. |
| R14 | Vendors | nvarchar | YES | - | CODE-BACKED | Comma-separated list of authentication vendor names that analyzed this document (e.g., "Au10tix", "Au10tix,Onfido"). From BackOffice.DocumentVendors via OUTER APPLY with STRING_AGG. Always included (not gated by @includeAuthResults). |
| R15 | AuthenticationReasons | nvarchar | YES | - | CODE-BACKED | Comma-separated vendor authentication reason names (e.g., "Expired,FaceNotVisible"). Empty string when @includeAuthResults=0. From Dictionary.AuthenticationReason via BackOffice.DocumentAuthenticationReasons. |
| R16 | AuthenticationReasonsID | nvarchar | YES | - | CODE-BACKED | Comma-separated vendor authentication reason IDs corresponding to AuthenticationReasons. Empty string when @includeAuthResults=0. From BackOffice.DocumentAuthenticationReasons.ReasonID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| cd | BackOffice.CustomerDocument | SELECT | Primary source - document metadata |
| cc | Customer.Customer | JOIN | Resolves CID to GCID |
| m | BackOffice.Manager | LEFT JOIN | Resolves ManagerID to login name (AddedBy) |
| dar | BackOffice.DocumentAuthenticationReasons | LEFT JOIN | Authentication reason records per document |
| ar | Dictionary.AuthenticationReason | LEFT JOIN | Reason name lookup |
| dv | BackOffice.DocumentVendors | OUTER APPLY | Vendor names aggregated per document |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from the DocAPI service for BackOffice document retrieval. No stored procedure callers found within BackOffice schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetDocument (procedure)
├── BackOffice.CustomerDocument (table)
├── Customer.Customer (table - cross-schema)
├── BackOffice.Manager (table)
├── BackOffice.DocumentAuthenticationReasons (table)
├── Dictionary.AuthenticationReason (table)
└── BackOffice.DocumentVendors (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocument | Table | Primary source; filtered to DocumentID = @documentId AND StorageID IS NOT NULL |
| Customer.Customer | Table | JOIN on CID to get GCID |
| BackOffice.Manager | Table | LEFT JOIN on ManagerID to get login name (AddedBy) |
| BackOffice.DocumentAuthenticationReasons | Table | LEFT JOIN on DocumentID for authentication reason records |
| Dictionary.AuthenticationReason | Table | LEFT JOIN on ReasonID for reason name; used in STRING_AGG when @includeAuthResults=1 |
| BackOffice.DocumentVendors | Table | OUTER APPLY with STRING_AGG to get comma-separated vendor names |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DocAPI service | External | READER - retrieves document details for BackOffice UI and document processing workflows |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Notable: the GROUP BY includes `dar.TypeID` (not in SELECT) - a legacy artifact from before COMOP cleanup (Mikolaj, 2022) removed TypeID from the output while leaving the GROUP BY unchanged. This affects aggregation granularity but produces correct results since TypeID maps 1:1 with document context.

---

## 8. Sample Queries

### 8.1 Get basic document details (fast - no auth results)
```sql
EXEC BackOffice.GetDocument @documentId = 12345
-- Returns one row with document metadata; AuthenticationReasons and AuthenticationReasonsID = ''
```

### 8.2 Get document with full authentication vendor results
```sql
EXEC BackOffice.GetDocument
    @documentId = 12345,
    @includeAuthResults = 1
-- Returns one row including comma-separated vendor reasons
```

### 8.3 Equivalent ad-hoc query for document inspection
```sql
SELECT
    cd.DocumentID, cc.GCID, cd.DateAdded, cd.DisplayName,
    cd.StorageID, cd.SuggestedDocumentTypeID, cd.Obsolete
FROM BackOffice.CustomerDocument cd WITH (NOLOCK)
JOIN Customer.Customer cc WITH (NOLOCK) ON cc.CID = cd.CID
WHERE cd.DocumentID = 12345
  AND cd.StorageID IS NOT NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Change history from DDL comments: COMOP-391 (authentication reasons, 2020), COMOP-511 (POI validity detection, 2020), COMOP-732 (StorageId=null handling, 2020), COMOP-1932/1933 (DB optimizations, 2020), COMOP-2473/2517 (Onfido Selfie/POI, 2021), COMOP-2599/2545 (Onfido vendors + email, 2021), COMOP cleanup (2022).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetDocument | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetDocument.sql*
