# BackOffice.GetExtraInfoOnFixFiles

> Batch lookup that returns customer identity and document metadata for a set of document IDs - used by data fix and maintenance operations that need customer context (GCID, CID) alongside document details for a list of DocumentIDs.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | TVP @listDocIds (BackOffice.IDs) batch lookup; returns one row per DocumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetExtraInfoOnFixFiles is a batch document metadata retrieval procedure designed for data fix and maintenance scripts. Given a list of DocumentIDs (via the BackOffice.IDs TVP), it returns the customer identity context and document metadata needed to process each document in a correction operation: who uploaded it (CID, GCID), when it was uploaded (DateAdded), what the AI suggested its type was (SuggestedDocumentTypeID), what session it was uploaded in (SessionID), and the stored filename.

The name "ExtraInfoOnFixFiles" indicates this procedure was created for operational "fix" workflows - situations where a batch of document IDs has been identified for correction and the fix script needs customer and document metadata to proceed. The BackOffice.IDs TVP allows passing large lists efficiently via a set-based operation.

Note: The DDL comment says `@listDocIds` is "list of classifications" but the actual JOIN is on `cd.DocumentID` (not DocumentToDocumentTypeID) - the comment is incorrect; the parameter contains DocumentIDs.

---

## 2. Business Logic

### 2.1 Batch Document-to-Customer Resolution

**What**: Joins a batch of DocumentIDs to CustomerDocument and CustomerStatic to retrieve the minimal set of fields needed for fix/correction processing.

**Columns/Parameters Involved**: `@listDocIds`, `cd.DocumentID`, `cc.GCID`, `cc.CID`

**Rules**:
- INNER JOIN to `BackOffice.CustomerDocument` on `ldi.ID = cd.DocumentID` - only DocumentIDs that exist in CustomerDocument are returned. Missing DocumentIDs are silently excluded.
- INNER JOIN to `Customer.CustomerStatic` on `cd.CID = cc.CID` - requires the document's customer to have a CustomerStatic record. CustomerStatic is the lightweight static customer info table (CID, GCID, and other relatively stable attributes).
- No filtering beyond the TVP contents - all matching DocumentIDs are returned.
- Returns one row per DocumentID in the TVP that has a matching CustomerDocument and CustomerStatic record.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @listDocIds | BackOffice.IDs READONLY | NO | - | CODE-BACKED | Table-valued parameter containing the DocumentIDs to look up. Each row provides a DocumentID via the IDs UDT's single INT column (ID). Note: DDL comment says "list of classifications" but the join is on DocumentID - the comment is incorrect. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | DocumentID | int | NO | - | CODE-BACKED | The document's unique identifier. From BackOffice.CustomerDocument via the TVP join. |
| R2 | DateAdded | datetime | NO | - | CODE-BACKED | When the document was uploaded. From BackOffice.CustomerDocument.DateAdded. |
| R3 | SuggestedDocumentTypeID | int | YES | - | CODE-BACKED | AI-suggested document type (Au10tix/Onfido classification suggestion). FK to Dictionary.DocumentType. Not the final classification (that is in CustomerDocumentToDocumentType). From BackOffice.CustomerDocument. |
| R4 | SessionID | int | YES | - | CODE-BACKED | Session ID associated with the upload event. From BackOffice.CustomerDocument.SessionID. Useful for correlating with other session-based data. |
| R5 | GCID | int | YES | - | CODE-BACKED | Group Customer ID - identifies the person across all regulatory accounts. From Customer.CustomerStatic.GCID. |
| R6 | CID | int | NO | - | CODE-BACKED | Customer account ID. From Customer.CustomerStatic.CID (matches BackOffice.CustomerDocument.CID). |
| R7 | FileName | nvarchar | YES | - | CODE-BACKED | The stored filename of the document. From BackOffice.CustomerDocument.FileName. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| cd | BackOffice.CustomerDocument | INNER JOIN | Document metadata source; matched on ldi.ID = DocumentID |
| cc | Customer.CustomerStatic | INNER JOIN | Customer identity; matched on CID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Used by BackOffice data fix scripts and maintenance operations that process document batches.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetExtraInfoOnFixFiles (procedure)
├── BackOffice.CustomerDocument (table)
└── Customer.CustomerStatic (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocument | Table | INNER JOIN on DocumentID to get DateAdded, SuggestedDocumentTypeID, SessionID, FileName |
| Customer.CustomerStatic | Table | INNER JOIN on CID to get GCID and CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice data fix scripts | External | READER - retrieves customer and document context for batch fix operations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Both BackOffice.CustomerDocument and Customer.CustomerStatic have clustered PKs on their respective ID columns (DocumentID and CID), making this an efficient batch point-lookup.

### 7.2 Constraints

N/A for Stored Procedure. No NOLOCK hints are used - this may cause read blocking in high-write environments. No SET NOCOUNT ON.

---

## 8. Sample Queries

### 8.1 Get document info for a batch of DocumentIDs
```sql
DECLARE @docs BackOffice.IDs;
INSERT INTO @docs (ID) VALUES (12345), (67890), (11111);
EXEC BackOffice.GetExtraInfoOnFixFiles @listDocIds = @docs
-- Returns: DocumentID, DateAdded, SuggestedDocumentTypeID, SessionID, GCID, CID, FileName
-- One row per DocumentID that exists in CustomerDocument
```

### 8.2 Ad-hoc equivalent for a small set
```sql
SELECT cd.DocumentID, cd.DateAdded, cd.SuggestedDocumentTypeID, cd.SessionID,
       cc.GCID, cc.CID, cd.FileName
FROM BackOffice.CustomerDocument cd WITH (NOLOCK)
JOIN Customer.CustomerStatic cc WITH (NOLOCK) ON cc.CID = cd.CID
WHERE cd.DocumentID IN (12345, 67890, 11111)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetExtraInfoOnFixFiles | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetExtraInfoOnFixFiles.sql*
