# BackOffice.GetPoaDocumentsToAuthenticate_JUNKYulia0325

> JUNK - Returns POI/POA documents added after a cutoff date for submission to the Au10tix automated document authentication service. No longer in use; marked for removal March 2025 (Yulia).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @AddedLaterThan |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure was used to retrieve unprocessed KYC documents for submission to **Au10tix** - eToro's third-party automated document authentication service that performs OCR and validation of identity documents (passports, national IDs, driver's licenses). It queried recently-added POI (Proof of Identity) documents with SuggestedDocumentTypeID IN (1, 13) and returned the document file extension alongside customer/GCID context for the authentication job.

**Status: JUNK** - Marked for decommissioning March 2025 (Yulia). The Au10tix integration has been replaced or the document pipeline was refactored.

**Change history**:
- 2018-01-24 Geri Reshef (50270): Initial "get documents to authenticate"
- 2018-02-14 Geri Reshef (50449): Au10tix POA support
- 2018-12-04 Geri Reshef (RD-1685, 1742): "US document with POI+POA need to be sent twice to AU10TIX" - special handling for combined POI+POA documents from US customers requiring dual submission

**Permission**: No active EXECUTE grants found.

---

## 2. Business Logic

### 2.1 Document Queue for Au10tix Authentication

**What**: Returns documents eligible for automated authentication that were added after the cutoff date.

**Columns/Parameters Involved**: @AddedLaterThan, cd.DateAdded, cd.SuggestedDocumentTypeID

**Rules**:
- `DateAdded >= @AddedLaterThan`: Incremental polling pattern - callers pass the last processed date to get only new documents.
- `SuggestedDocumentTypeID IN (1, 13)`: Filters to:
  - Type 1 = POI (Proof of Identity - passport, national ID, driver's license)
  - Type 13 = Combined POI+POA document (passport with address pages, or similar dual-purpose documents; relevant to the RD-1685 US document handling)
- No status filter - any document of these types added after the cutoff is returned, regardless of authentication state.

### 2.2 File Extension Extraction

**What**: Extracts the file format from the document filename.

**Columns/Parameters Involved**: cd.FileName

**Rules**:
- `Reverse(Left(Reverse(FileName), CharIndex('.', Reverse(FileName)) - 1))`: Three-step pattern:
  1. `Reverse(FileName)` - reverses the filename string
  2. `CharIndex('.', ...)` - finds the position of the first '.' from the right (= last '.' in original)
  3. `Left(..., pos - 1)` - takes everything before the last '.'
  4. Outer `Reverse(...)` - reverses back to get the extension
- Example: "passport_scan.JPG" -> "JPG"
- Au10tix required the file type to route to the appropriate OCR processing pipeline.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AddedLaterThan | DATETIME | NO | - | CODE-BACKED | Cutoff date for incremental processing. Returns documents added to BackOffice.CustomerDocument on or after this date. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocumentID | INT | NO | - | CODE-BACKED | Primary key of the document record (BackOffice.CustomerDocument.DocumentID). Used as the handle for Au10tix submission tracking. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer account ID who uploaded this document. |
| 3 | GCID | INT | YES | - | CODE-BACKED | Global Customer ID from Customer.Customer. Used for cross-system identification in the Au10tix integration. |
| 4 | CountryID | INT | YES | - | CODE-BACKED | Customer's registered country from Customer.Customer. Used for country-specific processing rules (e.g., US documents requiring dual submission per RD-1685). |
| 5 | FileType | NVARCHAR | YES | - | CODE-BACKED | File extension extracted from the document FileName (e.g., 'JPG', 'PDF', 'PNG'). Used by Au10tix to determine document processing pipeline. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Document data | BackOffice.CustomerDocument | Read (FROM) | Document records filtered by DateAdded and SuggestedDocumentTypeID |
| GCID, CountryID | Customer.Customer | Read (INNER JOIN) | Customer profile for GCID and country |
| SuggestedDocumentTypeID | Dictionary.DocumentType | Implicit | Type 1=POI, Type 13=Combined POI+POA |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No active EXECUTE grants found. JUNK - no active callers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetPoaDocumentsToAuthenticate_JUNKYulia0325 (procedure - JUNK)
+-- BackOffice.CustomerDocument (table)
+-- Customer.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocument | Table | Document records; filtered by DateAdded and SuggestedDocumentTypeID |
| Customer.Customer | Table | INNER JOIN for GCID and CountryID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none) | - | JUNK - no active callers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SuggestedDocumentTypeID IN (1,13) | Business filter | POI and combined POI+POA documents only |
| No authentication status filter | Design | Returns all eligible documents regardless of processing state |
| File extension extraction | String manipulation | Reverse/CharIndex pattern; assumes filenames always contain at least one dot |

---

## 8. Sample Queries

### 8.1 Execute for documents added in the last 24 hours

```sql
EXEC BackOffice.GetPoaDocumentsToAuthenticate_JUNKYulia0325
    @AddedLaterThan = DATEADD(DAY, -1, GETDATE())
```

### 8.2 Check SuggestedDocumentTypeID meanings

```sql
SELECT DocumentTypeID, Name
FROM Dictionary.DocumentType WITH (NOLOCK)
WHERE DocumentTypeID IN (1, 13);
-- 1 = POI (Proof of Identity)
-- 13 = (likely Combined POI+POA or specific ID type)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 active callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetPoaDocumentsToAuthenticate_JUNKYulia0325 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetPoaDocumentsToAuthenticate_JUNKYulia0325.sql*
