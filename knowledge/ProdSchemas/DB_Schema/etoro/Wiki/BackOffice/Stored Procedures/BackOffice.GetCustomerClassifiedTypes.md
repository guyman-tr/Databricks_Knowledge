# BackOffice.GetCustomerClassifiedTypes

> Returns the active/valid document type classifications per customer for a batch of GCIDs, used by the UAPI risk-info endpoint to determine which document categories a customer currently holds.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcids (TVP of GCIDs) - batch input; one row per customer with comma-separated DocumentTypeIDs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure answers the question: "For each of these customers, which document types do they currently have active/non-expired classifications for?"

It is the data source for the `RiskInfo` endpoint in the UAPI (Unified API) layer, created April 2024 to expose document classification state to downstream services without requiring them to query the BO document tables directly.

The result is deliberately compact: one row per customer, with all valid DocumentTypeIDs concatenated into a comma-separated string. This lets the API caller determine whether a customer holds a POI (Proof of Identity), POA (Proof of Address), or other document categories without joining multiple tables.

Document validity is evaluated by a three-branch rule that handles both explicit expiry dates and age-based validity windows (see section 2.2).

DocumentTypeID=6 is always excluded from results (see section 2.3).

---

## 2. Business Logic

### 2.1 Batch GCID Input

**What**: The procedure accepts a batch of GCIDs (Global Customer IDs) rather than a single customer ID.

**Columns/Parameters Involved**: `@gcids BackOffice.IDs READONLY`, `BackOffice.CustomerDocument.GCID`

**Rules**:
- `JOIN BackOffice.CustomerDocument cd ON cd.GCID = gcids.ID` - drives the JOIN from the TVP
- Returns one row per (CID, GCID) pair with valid documents; customers with no valid documents produce no row
- Commented-out code shows an earlier design that would resolve GCIDs to CIDs via Customer.CustomerStatic with a temp table index - this was simplified to direct JOIN on GCID

### 2.2 Document Validity Three-Branch Rule

**What**: A document classification is included only if it passes at least one of three validity conditions.

**Columns/Parameters Involved**: `cdd.ExpiryDate`, `cdd.IssueDate`, `dt.MaxAgeInMonths`

**Validity logic**:
```
( cdd.ExpiryDate > GETUTCDATE() )
OR ( cdd.ExpiryDate IS NULL AND dt.MaxAgeInMonths IS NULL )
OR ( cdd.ExpiryDate IS NULL AND DATEDIFF(MONTH, cdd.IssueDate, GETUTCDATE()) <= dt.MaxAgeInMonths )
```

| Branch | Condition | Meaning |
|--------|-----------|---------|
| 1 | ExpiryDate > GETUTCDATE() | Document has an explicit expiry set and it is in the future - valid |
| 2 | ExpiryDate IS NULL AND MaxAgeInMonths IS NULL | Document has no expiry and the type has no age limit - valid indefinitely |
| 3 | ExpiryDate IS NULL AND age in months <= MaxAgeInMonths | No explicit expiry but the document type has a maximum age in months; valid if issued within that window |

Documents where ExpiryDate IS NOT NULL but ExpiryDate <= GETUTCDATE() (expired) or where ExpiryDate IS NULL but the document is older than MaxAgeInMonths are excluded.

### 2.3 DocumentTypeID = 6 Exclusion

**What**: A specific document type ID is always filtered out.

**Rules**:
- `AND cdd.DocumentTypeID <> 6` in the CTE JOIN condition
- DocumentTypeID=6 is excluded from all results regardless of validity
- This type is likely an internal/administrative document category not relevant to external risk classification

### 2.4 DISTINCT on CTE + String_agg Aggregation

**What**: The CTE uses DISTINCT to deduplicate per (CID, GCID, DocumentTypeID) before aggregating.

