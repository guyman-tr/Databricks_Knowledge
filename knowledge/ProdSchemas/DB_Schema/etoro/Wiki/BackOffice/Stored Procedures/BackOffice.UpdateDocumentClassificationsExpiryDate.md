# BackOffice.UpdateDocumentClassificationsExpiryDate

> Batch-updates expiry dates on KYC document classification records using a table-valued parameter, limited to 2000 records per call.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @documentClassificationsExpiry TVP - targets BackOffice.CustomerDocumentToDocumentType by DocumentToDocumentTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UpdateDocumentClassificationsExpiryDate` provides a batch mechanism for updating the `ExpiryDate` on existing KYC document classification records. Document expiry dates may need correction after initial classification - for example, when a passport is classified with a wrong expiry date, or when a W-8BEN form is renewed and the existing record's expiry must be extended. Rather than calling the single-record `UpdateDocumentClassification` in a loop, this SP accepts up to 2000 updates in one call via a TVP.

The procedure exists as a separate dedicated SP (rather than part of the general `UpdateDocumentClassification`) because expiry date corrections are often done in bulk by compliance teams processing batches of documents. The 2000-record cap prevents runaway updates and keeps transaction scope manageable.

ExpiryDate is critical in the KYC compliance flow: `GetExpiredIdentityDocuments` queries on this field, and expired documents trigger re-verification requirements. Accurate expiry dates directly affect customer verification status and ability to trade.

---

## 2. Business Logic

### 2.1 Batch Expiry Date Update with Cap

**What**: Updates ExpiryDate on multiple classification records in a single JOIN-based UPDATE.

**Columns/Parameters Involved**: `@documentClassificationsExpiry.DocumentClassificationId`, `@documentClassificationsExpiry.ExpiryDate`

**Rules**:
- Accepts up to 2000 records per batch (RAISERROR raised if count exceeds 2000; execution stops).
- UPDATE via JOIN: `UPDATE cdd SET ExpiryDate = d.ExpiryDate FROM @documentClassificationsExpiry d JOIN BackOffice.CustomerDocumentToDocumentType cdd ON cdd.DocumentToDocumentTypeID = d.DocumentClassificationId`.
- Records in the TVP not matching any DocumentToDocumentTypeID are silently skipped (no error).
- Only ExpiryDate is modified; all other classification fields remain unchanged.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @documentClassificationsExpiry | BackOffice.DocumentClassificationsExpiry (TVP) | NO | - | CODE-BACKED | READONLY table-valued parameter. Each row contains: `DocumentClassificationId` (maps to BackOffice.CustomerDocumentToDocumentType.DocumentToDocumentTypeID) and `ExpiryDate` (the new expiry date to set). Maximum 2000 rows per call (RAISERROR raised if exceeded). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DocumentClassificationId (from TVP) | [BackOffice.CustomerDocumentToDocumentType](../Tables/BackOffice.CustomerDocumentToDocumentType.md) | UPDATE target | Updates ExpiryDate by DocumentToDocumentTypeID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No direct callers found in BackOffice SPs. | - | - | Called from compliance tooling for bulk document expiry corrections. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UpdateDocumentClassificationsExpiryDate (procedure)
+-- BackOffice.CustomerDocumentToDocumentType (table) [UPDATE target: ExpiryDate]
+-- BackOffice.DocumentClassificationsExpiry (user-defined table type) [TVP schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [BackOffice.CustomerDocumentToDocumentType](../Tables/BackOffice.CustomerDocumentToDocumentType.md) | Table | UPDATE target - sets ExpiryDate by DocumentToDocumentTypeID join |
| BackOffice.DocumentClassificationsExpiry | User Defined Type (TVP) | Defines the input batch schema (DocumentClassificationId, ExpiryDate) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo. | - | Called from compliance tooling for expiry date corrections. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Batch size cap: RAISERROR if input TVP has > 2000 rows. Prevents oversized update transactions.

---

## 8. Sample Queries

### 8.1 Update expiry dates for a batch of classification records

```sql
DECLARE @expiryUpdates BackOffice.DocumentClassificationsExpiry;
INSERT INTO @expiryUpdates (DocumentClassificationId, ExpiryDate)
VALUES
    (1234567, '2030-06-30'),
    (1234568, '2031-01-15'),
    (1234569, '2029-12-31');

EXEC BackOffice.UpdateDocumentClassificationsExpiryDate
    @documentClassificationsExpiry = @expiryUpdates;
```

### 8.2 Verify expiry dates after update

```sql
SELECT DocumentToDocumentTypeID, DocumentTypeID, ExpiryDate, DocumentID
FROM BackOffice.CustomerDocumentToDocumentType WITH (NOLOCK)
WHERE DocumentToDocumentTypeID IN (1234567, 1234568, 1234569);
```

### 8.3 Find soon-expiring POI documents for proactive renewal outreach

```sql
SELECT cd.CID, c2dt.DocumentToDocumentTypeID, c2dt.ExpiryDate, dt.Name AS DocumentTypeName
FROM BackOffice.CustomerDocumentToDocumentType c2dt WITH (NOLOCK)
JOIN BackOffice.CustomerDocument cd WITH (NOLOCK) ON cd.DocumentID = c2dt.DocumentID
JOIN Dictionary.DocumentType dt WITH (NOLOCK) ON dt.DocumentTypeID = c2dt.DocumentTypeID
WHERE c2dt.DocumentTypeID = 2  -- Proof of Identity
  AND c2dt.ExpiryDate BETWEEN GETUTCDATE() AND DATEADD(MONTH, 3, GETUTCDATE())
ORDER BY c2dt.ExpiryDate ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Dependency Inheritance, Caller Scan, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UpdateDocumentClassificationsExpiryDate | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UpdateDocumentClassificationsExpiryDate.sql*
