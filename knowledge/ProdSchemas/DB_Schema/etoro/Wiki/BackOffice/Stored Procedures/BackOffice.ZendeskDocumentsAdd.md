# BackOffice.ZendeskDocumentsAdd

> Inserts a single row into BackOffice.ZendeskDocuments, linking a Zendesk support document to an eToro T&C document for a specific customer (GCID). No validation, no transaction, no error handling - a bare INSERT created in 2014 for an integration that was never fully adopted.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID + @ZendeskDocumentID + @DocumentID - the three columns of the link record |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.ZendeskDocumentsAdd` is the sole write path for `BackOffice.ZendeskDocuments`. It records the fact that a specific eToro T&C document (`DocumentID` -> `BackOffice.TncDocument`) was associated with a Zendesk support ticket document (`ZendeskDocumentID`) for a given customer (`GCID`).

The business context: when a customer support agent sent a T&C document to a customer via Zendesk (eToro's support platform in 2014), this SP was intended to create an audit record of which internal eToro document was delivered and to which customer. The `Occurred` column defaults to `GETDATE()` on insert, providing a timestamp without the caller needing to supply one.

The table targeted by this SP is currently empty (0 rows). The 2014 creation date and absence of any caller in the codebase suggest this feature was built but never operationally activated, or was replaced by native Zendesk functionality before it could be used. No Atlassian documentation was found for this object.

**Historical changes (from DDL comments)**:
- 2014-08-12 (TRAD\omerbaCREATE): Initial creation
- 2014-08-13 (TRAD\gerire): Reviewed/committed

---

## 2. Business Logic

### 2.1 Unconditional INSERT

**What**: Creates a new Zendesk-to-TncDocument link record for a customer with no pre-conditions.

**Columns/Parameters Involved**: `@GCID`, `@ZendeskDocumentID`, `@DocumentID`

**Rules**:
- No validation is performed before the INSERT (no existence check, no duplicate check, no status check).
- `SET NOCOUNT ON` suppresses the row-count message.
- `Occurred` is NOT a parameter - it defaults to `GETDATE()` at INSERT time via the column default.
- The target table has no UNIQUE constraint on (GCID, ZendeskDocumentID, DocumentID), so duplicate inserts are silently allowed.
- No RETURN value, no OUTPUT parameters, no transaction management.
- No TRY/CATCH error handling - any SQL error propagates directly to the caller.

**Diagram**:
```
@GCID + @ZendeskDocumentID + @DocumentID
    |
    v
INSERT BackOffice.ZendeskDocuments
    (GCID, ZendeskDocumentID, DocumentID)
    -- Occurred defaults to GETDATE()
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID of the customer who received the document via Zendesk. Different from CID (platform-specific eToro ID); GCID is the cross-platform identifier. Stored in BackOffice.ZendeskDocuments.GCID. Part of the NC index (GCID, ZendeskDocumentID) on the target table for per-customer lookups. |
| 2 | @ZendeskDocumentID | int | NO | - | CODE-BACKED | The document record ID as tracked in the Zendesk support platform (external ID). Used alongside @DocumentID to cross-reference the Zendesk external record with the eToro internal document. Stored in BackOffice.ZendeskDocuments.ZendeskDocumentID. |
| 3 | @DocumentID | int | NO | - | CODE-BACKED | The eToro internal T&C document ID. Logical FK to BackOffice.TncDocument.DocumentID (no DDL constraint enforced). Leading key of the clustered index on BackOffice.ZendeskDocuments - the table was designed for document-centric lookups by DocumentID. |

**Return value**: None. No SELECT output, no OUTPUT parameters, no RETURN statement.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID + @ZendeskDocumentID + @DocumentID | [BackOffice.ZendeskDocuments](../Tables/BackOffice.ZendeskDocuments.md) | INSERT | Sole write path - creates the Zendesk-to-TncDocument link record |
| @DocumentID | BackOffice.TncDocument | Logical dependency | DocumentID logically references TncDocument.DocumentID (no DDL FK enforced in ZendeskDocuments) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External application (Zendesk integration, 2014) | API call | Consumer | Intended to be called by the Zendesk integration layer when a T&C document was sent to a customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ZendeskDocumentsAdd (procedure)
+-- BackOffice.ZendeskDocuments (table) [INSERT: target for the link record]
      +-- BackOffice.TncDocument (table) [logical FK: DocumentID -> TncDocument.DocumentID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ZendeskDocuments | Table | INSERT target - the sole destination for the three-column link record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Zendesk integration (external, 2014) | External | Intended caller - never operationally active |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `SET NOCOUNT ON` - suppresses row-count messages
- No transaction wrapping (implicit single-statement transaction)
- No TRY/CATCH - errors propagate directly to the caller
- No input validation - GCID, ZendeskDocumentID, and DocumentID are accepted and inserted as-is
- No UNIQUE constraint on the target table - duplicate (GCID, ZendeskDocumentID, DocumentID) combinations are silently allowed
- `Occurred` column is populated by the table's DEFAULT (GETDATE()) - not a parameter
- The procedure is 14 lines total (DDL boilerplate + SET NOCOUNT + single INSERT)

---

## 8. Sample Queries

### 8.1 Record a Zendesk document delivery for a customer

```sql
-- Link Zendesk document 9999 to eToro T&C document 1 for customer GCID 12345
EXEC BackOffice.ZendeskDocumentsAdd
    @GCID = 12345,
    @ZendeskDocumentID = 9999,
    @DocumentID = 1;
-- No return value. Check BackOffice.ZendeskDocuments to confirm insertion.
```

### 8.2 Verify the inserted record

```sql
SELECT zd.ID, zd.GCID, zd.ZendeskDocumentID, zd.DocumentID, zd.Occurred,
       tnc.DisplayName
FROM BackOffice.ZendeskDocuments zd WITH (NOLOCK)
JOIN BackOffice.TncDocument tnc WITH (NOLOCK) ON tnc.DocumentID = zd.DocumentID
WHERE zd.GCID = 12345
ORDER BY zd.Occurred DESC;
```

### 8.3 Check for duplicates (no constraint prevents them)

```sql
SELECT GCID, ZendeskDocumentID, DocumentID, COUNT(*) AS DuplicateCount
FROM BackOffice.ZendeskDocuments WITH (NOLOCK)
GROUP BY GCID, ZendeskDocumentID, DocumentID
HAVING COUNT(*) > 1;
-- Returns empty on an unused table; useful if the feature is ever reactivated
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object (Confluence and Jira searches returned no results).

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (DDL, Dependency Inheritance, Caller Scan, Code Analysis, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callees (bare INSERT) | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.ZendeskDocumentsAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.ZendeskDocumentsAdd.sql*