**Rules**:
- `SELECT DISTINCT cd.CID, cd.GCID, cdd.DocumentTypeID` prevents duplicate type IDs in the string
- `String_agg(DocumentTypeID, ',')` concatenates all unique valid DocumentTypeIDs per customer into a CSV string (e.g., "1,2,4")
- The order of IDs in the string is not guaranteed (no WITHIN GROUP ORDER BY)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @gcids | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Table-valued parameter of Global Customer IDs (GCIDs) to evaluate. Each ID is matched against BackOffice.CustomerDocument.GCID. Customers not in the TVP or with no valid documents produce no output row. |
| **Output Columns** | | | | | | |
| 2 | CID | INT | YES | - | CODE-BACKED | Customer ID. From BackOffice.CustomerDocument.CID. The integer-based customer identifier. |
| 3 | GCID | INT | YES | - | CODE-BACKED | Global Customer ID. From BackOffice.CustomerDocument.GCID. The cross-platform identifier provided as input. |
| 4 | DocumentTypes | NVARCHAR | YES | - | CODE-BACKED | Comma-separated list of active DocumentTypeIDs for this customer. Built by String_agg(DocumentTypeID, ','). Excludes DocumentTypeID=6 and expired/aged-out documents. NULL if the customer has no qualifying documents (though such customers would produce no row). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID | BackOffice.CustomerDocument | Primary Source | Customer document records; filtered by GCID from input TVP |
| DocumentID | BackOffice.CustomerDocumentToDocumentType | Lookup / JOIN | Maps document IDs to document type IDs with expiry and issue date |
| DocumentTypeID | Dictionary.DocumentType | Lookup / JOIN | Provides MaxAgeInMonths for age-based validity check |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| UAPI (Unified API) | RiskInfo endpoint | Application call | Called to populate document classification data for the risk-info API response. Created specifically for this purpose (April 2024). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerClassifiedTypes (procedure)
|- BackOffice.CustomerDocument (customer document records)
|- BackOffice.CustomerDocumentToDocumentType (document-to-type mapping with validity dates)
+-- Dictionary.DocumentType (type metadata: MaxAgeInMonths)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocument | Table | Primary source - customer documents filtered by GCID from input TVP |
| BackOffice.CustomerDocumentToDocumentType | Table | JOINed to get DocumentTypeID, ExpiryDate, IssueDate for each document |
| Dictionary.DocumentType | Table | JOINed to get MaxAgeInMonths for age-based validity branch |
| BackOffice.IDs | User Defined Type | TVP type for @gcids parameter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| UAPI RiskInfo endpoint | External API | Reads document classifications for risk assessment |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `SET NOCOUNT ON`: Suppresses row-count messages to avoid interfering with API result consumption.
- `WITH(NOLOCK)` on all tables: Accepts potentially stale reads; appropriate for a read-only classification query.

---

## 8. Sample Queries

### 8.1 Get document classifications for a batch of customers

```sql
DECLARE @gcids BackOffice.IDs;
INSERT @gcids VALUES (1001), (1002), (1003);

EXEC BackOffice.GetCustomerClassifiedTypes @gcids = @gcids;
-- Returns: CID | GCID | DocumentTypes (e.g., "1,2" or "1")
```

### 8.2 Direct validity check for one customer's documents

```sql
DECLARE @gcid INT = 1001;

SELECT DISTINCT cd.CID, cd.GCID, cdd.DocumentTypeID,
    cdd.ExpiryDate, cdd.IssueDate, dt.MaxAgeInMonths
FROM BackOffice.CustomerDocument cd WITH(NOLOCK)
JOIN BackOffice.CustomerDocumentToDocumentType cdd WITH(NOLOCK) ON cd.DocumentID = cdd.DocumentID
    AND cdd.DocumentTypeID <> 6
JOIN Dictionary.DocumentType dt WITH(NOLOCK) ON cdd.DocumentTypeID = dt.DocumentTypeID
WHERE cd.GCID = @gcid
    AND (
        cdd.ExpiryDate > GETUTCDATE()
        OR (cdd.ExpiryDate IS NULL AND dt.MaxAgeInMonths IS NULL)
        OR (cdd.ExpiryDate IS NULL AND DATEDIFF(MONTH, cdd.IssueDate, GETUTCDATE()) <= dt.MaxAgeInMonths)
    );
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira records found. The procedure comment states it was created to "Support RiskInfo in UAPI" by Pola Gershon, April 2024.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerClassifiedTypes | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerClassifiedTypes.sql*
