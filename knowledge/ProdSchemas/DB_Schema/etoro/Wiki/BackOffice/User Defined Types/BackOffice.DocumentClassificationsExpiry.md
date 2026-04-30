# BackOffice.DocumentClassificationsExpiry

> Table-valued parameter type for passing a batch of document classification ID and expiry date pairs to bulk-update expiry dates on existing classification records.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | User Defined Type |
| **Key Identifier** | DocumentClassificationId (NOT NULL - row key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.DocumentClassificationsExpiry` is a Table-Valued Type (TVT) that defines the minimal schema contract for bulk-updating expiry dates on existing document classification records. Each row pairs a `DocumentClassificationId` (the PK of `BackOffice.CustomerDocumentToDocumentType`) with a new `ExpiryDate`, allowing a caller to update multiple classifications' expiry dates in a single database round-trip.

This type exists to support scenarios where document expiry dates need to be extended or corrected in batch - for example, when a compliance officer updates the validity of multiple documents at once, or when a document API processes a batch of expiry corrections. Without this TVT, each expiry update would require a separate UPDATE call.

Data flows into this type from the DocAPI or compliance tooling. The caller builds the list of (ID, ExpiryDate) pairs and passes it READONLY to `BackOffice.UpdateDocumentClassificationsExpiryDate`, which applies a simple UPDATE JOIN to `BackOffice.CustomerDocumentToDocumentType`. The procedure enforces a batch size limit of 2,000 records to prevent temp DB pressure.

---

## 2. Business Logic

### 2.1 Batch Expiry Date Correction

**What**: A compact two-column transport for patching expiry dates on existing classification records without disturbing any other classification metadata.

**Columns/Parameters Involved**: `DocumentClassificationId`, `ExpiryDate`

**Rules**:
- `DocumentClassificationId` maps to `CustomerDocumentToDocumentType.DocumentToDocumentTypeID` (the row's identity PK).
- `ExpiryDate` is NOT NULL in the type - every row must provide a new date; the procedure does not support setting expiry to NULL via this path.
- Maximum 2,000 rows per call (enforced in consuming SP): `IF (SELECT COUNT(1) FROM @input) > 2000 RAISERROR(...)`.
- No transaction wrapping - updates are applied as a single batch UPDATE JOIN.

**Diagram**:
```
Caller provides @expiryUpdates AS BackOffice.DocumentClassificationsExpiry:
  [(DocClassId=101, ExpiryDate='2030-01-01'),
   (DocClassId=102, ExpiryDate='2028-06-15'), ...]
         |
         v
BackOffice.UpdateDocumentClassificationsExpiryDate
         |
         v
UPDATE BackOffice.CustomerDocumentToDocumentType
SET ExpiryDate = d.ExpiryDate
FROM @expiryUpdates d
JOIN ... ON DocumentToDocumentTypeID = d.DocumentClassificationId
```

---

## 3. Data Overview

N/A for User Defined Type. This is a transient parameter container, not a persistent table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocumentClassificationId | int | NO | - | CODE-BACKED | Primary key of the target row in BackOffice.CustomerDocumentToDocumentType (column DocumentToDocumentTypeID). NOT NULL - every row must identify an existing classification record to update. |
| 2 | ExpiryDate | datetime | NO | - | CODE-BACKED | The new expiry date to set on the identified classification record. NOT NULL - this type is exclusively used for date update operations. The consuming SP applies: SET ExpiryDate = d.ExpiryDate FROM @input d JOIN CustomerDocumentToDocumentType ON DocumentToDocumentTypeID = d.DocumentClassificationId. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DocumentClassificationId | BackOffice.CustomerDocumentToDocumentType.DocumentToDocumentTypeID | Implicit | Row key identifying which classification record's expiry date to update |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.UpdateDocumentClassificationsExpiryDate | @documentClassificationsExpiry parameter | Schema contract | Batch-updates ExpiryDate on CustomerDocumentToDocumentType rows identified by DocumentClassificationId |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.UpdateDocumentClassificationsExpiryDate | Stored Procedure | READONLY parameter - JOINs to CustomerDocumentToDocumentType and applies ExpiryDate updates for each row (max 2,000 rows per call) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DocumentClassificationId NOT NULL | Column constraint | Row key must always be provided - no anonymous expiry updates |
| ExpiryDate NOT NULL | Column constraint | A new expiry date must always be specified - NULL clearing not supported via this path |

---

## 8. Sample Queries

### 8.1 Update expiry dates for a batch of classifications

```sql
DECLARE @expiryUpdates BackOffice.DocumentClassificationsExpiry;

INSERT INTO @expiryUpdates (DocumentClassificationId, ExpiryDate)
VALUES (1001, '2030-12-31'),
       (1002, '2029-06-15'),
       (1003, '2031-01-01');

EXEC BackOffice.UpdateDocumentClassificationsExpiryDate
    @documentClassificationsExpiry = @expiryUpdates;
```

### 8.2 Verify expiry dates before sending to the procedure

```sql
DECLARE @expiryUpdates BackOffice.DocumentClassificationsExpiry;

INSERT INTO @expiryUpdates (DocumentClassificationId, ExpiryDate)
SELECT cdd.DocumentToDocumentTypeID, DATEADD(YEAR, 5, cdd.ExpiryDate)
FROM BackOffice.CustomerDocumentToDocumentType cdd WITH (NOLOCK)
WHERE cdd.ExpiryDate IS NOT NULL
  AND cdd.ExpiryDate < GETDATE()
  AND cdd.DocumentTypeID = 2; -- POI documents only

SELECT u.DocumentClassificationId, u.ExpiryDate,
       cdd.ExpiryDate AS CurrentExpiryDate
FROM @expiryUpdates u
JOIN BackOffice.CustomerDocumentToDocumentType cdd WITH (NOLOCK)
    ON cdd.DocumentToDocumentTypeID = u.DocumentClassificationId;
```

### 8.3 Check classification records that would be updated

```sql
-- Inspect before running the batch
DECLARE @batch BackOffice.DocumentClassificationsExpiry;

INSERT INTO @batch VALUES (5001, '2032-03-01'), (5002, '2032-03-01');

SELECT b.DocumentClassificationId,
       b.ExpiryDate AS NewExpiry,
       cdd.ExpiryDate AS CurrentExpiry,
       cdd.DocumentTypeID,
       cdd.DocumentID
FROM @batch b
JOIN BackOffice.CustomerDocumentToDocumentType cdd WITH (NOLOCK)
    ON cdd.DocumentToDocumentTypeID = b.DocumentClassificationId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.DocumentClassificationsExpiry | Type: User Defined Type | Source: etoro/etoro/BackOffice/User Defined Types/BackOffice.DocumentClassificationsExpiry.sql*
