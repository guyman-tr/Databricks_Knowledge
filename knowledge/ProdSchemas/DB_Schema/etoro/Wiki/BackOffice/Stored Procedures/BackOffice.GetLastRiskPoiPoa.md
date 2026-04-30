# BackOffice.GetLastRiskPoiPoa

> Returns the latest POI (Proof of Identity) and POA (Proof of Address) document status for a batch of customers identified by GCID, including expiry flags, for use by the User Document API (UAPI).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcids - table-valued parameter of GCIDs to query |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the most recent POI (Proof of Identity, DocumentTypeID=1) and POA (Proof of Address, DocumentTypeID=2) document record for each customer in a provided batch of GCIDs. It answers: "Does each customer in this set have a valid, non-expired POI and/or POA on file?" - which is the core identity verification check needed for risk and compliance workflows.

The procedure was created in April 2024 to support the RiskInfo endpoint in the User API (UAPI). It enables the UAPI to batch-retrieve document verification status for multiple customers in a single call rather than querying per customer, which is critical for performance in bulk risk assessment scenarios.

Data flows from `BackOffice.CustomerDocument` (the master document registry) joined to `BackOffice.CustomerDocumentToDocumentType` (the document type classification, potentially with expiry dates), and `Dictionary.DocumentType` (which provides the `MaxAgeInMonths` limit for expiry-by-age calculations). The procedure uses `WITH RECOMPILE` to handle the variable cardinality of the TVP input, preventing query plan caching issues with large vs. small input sets.

---

## 2. Business Logic

### 2.1 POI and POA Document Type Filtering

**What**: The procedure returns exactly two rows per customer (at most) - one for POI and one for POA - identified by hardcoded DocumentTypeID values.

**Columns/Parameters Involved**: `DocumentTypeID`, `SuggestedDocumentTypeID`, `DocKindID`

**Rules**:
- DocumentTypeID = 1 = POI (Proof of Identity). First UNION branch handles this type.
- DocumentTypeID = 2 = POA (Proof of Address). Second UNION branch handles this type.
- DocumentTypeID = 6 = Rejected. Explicitly excluded: `IsNull(cdd.DocumentTypeID,1)<>6` prevents rejected documents from appearing.
- If `cdd.DocumentTypeID` is NULL (the document has not yet been classified via `CustomerDocumentToDocumentType`), the filter falls back to `SuggestedDocumentTypeID` from `BackOffice.CustomerDocument`. This ensures unreviewed-but-suggested documents are still captured.
- `DocKindID` mirrors `DocumentTypeID` (1 for POI, 2 for POA) - an alias column that the calling API uses.

### 2.2 Document Expiry Calculation

**What**: The `Expired` flag determines whether the most recent document of each type is still valid, based on two complementary expiry rules.

**Columns/Parameters Involved**: `Expired`, `cdd.ExpiryDate`, `cdd.IssueDate`, `dt.MaxAgeInMonths`

**Rules**:
- Rule 1 - Explicit Expiry Date: If `max(cdd.ExpiryDate) < GetUtcDate()`, the document is expired (Expired = 1).
- Rule 2 - Age-Based Expiry: If `ExpiryDate IS NULL` AND the document's issue date is more than `MaxAgeInMonths` months ago (per `Dictionary.DocumentType.MaxAgeInMonths`), the document is expired (Expired = 1).
- If neither rule applies (document is not expired), `Expired` returns NULL (not 0 - caller must treat NULL as "not expired").
- The `MAX()` aggregate on ExpiryDate and IssueDate means that when a customer has multiple documents of the same type, only the most recently-uploaded document's expiry is evaluated.
- Only one row per GCID+DocumentTypeID is returned due to the GROUP BY clause.

**Diagram**:
```
For each GCID + DocumentTypeID (1=POI, 2=POA):

  MAX(DocumentID) -> most recent document
  MAX(ExpiryDate) < NOW  --------> Expired = 1
  OR
  ExpiryDate IS NULL AND
  DateDiff(Month, MAX(IssueDate), NOW) > MaxAgeInMonths -> Expired = 1

  Otherwise -> Expired = NULL (not expired)

  DocumentTypeID = 6 (Rejected) -> EXCLUDED
```

### 2.3 Batch Input via Table-Valued Parameter

**What**: The procedure accepts a TVP (`BackOffice.IDs`) instead of a single GCID, enabling efficient batch retrieval for bulk API calls.

**Columns/Parameters Involved**: `@gcids`, `BackOffice.IDs`

**Rules**:
- `BackOffice.IDs` is a user-defined table type with a single `ID` column (likely UNIQUEIDENTIFIER or BIGINT matching GCID).
- The `WITH RECOMPILE` option prevents an unstable query plan from being cached, since the cardinality of the TVP can vary widely between calls.
- The commented-out alternative approach (creating `#cids` temp table and joining via `Customer.CustomerStatic`) would have enabled CID-based filtering, but the final implementation uses GCID directly for simpler cross-schema access.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcids | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Input parameter. Table-valued parameter containing the set of GCIDs (Global Customer IDs) to query. Each row in the TVP has an `ID` column with one GCID. Accepts multiple GCIDs in a single call for batch processing. |

**Output Columns** (one row per GCID per DocumentType, up to 2 rows per customer):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | YES | - | CODE-BACKED | Internal customer identifier. From `BackOffice.CustomerDocument.CID`. |
| 2 | GCID | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Global customer identifier. From `BackOffice.CustomerDocument.GCID`. Matches the input TVP `ID` values. |
| 3 | DocumentID | INT | YES | - | CODE-BACKED | The ID of the most recently uploaded document of this type (MAX over the group). References `BackOffice.CustomerDocument.DocumentID`. |
| 4 | DocumentTypeID | INT | NO | - | CODE-BACKED | Hardcoded document type: 1 = POI (Proof of Identity), 2 = POA (Proof of Address). Identifies which verification type this row represents. |
| 5 | DocKindID | INT | NO | - | CODE-BACKED | Same value as DocumentTypeID (1 for POI, 2 for POA). A parallel alias column used by the calling UAPI to distinguish document kinds in its response model. |
| 6 | Expired | BIT | YES | - | CODE-BACKED | Expiry status: 1 = the latest document of this type is expired (by explicit ExpiryDate or by MaxAgeInMonths rule). NULL = not expired or no expiry data available. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcids.ID | BackOffice.CustomerDocument.GCID | JOIN | Filters documents to only those belonging to the provided GCIDs |
| DocumentID | BackOffice.CustomerDocumentToDocumentType | Lookup (READ) | Joins to get ExpiryDate, IssueDate, and DocumentTypeID classification for each document |
| DocumentTypeID | Dictionary.DocumentType | Lookup | Joins to get MaxAgeInMonths - the maximum allowed document age before it is considered expired |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_UserDocAPI (database user) | EXECUTE permission | Permission | The User Document API service account is granted EXECUTE on this procedure |
| UAPI RiskInfo endpoint | External | Called from | The primary consumer - UAPI's RiskInfo endpoint calls this SP to populate POI/POA verification status in risk responses |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetLastRiskPoiPoa (procedure)
├── BackOffice.IDs (user defined type) [TVP parameter type]
├── BackOffice.CustomerDocument (table)
├── BackOffice.CustomerDocumentToDocumentType (table)
└── Dictionary.DocumentType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.IDs | User Defined Type | TVP parameter type for @gcids; defines the input table schema |
| BackOffice.CustomerDocument | Table | Primary JOIN target; source of CID, GCID, DocumentID, SuggestedDocumentTypeID |
| BackOffice.CustomerDocumentToDocumentType | Table | LEFT JOIN for ExpiryDate, IssueDate, DocumentTypeID classification per document |
| Dictionary.DocumentType | Table | LEFT JOIN for MaxAgeInMonths - used in the age-based expiry check |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| UAPI / User Document API | External | Calls this procedure to retrieve POI/POA status for risk info responses |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Execution hint | Forces query plan recompilation on each call; prevents suboptimal plan caching due to variable TVP cardinality |
| DocumentTypeID = 6 exclusion | Business filter | `IsNull(cdd.DocumentTypeID,1)<>6` and `IsNull(cdd.DocumentTypeID,2)<>6` exclude rejected documents from results |
| SuggestedDocumentTypeID fallback | Business logic | `isnull(cdd.DocumentTypeID, SuggestedDocumentTypeID)` enables unclassified documents to be included if their suggested type matches |

---

## 8. Sample Queries

### 8.1 Get POI and POA status for a single customer by GCID

```sql
DECLARE @gcids BackOffice.IDs;
INSERT INTO @gcids (ID) VALUES ('A1B2C3D4-E5F6-7890-ABCD-EF1234567890');

EXEC BackOffice.GetLastRiskPoiPoa @gcids = @gcids;
```

### 8.2 Get POI and POA status for multiple customers

```sql
DECLARE @gcids BackOffice.IDs;
INSERT INTO @gcids (ID)
SELECT GCID FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE CID IN (12345, 67890, 11111);

EXEC BackOffice.GetLastRiskPoiPoa @gcids = @gcids;
```

### 8.3 Query document expiry directly for a customer

```sql
SELECT cd.CID,
       cd.GCID,
       cd.DocumentID,
       cdd.DocumentTypeID,
       cdd.ExpiryDate,
       cdd.IssueDate,
       dt.MaxAgeInMonths,
       CASE
           WHEN cdd.ExpiryDate < GETUTCDATE() THEN 1
           WHEN cdd.ExpiryDate IS NULL AND DATEDIFF(MONTH, cdd.IssueDate, GETUTCDATE()) > dt.MaxAgeInMonths THEN 1
           ELSE NULL
       END AS Expired
FROM BackOffice.CustomerDocument cd WITH (NOLOCK)
LEFT JOIN BackOffice.CustomerDocumentToDocumentType cdd WITH (NOLOCK)
    ON cdd.DocumentID = cd.DocumentID
LEFT JOIN Dictionary.DocumentType dt WITH (NOLOCK)
    ON cdd.DocumentTypeID = dt.DocumentTypeID
WHERE cd.GCID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890'
  AND ISNULL(cdd.DocumentTypeID, cd.SuggestedDocumentTypeID) IN (1, 2)
  AND ISNULL(cdd.DocumentTypeID, 0) <> 6;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found directly for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 10.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetLastRiskPoiPoa | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetLastRiskPoiPoa.sql*
