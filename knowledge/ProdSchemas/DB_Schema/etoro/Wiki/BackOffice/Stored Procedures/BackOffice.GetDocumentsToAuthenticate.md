# BackOffice.GetDocumentsToAuthenticate

> Returns recently uploaded POI and POI+POA documents from depositing, unverified customers that have not yet been submitted to the Au10tix authentication service - feeds the automated KYC document authentication pipeline.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Multi-step pipeline: linked server queue check + candidate selection + StorageApi file size validation; returns qualifying document rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetDocumentsToAuthenticate is the document feed procedure for eToro's automated Au10tix KYC authentication pipeline. It identifies recently uploaded identity documents that should be submitted to the Au10tix vendor for authenticity analysis - answering the question "which documents need to go to Au10tix right now?".

The procedure applies a strict multi-layered filter: only identity documents (POI and POI+POA combined), only from customers who have deposited at least once (active customers), only from customers not yet fully verified by BackOffice, and only documents not already in the Au10tix submission queue. It also validates document file integrity via the StorageApi linked server, filtering out files that are too small (< 30KB, likely corrupt or empty) or too large (> 20MB, too large for Au10tix processing).

The result is consumed by an automated job (likely `dbo.JOB_Alert_ReportForAu10tix`) that submits the returned document StorageIDs to Au10tix for classification and fraud detection.

Created March 2017 with the initial Au10tix integration (ticket 44285) and enhanced extensively through 2018 to add POA support, performance improvements, and POI+POA combined document handling for US customers.

---

## 2. Business Logic

### 2.1 Already-Authenticated Queue Exclusion

**What**: The procedure first loads the list of documents already submitted to Au10tix, then excludes them from results.

**Columns/Parameters Involved**: `dbo.Authenticate_Documents` synonym, `#Authenticate_Documents`, `DocumentID NOT IN (...)`

**Rules**:
- `dbo.Authenticate_Documents` is a synonym in the etoro database pointing to `[Authenticate].[Authenticate].[dbo].[T_Documents]` on the `Authenticate` linked server - the Au10tix job processing queue
- Loading this into a temp table `#Authenticate_Documents` with a clustered PK (Data_Compression=Page) ensures the NOT IN exclusion is fast even with large queues
- Documents already in this queue must not be re-submitted (prevents duplicate Au10tix charges and processing)

### 2.2 Candidate Document Selection Criteria

**What**: Six simultaneous filters determine which documents are eligible for authentication.

**Columns/Parameters Involved**: `SuggestedDocumentTypeID`, `DateAdded`, `@TimeFrameInHours`, `VerificationLevelID`, `VerifiedBy`, `Billing.Deposit`

**Rules**:
- `SuggestedDocumentTypeID IN (2, 13)`: Only POI (Proof of Identity=2) and POI+POA (combined=13) are sent to Au10tix. Au10tix specializes in identity document verification; POA-only (DocumentTypeID=1) uses different validation.
- `DateAdded >= DATEADD(Hour, -@TimeFrameInHours, GetDate())`: Only recently uploaded documents within the caller's lookback window. Prevents re-processing old documents on every run.
- `CID IN (SELECT CID FROM Billing.Deposit)`: Only depositing customers. Au10tix authentication is only performed for customers who have demonstrated intent to trade by making a deposit. Demo-only customers are excluded.
- `DocumentID NOT IN (#Authenticate_Documents)`: Not already in the Au10tix queue.
- `bc.VerificationLevelID < 3`: Customer must not already be at full verification (level 3). Fully verified customers do not need automated re-authentication.
- `bc.VerifiedBy = 0 OR bc.VerifiedBy IS NULL`: Customer must not have been manually verified by a BackOffice agent. Manual verification takes precedence over automated processing.

### 2.3 StorageApi File Validation

**What**: Before returning results, the procedure validates each document's file metadata from the StorageApi linked server to ensure it is a valid processable file.

**Columns/Parameters Involved**: `FileType`, `FileSize`, `[StorageApi]` linked server

