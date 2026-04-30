# BackOffice.GetAllUserDocuments

> Returns all uploaded KYC documents for a customer (by GCID) with vendor processing history and optional authentication reasons, used by the BackOffice DocAPI layer.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid - global customer identifier; returns one row per document-authentication-type combination |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetAllUserDocuments` is the primary document metadata retrieval procedure for the DocAPI layer. It returns all uploaded KYC documents for a customer - their passport scans, utility bills, selfies, and other identity documents - enriched with the verification vendors that processed each document and optionally the authentication outcome reasons.

This procedure is the "document inventory" view: while `GetAllDocumentClassifications` shows how documents were classified (Proof of Identity, POA, etc.), `GetAllUserDocuments` shows what was uploaded, when, by whom, and what automated vendors processed it. It drives the document listing panel in the BackOffice customer view, showing upload metadata alongside vendor results.

The procedure has been heavily evolved since its creation in August 2017 (ticket 47311). Key additions: Au10tix details in January 2020 (PROD-79), authentication reasons column in March 2020 (COMOP-391/468), StorageID null handling in April 2020 (COMOP-732/833), performance optimizations in December 2020 (COMOP-1932/1933), and Onfido vendor support in April 2021 (COMOP-2473/2545). Authentication reason types were removed in March 2022.

The `StorageID IS NOT NULL` filter silently excludes documents that were uploaded but never stored in the external storage system - a data quality guard ensuring only actionable documents are returned.

---

## 2. Business Logic

### 2.1 Vendor Aggregation (Comma-Separated List)

**What**: Multiple KYC vendors may process the same document; all are returned as a comma-separated string.

**Columns/Parameters Involved**: `dv.Vendors` (OUTER APPLY), `BackOffice.DocumentVendors`

**Rules**:
- OUTER APPLY selects STRING_AGG(Vendor, ',') grouped by DocumentID from BackOffice.DocumentVendors.
- Known vendors: "Onfido" (31.8%), "Sumsub" (5.2%), "Au10tix" (1.5%), "IDnow" (0.8%), "100" (60.8% - legacy numeric code).
- A document can have multiple vendor entries (re-processed by a second vendor).
- NULL if no vendor processed the document (new uploads not yet sent to a vendor).
- Documents with StorageID IS NULL are already excluded before this join.

### 2.2 Authentication Reasons (Conditional Aggregation)

**What**: Authentication outcome reasons from the verification system are only returned when @includeAuthResults=1, avoiding unnecessary processing cost.

**Columns/Parameters Involved**: `@includeAuthResults`, `dar.Reason` (via Dictionary.AuthenticationReason), `dar.ReasonID`

**Rules**:
- @includeAuthResults=0 (default): Both AuthenticationReasons and AuthenticationReasonsID return '' (empty string).
- @includeAuthResults=1: Returns comma-separated reason text and reason IDs from DocumentAuthenticationReasons + Dictionary.AuthenticationReason.
- ReasonID=0 ("Ok") = document passed verification; non-zero = authentication issues (expired document, face not detected, address mismatch, etc.).
- Grouped by dar.TypeID (included in GROUP BY but NOT in SELECT) - this means rows can be duplicated per TypeID if a document has reasons across different verification types (POI=1, POA=2, Selfie=3+).

### 2.3 Date Filter

**What**: @minDateAdded optionally limits results to recently uploaded documents.

**Columns/Parameters Involved**: `@minDateAdded`, `cd.DateAdded`

**Rules**:
- Filter: `DateAdded >= ISNULL(@minDateAdded, cd.DateAdded)` - when @minDateAdded is NULL, the ISNULL returns the row's own DateAdded, making the condition always true (no filter).
- When provided, returns only documents uploaded on or after @minDateAdded.
- Used by Au10tix service (PROD-79) to fetch recently added documents for processing.

### 2.4 StorageID NOT NULL Gate

**What**: Only documents with a storage location are returned.

**Columns/Parameters Involved**: `cd.StorageID`

**Rules**:
- `cd.StorageID IS NOT NULL` excludes document records that exist in BackOffice.CustomerDocument but were never stored in the external storage system.
- Added April 2020 (COMOP-732/833) - before this, NULL StorageID records caused issues in the DocAPI layer.
- Approximately matches the count of documents with an actual file accessible to the application.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | INT | NO | - | CODE-BACKED | Global Customer ID (GCID). Joined to Customer.CustomerStatic.GCID for CID resolution. Used to filter BackOffice.CustomerDocument by CID. |
| 2 | @minDateAdded | DATETIME | YES | NULL | CODE-BACKED | Optional minimum upload date. When provided, returns only documents uploaded on or after this date. NULL (default) returns all documents. Used by Au10tix service to fetch recent documents. |
| 3 | @includeAuthResults | BIT | NO | 0 | CODE-BACKED | Whether to include authentication outcome reasons. 0=exclude (returns '' for reason columns, better performance); 1=include comma-separated reason text and IDs from DocumentAuthenticationReasons. |
| 4 | DocumentID | INT | NO | - | CODE-BACKED | Primary key of the BackOffice.CustomerDocument record. Identifies the physical document upload. |
| 5 | GCID | INT | NO | - | CODE-BACKED | Global Customer ID - same as @gcid. From Customer.CustomerStatic.GCID (JOIN on CID). |
| 6 | DateAdded | DATETIME | NO | - | CODE-BACKED | UTC timestamp when the document was uploaded to BackOffice.CustomerDocument. |
| 7 | DisplayName | NVARCHAR | YES | - | CODE-BACKED | Human-readable name for this document as displayed in BackOffice (e.g., "Passport front side"). |
| 8 | FileName | NVARCHAR | NO | - | CODE-BACKED | File path/name in the storage system. Reference for retrieving the actual document file. |
| 9 | AddedBy | VARCHAR | YES | - | CODE-BACKED | Login of the BackOffice.Manager who uploaded the document. NULL if ManagerID=0/NULL (customer self-upload via web/mobile) or no matching manager found. |
| 10 | Comment | NVARCHAR | YES | - | CODE-BACKED | Free-text comment on the document upload. Often empty; may contain instructions or notes from the manager who uploaded on behalf of a customer. |
| 11 | StorageID | INT | NO | - | CODE-BACKED | External storage system reference. IS NOT NULL guaranteed by WHERE filter - every returned row has a stored file. |
| 12 | SuggestedDocumentTypeID | INT | YES | - | CODE-BACKED | Document type suggested by an automated vendor (Au10tix, Onfido) before BackOffice agent classification. FK to Dictionary.DocumentType. NULL if no suggestion made. |
| 13 | SessionID | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Session identifier linking this document to the verification session in which it was submitted. Used to correlate documents from the same customer interaction. |
| 14 | Obsolete | BIT | YES | - | CODE-BACKED | Whether this document upload has been marked obsolete (superseded by a newer upload). Added Nov 2020 (David Z). 1=obsolete, 0/NULL=current. |
| 15 | SuggestedDocumentSubTypeID | INT | YES | - | CODE-BACKED | Sub-type suggestion from automated vendor (e.g., specific passport type, card side). Refines SuggestedDocumentTypeID. |
| 16 | Vendors | NVARCHAR | YES | - | CODE-BACKED | Comma-separated list of KYC vendors that processed this document. Values: "Onfido", "Sumsub", "Au10tix", "IDnow", "100" (legacy). NULL if no vendor processed. From STRING_AGG over BackOffice.DocumentVendors. |
| 17 | AuthenticationReasons | NVARCHAR | NO | '' | CODE-BACKED | Comma-separated authentication reason text (e.g., "Ok", "Expired Document", "Face Not Detected"). Empty string when @includeAuthResults=0. From STRING_AGG over DocumentAuthenticationReasons JOIN Dictionary.AuthenticationReason. |
| 18 | AuthenticationReasonsID | NVARCHAR | NO | '' | CODE-BACKED | Comma-separated authentication reason IDs (e.g., "0", "4,12"). Empty string when @includeAuthResults=0. 0=Ok (passed). Maps to Dictionary.AuthenticationReason for labels. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid / GCID | Customer.CustomerStatic | JOIN (GCID resolution) | Resolves GCID to CID via INNER JOIN. |
| DocumentID | BackOffice.CustomerDocument | Primary source | All document upload records for this customer. |
| cd.ManagerID | BackOffice.Manager | Lookup (LEFT JOIN) | Resolves manager ID to Login for AddedBy. |
| DocumentID | BackOffice.DocumentAuthenticationReasons | Lookup (LEFT JOIN) | Authentication outcome reasons per document. |
| dar.ReasonID | Dictionary.AuthenticationReason | Lookup (LEFT JOIN) | Resolves reason ID to human-readable text. |
| DocumentID | BackOffice.DocumentVendors | Aggregation (OUTER APPLY) | Comma-aggregated vendor names per document. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by SQL_UserDocAPI and PROD_BIadmins service accounts. No SQL procedure callers in repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetAllUserDocuments (procedure)
├── BackOffice.CustomerDocument (table)
├── Customer.CustomerStatic (table) [cross-schema]
├── BackOffice.Manager (table)
├── BackOffice.DocumentAuthenticationReasons (table)
├── Dictionary.AuthenticationReason (table) [cross-schema]
└── BackOffice.DocumentVendors (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocument | Table | Main source - document upload records filtered by CID+StorageID+DateAdded. |
| Customer.CustomerStatic | Table | INNER JOIN on CID to filter by GCID and return GCID in output. |
| BackOffice.Manager | Table | LEFT JOIN on ManagerID for AddedBy login. |
| BackOffice.DocumentAuthenticationReasons | Table | LEFT JOIN for authentication outcome reason IDs. |
| Dictionary.AuthenticationReason | Table | LEFT JOIN for authentication reason text labels. |
| BackOffice.DocumentVendors | Table | OUTER APPLY STRING_AGG for comma-separated vendor list. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by DocAPI service (SQL_UserDocAPI). No SQL procedure callers in repository. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

SET NOCOUNT ON. NOLOCK on all tables. GROUP BY includes `dar.TypeID` (not in SELECT) - rows may be multiplied per authentication type when @includeAuthResults=1 and a document has reasons of multiple TypeIDs (POI, POA, Selfie). STRING_AGG requires SQL Server 2017+.

---

## 8. Sample Queries

### 8.1 Get all documents for a customer (no auth reasons - default)
```sql
EXEC BackOffice.GetAllUserDocuments @gcid = 987654321;
```

### 8.2 Get documents with authentication reasons included
```sql
EXEC BackOffice.GetAllUserDocuments
    @gcid = 987654321,
    @includeAuthResults = 1;
```

### 8.3 Get documents added since a specific date (for incremental sync)
```sql
EXEC BackOffice.GetAllUserDocuments
    @gcid = 987654321,
    @minDateAdded = '2025-01-01',
    @includeAuthResults = 0;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Doc Api DB Migration Mapping](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/1782906896) | Confluence | GetAllUserDocuments is the core DocAPI document-listing procedure; part of DocAPI migration mapping documentation. |
| COMOP-391/468 | Jira | Added AuthenticationReasons column to BackOffice document section (March 2020, Yulia Kramer). |
| COMOP-732/833 | Jira | Added StorageID IS NOT NULL filter to handle documents without storage reference (April 2020). |
| PROD-79 | Jira | Added DocumentDetails to Au10tix service request - triggered @minDateAdded parameter pattern (January 2020). |
| COMOP-1932/1933 | Jira | DB optimizations on DocApi procedures (December 2020, Yulia Kramer). |
| COMOP-2473/2517 | Jira | Onfido - Classify Selfie Liveliness + POI doc support (April 2021). |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 1 Confluence + 5 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetAllUserDocuments | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetAllUserDocuments.sql*