**Rules**:
- Dynamic SQL builds a comma-separated list of StorageIDs and queries `StorageApi.StorageDocuments` on the `[StorageApi]` linked server for FileType and FileSize
- `FileType IS NOT NULL`: The file must exist and be retrievable from storage. NULL FileType means the StorageApi has no record for this document - likely a storage failure.
- `FileSize > 30000` (> ~30KB): Minimum file size threshold. Files smaller than 30KB are likely corrupt, empty, or are placeholder thumbnails unacceptable for Au10tix analysis.
- `FileSize < 20000000` (< 20MB): Maximum file size threshold. Files larger than 20MB exceed the Au10tix processing limit and would be rejected by the vendor.
- Both `FileType` and `FileSize` are initially NULL in the temp table; only populated after StorageApi query. Documents with NULL FileType (file not found in storage) are excluded from results.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeFrameInHours | INT | NO | - | CODE-BACKED | Lookback window in hours. Documents uploaded in the last N hours are candidates for authentication. Typical value: 24 (check last 24 hours of uploads). |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | DocumentID | int | NO | - | CODE-BACKED | The document's unique identifier. From BackOffice.CustomerDocument. |
| R2 | CID | int | NO | - | CODE-BACKED | Customer account ID. From BackOffice.CustomerDocument.CID. |
| R3 | GCID | int | YES | - | CODE-BACKED | Group Customer ID - identifies the person across all regulatory accounts. From Customer.Customer.GCID via CID join. |
| R4 | CountryID | int | YES | - | CODE-BACKED | Customer's registered country. From Customer.Customer.CountryID. Used by Au10tix processing rules that vary by jurisdiction. |
| R5 | FileType | varchar | YES | - | CODE-BACKED | MIME type or file extension of the document file (e.g., 'image/jpeg', 'application/pdf'). From StorageApi.StorageDocuments via linked server query. NULL documents are excluded before return. Tells Au10tix how to decode/process the file. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| #Authenticate_Documents | dbo.Authenticate_Documents (synonym -> [Authenticate].[Authenticate].[dbo].[T_Documents]) | SELECT via linked server | Documents already in the Au10tix authentication queue - used for exclusion |
| cd | BackOffice.CustomerDocument | SELECT | Primary document source; filtered to POI/POI+POA within time window |
| cc | Customer.Customer | INNER JOIN | Provides GCID, CountryID |
| bc | BackOffice.Customer | INNER JOIN | Provides VerificationLevelID, VerifiedBy for eligibility check |
| d | Billing.Deposit | EXISTS subquery | Confirms customer has made at least one deposit |
| sd | StorageApi.StorageDocuments via [StorageApi] linked server | Dynamic EXEC AT | Provides FileType and FileSize for file validity validation |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Consumed by the Au10tix authentication job(s) (likely `dbo.JOB_Alert_ReportForAu10tix`) on a scheduled basis to feed documents to the Au10tix vendor API.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetDocumentsToAuthenticate (procedure)
├── dbo.Authenticate_Documents (synonym -> [Authenticate] linked server)
├── BackOffice.CustomerDocument (table)
├── Customer.Customer (table - cross-schema)
├── BackOffice.Customer (table)
├── Billing.Deposit (table - cross-schema, EXISTS check)
└── [StorageApi] linked server (StorageApi.StorageDocuments - dynamic SQL via EXEC...AT)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Authenticate_Documents | Synonym (-> [Authenticate] linked server) | SELECT DocumentId - loaded into #Authenticate_Documents for NOT IN exclusion |
| BackOffice.CustomerDocument | Table | Primary candidate source; filtered by SuggestedDocumentTypeID, DateAdded, DocumentID exclusion |
| Customer.Customer | Table | INNER JOIN on CID to get GCID and CountryID |
| BackOffice.Customer | Table | INNER JOIN on CID to get VerificationLevelID and VerifiedBy |
| Billing.Deposit | Table | EXISTS subquery - confirms customer has made at least one deposit |
| [StorageApi] linked server | External linked server | Dynamic SQL `EXEC(@S) AT [StorageApi]` to query StorageApi.StorageDocuments for FileType and FileSize |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.JOB_Alert_ReportForAu10tix | Stored Procedure | CALLER - scheduled job that submits returned documents to Au10tix |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Temp tables created internally:
- `#Authenticate_Documents`: Clustered PK on DocumentId with Data_Compression=Page (efficient large-set exclusion)
- `#GetDocumentsToAuthenticate`: Temporary result set with NULL FileType/FileSize until StorageApi enrichment
- `#StorageDocuments`: Unique Clustered Index on StorageID for efficient JOIN after StorageApi query

### 7.2 Constraints

N/A for Stored Procedure. Notable design points:
- Dynamic SQL is used to build the StorageApi query because linked server queries with `IN (list)` require the list to be embedded as string
- The procedure uses `EXEC(@S) AT [StorageApi]` - a distributed query pattern requiring the [StorageApi] linked server to be configured on the SQL Server instance
- The `Authenticate_Documents` synonym (dbo schema) resolves to `[Authenticate].[Authenticate].[dbo].[T_Documents]` - requires the `Authenticate` linked server to be available

---

## 8. Sample Queries

### 8.1 Get documents uploaded in the last 24 hours that need authentication
```sql
EXEC BackOffice.GetDocumentsToAuthenticate @TimeFrameInHours = 24
-- Returns: DocumentID, CID, GCID, CountryID, FileType for eligible documents
-- Filters: POI/POI+POA only, depositors only, unverified, not in Au10tix queue,
--          FileSize 30KB-20MB
```

### 8.2 Wider lookback window (e.g., re-process 7 days)
```sql
EXEC BackOffice.GetDocumentsToAuthenticate @TimeFrameInHours = 168  -- 7 days
```

### 8.3 Ad-hoc: check candidate documents (without StorageApi or linked server calls)
```sql
SELECT
    cd.DocumentID, cd.CID, cc.GCID, cc.CountryID, cd.StorageID,
    bc.VerificationLevelID, bc.VerifiedBy
FROM BackOffice.CustomerDocument cd WITH (NOLOCK)
JOIN Customer.Customer cc WITH (NOLOCK) ON cc.CID = cd.CID
JOIN BackOffice.Customer bc WITH (NOLOCK) ON bc.CID = cd.CID
WHERE cd.SuggestedDocumentTypeID IN (2, 13)
  AND cd.DateAdded >= DATEADD(Hour, -24, GETDATE())
  AND cd.CID IN (SELECT CID FROM Billing.Deposit WITH (NOLOCK))
  AND bc.VerificationLevelID < 3
  AND (bc.VerifiedBy = 0 OR bc.VerifiedBy IS NULL)
ORDER BY cd.DateAdded DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Change history from DDL comments: ticket 44285 (Create link server to AuthenticDB, Mar 2017), ticket 46667 (add new fields to au10tix document and collect also ID, Jun 2017), ticket 47075 (au10tix fixes, Jul 2017), ticket 49634 (Improve performance, Nov 2017), ticket 50270 (get documents to authenticate, Jan 2018), ticket 50449 (Au10tix poa, Feb 2018), RD-1685/1742 (US document with POI+POA need to be send twice to AU10TIX, Dec 2018).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller found | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetDocumentsToAuthenticate | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetDocumentsToAuthenticate.sql*
